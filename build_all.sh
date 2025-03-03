#!/usr/bin/env bash
# vim:ts=4:sts=4:sw=4:et

# SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
# SPDX-License-Identifier: BSD-3-Clause
#
# Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

declare -r PROGNAME=${0##*/}

function msg() {
    echo -e "\033[33;1m[*] $*\033[0m\n"
}

function error_msg() {
    echo -e "\033[31;1m[!] $*\033[0m\n" >&2
}

function is_mac() {
    local OS_NAME
    OS_NAME=$(uname | tr "[:upper:]" "[:lower:]")
    if [[ ${OS_NAME} =~ "darwin" ]]; then
        return 0
    fi

    return 1
}

SDK_TEMP_DIR=""

function ctrl_c()
{
    exit 1
}
trap ctrl_c INT

function on_exit()
{
    if [[ -n ${EXAMPLE_PROJECTS+x} ]]; then
        for EXAMPLE_PATH in ${EXAMPLE_PROJECTS}; do
            pushd "${EXAMPLE_PATH}" &>/dev/null || error_msg "pushd failed"
            flutter clean || error_msg "flutter clean failed"
            if [ -d "plugins/gem_kit" ]; then
                rm -rf "plugins/gem_kit"
            fi
            find . -type d -name ".gradle" -exec rm -rf {} +
            find . -type d -name ".cxx" -exec rm -rf {} +
            find . -type d -name "local.properties" -exec rm -rf {} +
            popd &>/dev/null || error_msg "popd failed"
        done
    fi

    if [[ -n ${SDK_TEMP_DIR} ]]; then
        rm -fr "${SDK_TEMP_DIR:?}"
    fi

    msg "Bye-Bye"
}
trap 'on_exit' EXIT

if is_mac; then
    if [ ! -f "$(brew --prefix)/opt/gnu-getopt/bin/getopt" ]; then
        error_msg "This script requires 'brew install gnu-getopt && brew link --force gnu-getopt'"
        exit 1
    fi

    PATH="$(brew --prefix)/opt/gnu-getopt/bin:${PATH}"
fi

set -eEuo pipefail

SDK_ARCHIVE_PATH=""
BUILD_ANDROID=false
BUILD_IOS=false
BUILD_MACOS=false
BUILD_WEB=false
ANALYZE=false
UPGRADE=false

MY_DIR="$(cd "$(dirname "$0")" && pwd)"

function usage()
{
    echo -e "\033[32;1m
Usage: ${PROGNAME} [options] 

Options:
    [REQUIRED] --sdk-archive=<path>
                    Set path to the Maps SDK for Flutter archive

    [OPTIONAL] --android
                    Build examples for Android
    [OPTIONAL] --ios
                    Build examples for iOS
     [OPTIONAL] --macos
                    Build examples for MacOS
    [OPTIONAL] --web
                    Build examples for Web

    [OPTIONAL] --analyze
                    Analyze dart code for all examples
    [OPTIONAL] --upgrade
                    Upgrade the current package's dependencies to latest versions
\033[0m\n"
}

LONGOPTS_LIST=(
    "sdk-archive:"
    "android"
    "ios"
    "macos"
    "web"
    "analyze"
    "upgrade"
)

if ! PARSED_OPTIONS=$(getopt \
    -s bash \
    --options "" \
    --longoptions "$(printf "%s," "${LONGOPTS_LIST[@]}")" \
    --name "${PROGNAME}" \
    -- "$@"); then
    usage
    exit 1
fi

eval set -- "${PARSED_OPTIONS}"
unset PARSED_OPTIONS

while true; do
    case "${1}" in
        --sdk-archive)
            shift
            SDK_ARCHIVE_PATH="${1}"
            ;;
        --android)
            BUILD_ANDROID=true
            ;;
        --ios)
            BUILD_IOS=true
            ;;
        --macos)
            BUILD_MACOS=true
            ;;
        --web)
            BUILD_WEB=true
            ;;
        --analyze)
            ANALYZE=true
            ;;
        --upgrade)
            UPGRADE=true
            ;;
        --)
            shift
            break
            ;;
        *)
            error_msg "Internal error"
            exit 1
            ;;
    esac
    shift
done

msg "Checking prerequisites..."

if ${BUILD_IOS} || ${BUILD_MACOS}; then
    if ! is_mac; then
        error_msg "Examples can be built for iOS/MacOS only under MacOS"
        exit 1
    fi
fi

if [[ ! -f "${SDK_ARCHIVE_PATH}" ]]; then
    error_msg "You must provide local path to SDK archive"
    usage
    exit 1
fi

if ! command -v flutter >/dev/null; then
    error_msg "flutter command not found. Please get it from: https://docs.flutter.dev/get-started/install"
    echo
    exit 2
fi

flutter doctor || ( error_msg "flutter doctor failed"; exit 1 )

msg "Extract SDK..."

SDK_TEMP_DIR="$(mktemp -d)"
tar -xvf "${SDK_ARCHIVE_PATH}" --strip-components=1 -C "${SDK_TEMP_DIR}"

pushd "${MY_DIR}" &>/dev/null

[ -d "_APK" ] && rm -rf _APK
${BUILD_ANDROID} && mkdir _APK

[ -d "_WEB" ] && rm -rf _WEB
${BUILD_WEB} && mkdir _WEB

popd &>/dev/null

# Find paths that contain an app module
EXAMPLE_PROJECTS=$(find "${MY_DIR}" -maxdepth 1 -type d -exec [ -d {}/plugins ] \; -print -prune)

for EXAMPLE_PATH in ${EXAMPLE_PROJECTS}; do
	EXAMPLE_NAME="$(basename "${EXAMPLE_PATH}")"

    cp -R "${SDK_TEMP_DIR}"/gem_kit "${EXAMPLE_PATH}"/plugins/

    pushd "${EXAMPLE_PATH}" &>/dev/null

    flutter pub get

    flutter pub outdated

	if ${UPGRADE}; then
		flutter pub upgrade
	fi

    if ${BUILD_IOS}; then
        (cd ios; pod install --repo-update; cd ..)
        flutter build ios --release --no-codesign
	fi
    if ${BUILD_MACOS}; then
        (cd macos; pod install --repo-update; cd ..)
        flutter build macos --release
    fi

    if ${BUILD_ANDROID}; then
        flutter build apk --release
    fi

    if ${BUILD_WEB}; then
        flutter build web --release
    fi

    if ${ANALYZE}; then
        flutter analyze --preamble --no-pub --no-fatal-infos --no-fatal-warnings
    fi

    if ${BUILD_ANDROID}; then
        mv "build/app/outputs/flutter-apk"/app-release.apk "${MY_DIR}/_APK/${EXAMPLE_NAME}_app-release.apk"
    fi
    if ${BUILD_WEB}; then
        mkdir -p "${MY_DIR}/_WEB/${EXAMPLE_NAME}"
        mv "build/web"/* "${MY_DIR}/_WEB/${EXAMPLE_NAME}"/
    fi

    flutter clean || error_msg "flutter clean failed"
    if [ -d "plugins/gem_kit" ]; then
		rm -rf "plugins/gem_kit"
	fi
	find . -type d -name ".gradle" -exec rm -rf {} +
	find . -type d -name ".cxx" -exec rm -rf {} +

    popd &>/dev/null
done

exit 0
