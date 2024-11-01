#!/usr/bin/env bash
# vim:ts=4:sts=4:sw=4:et

# Copyright (C) 2019-2024, Magic Lane B.V.
# All rights reserved.
#
# This software is confidential and proprietary information of Magic Lane
# ("Confidential Information"). You shall not disclose such Confidential
# Information and shall use it only in accordance with the terms of the
# license agreement you entered into with Magic Lane.

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
BUILD_WEB=false
ANALYZE=false

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
                    Build examples for iOS/OSX
    [OPTIONAL] --web
                    Build examples for Web

    [OPTIONAL] --analyze
                    Analyze dart code for all examples
\033[0m\n"
}

LONGOPTS_LIST=(
    "sdk-archive:"
    "android"
    "ios"
    "web"
    "analyze"
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
        --web)
            BUILD_WEB=true
            ;;
        --analyze)
            ANALYZE=true
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

if ${BUILD_IOS}; then
    if ! is_mac; then
        error_msg "Examples can be built for iOS/OSX only under OSX"
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

# Find paths that contain an app module
EXAMPLE_PROJECTS=$(find "${MY_DIR}" -maxdepth 1 -type d -exec [ -d {}/plugins ] \; -print -prune)

for EXAMPLE_PATH in ${EXAMPLE_PROJECTS}; do
    cp -R "${SDK_TEMP_DIR}"/gem_kit "${EXAMPLE_PATH}"/plugins/

    pushd "${EXAMPLE_PATH}" &>/dev/null

    flutter pub get

    flutter pub outdated

    flutter pub upgrade --major-versions

    if ${BUILD_IOS}; then
        if is_mac; then
            (cd ios; pod install --repo-update; cd ..)
            flutter build ios --release --no-codesign

            (cd macos; pod install --repo-update; cd ..)
            flutter build macos --release
        fi
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

    flutter clean || error_msg "flutter clean failed"
    if [ -d "plugins/gem_kit" ]; then
		rm -rf "plugins/gem_kit"
	fi
	find . -type d -name ".gradle" -exec rm -rf {} +

    popd &>/dev/null
done

pushd "${MY_DIR}" &>/dev/null

if [ -d "APK" ]; then
    rm -rf "APK"
fi
if ${BUILD_ANDROID}; then
    mkdir APK
fi

if [ -d "WEB" ]; then
    rm -rf "WEB"
fi
if ${BUILD_WEB}; then
    mkdir WEB
fi

for EXAMPLE_PATH in ${EXAMPLE_PROJECTS}; do
    EXAMPLE_NAME="$(basename "${EXAMPLE_PATH}")"
    if ${BUILD_ANDROID}; then
        mv "${EXAMPLE_PATH}/build/app/outputs/flutter-apk"/app-release.apk "APK/${EXAMPLE_NAME}_app-release.apk"
    fi
    if ${BUILD_WEB}; then
        mkdir -p "WEB/${EXAMPLE_NAME}"
        mv "${EXAMPLE_PATH}/build/web"/* "WEB/${EXAMPLE_NAME}"/
    fi
done

popd &>/dev/null
