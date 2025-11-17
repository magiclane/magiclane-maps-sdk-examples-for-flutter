#!/usr/bin/env bash
# vim:ts=4:sts=4:sw=4:et

# SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
# SPDX-License-Identifier: Apache-2.0
#
# Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

declare -r PROGNAME=${0##*/}

declare -r COLOR_RESET="\033[0m"
declare -r COLOR_RED="\033[31;1m"
declare -r COLOR_GREEN="\033[32;1m"
declare -r COLOR_YELLOW="\033[33;1m"
declare -r COLOR_BLUE="\033[34;1m"
declare -r COLOR_CYAN="\033[36;1m"

function log_timestamp()
{
    date "+%Y-%m-%d %H:%M:%S"
}

function log_info()
{
    echo -e "${COLOR_CYAN}[$(log_timestamp)] [INFO]${COLOR_RESET} $*"
}

function log_success()
{
    echo -e "${COLOR_GREEN}[$(log_timestamp)] [SUCCESS]${COLOR_RESET} $*"
}

function log_warning()
{
    echo -e "${COLOR_YELLOW}[$(log_timestamp)] [WARNING]${COLOR_RESET} $*"
}

function log_error()
{
    echo -e "${COLOR_RED}[$(log_timestamp)] [ERROR]${COLOR_RESET} $*" >&2
}

function log_step()
{
    echo -e "${COLOR_BLUE}[$(log_timestamp)] [STEP]${COLOR_RESET} $*"
}

function is_mac()
{
    local OS_NAME
    OS_NAME=$(uname | tr "[:upper:]" "[:lower:]")
    if [[ ${OS_NAME} =~ "darwin" ]]; then
        return 0
    fi

    return 1
}

SDK_TEMP_DIR=""

# shellcheck disable=SC2317
function ctrl_c()
{
    exit 1
}
trap ctrl_c INT

function clean_example()
{
    local EXAMPLE_PATH="${1}"

    if [[ -z "${EXAMPLE_PATH}" || ! -d "${EXAMPLE_PATH}" ]]; then
        return
    fi

    pushd "${EXAMPLE_PATH}" &>/dev/null

    EXAMPLE_NAME="$(basename "${EXAMPLE_PATH}")"
    log_info "Cleaning example '${EXAMPLE_NAME}'..."

    flutter clean &>/dev/null

    [[ -d "plugins/magiclane_maps_flutter" ]] && rm -rf "plugins/magiclane_maps_flutter" &>/dev/null

    find . -type d -name ".gradle" -exec rm -rf {} + 2>/dev/null
    find . -type d -name ".cxx" -exec rm -rf {} + 2>/dev/null
    find . -type d -name ".kotlin" -exec rm -rf {} + 2>/dev/null   
    find . -type f -name "local.properties" -exec rm -f {} + 2>/dev/null
    
    find ios -type d -name ".symlinks" -exec rm -rf {} + 2>/dev/null
    find ios -type d -name "Pods" -exec rm -rf {} + 2>/dev/null
    find ios -type d -name "Podfile.lock" -exec rm -f {} + 2>/dev/null

    local GEN_FILE="${EXAMPLE_PATH}/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"
    if [[ -f "${GEN_FILE}" ]]; then
        local JAVA_DIR="${EXAMPLE_PATH}/android/app/src/main/java"
        rm -rf "${JAVA_DIR}" &>/dev/null
    fi

    popd &>/dev/null
}

# shellcheck disable=SC2317
function on_exit()
{
    if [[ -v EXAMPLE_PROJECTS ]]; then
        for EXAMPLE_PATH in "${EXAMPLE_PROJECTS[@]}"; do
            clean_example "${EXAMPLE_PATH}"
        done
    fi

    if [[ -n ${SDK_TEMP_DIR} ]]; then
        rm -fr "${SDK_TEMP_DIR:?}"
    fi

    log_info "Build script completed"
}
trap 'on_exit' EXIT

if is_mac; then
    if [ ! -f "$(brew --prefix)/opt/gnu-getopt/bin/getopt" ]; then
        log_error "This script requires 'brew install gnu-getopt && brew link --force gnu-getopt'"
        exit 1
    fi

    PATH="$(brew --prefix)/opt/gnu-getopt/bin:${PATH}"
    export PATH
fi

set -eEuo pipefail

SDK_ARCHIVE_PATH=""
BUILD_ANDROID=false
BUILD_IOS=false
BUILD_WEB=false
ANALYZE=false
UPGRADE=false

MY_DIR="$(cd "$(dirname "$0")" && pwd)"

function usage()
{
    echo -e "\033[32;1m
Usage: ${PROGNAME} [options] 

Options:
    [OPTIONAL] --sdk-archive=<path>
                    Set path to the Maps SDK for Flutter archive (.tar.bz2 or .zip)
                    If not provided, magiclane_maps_flutter will be downloaded from pub.dev

    [OPTIONAL] --android
                    Build examples for Android
    [OPTIONAL] --ios
                    Build examples for iOS
    [OPTIONAL] --web
                    Build examples for Web

    [OPTIONAL] --analyze
                    Analyze dart code for all examples
    [OPTIONAL] --upgrade
                    Upgrade the current package's dependencies to latest versions
\033[0m\n"
}

SHORTOPTS="h"
LONGOPTS_LIST=(
    "help"
    "sdk-archive:"
    "android"
    "ios"
    "web"
    "analyze"
    "upgrade"
)

if ! PARSED_OPTIONS=$(getopt \
    -s bash \
    --options ${SHORTOPTS} \
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
        -h|--help)
            usage
            exit 0
            ;;
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
        --upgrade)
            UPGRADE=true
            ;;
        --)
            shift
            break
            ;;
        *)
            log_error "Internal error"
            exit 1
            ;;
    esac
    shift
done

log_info "Checking prerequisites..."

if ${BUILD_IOS}; then
    if ! is_mac; then
        log_error "Examples can be built for iOS only under MacOS"
        exit 1
    fi
fi

if ! is_mac && [[ -z "${SDK_ARCHIVE_PATH}" ]]; then
    log_error "On Linux, the --sdk-archive option is required because the pub.dev version"
    log_error "includes iOS dependencies that cannot be resolved on non-macOS systems."
    log_error ""
    log_error "Please provide an SDK archive:"
    log_error "  ${PROGNAME} --sdk-archive=/path/to/sdk.tar.bz2 --android --analyze"
    log_error ""
    exit 1
fi

# Avoid dependency resolution errors
if is_mac; then
    log_info "Enabling Swift Package Manager on macOS..."
    flutter config --enable-swift-package-manager 2>/dev/null || true
fi

if [[ -n "${SDK_ARCHIVE_PATH}" && ! -f "${SDK_ARCHIVE_PATH}" ]]; then
    log_error "SDK archive file not found: ${SDK_ARCHIVE_PATH}"
    usage
    exit 1
fi

if ! command -v flutter >/dev/null; then
    log_error "flutter command not found. Please get it from: https://docs.flutter.dev/get-started/install"
    printf '\n'
    exit 2
fi

flutter doctor || ( log_error "flutter doctor failed"; exit 1 )

if [[ -n "${SDK_ARCHIVE_PATH}" ]]; then
    log_info "Extracting SDK archive..."

    SDK_TEMP_DIR="$(mktemp -d)"
    
    case "${SDK_ARCHIVE_PATH}" in
        *.tar.bz2)
            tar -xvf "${SDK_ARCHIVE_PATH}" --strip-components=1 -C "${SDK_TEMP_DIR}"
            ;;
        *.zip)
            if ! command -v unzip >/dev/null; then
                log_error "unzip command not found. Please install unzip to extract .zip archives"
                exit 2
            fi
            unzip -q "${SDK_ARCHIVE_PATH}" -d "${SDK_TEMP_DIR}"
            # Handle potential top-level directory in zip
            if [[ $(find "${SDK_TEMP_DIR}" -mindepth 1 -maxdepth 1 -type d | wc -l) -eq 1 ]]; then
                local TOP_DIR=$(find "${SDK_TEMP_DIR}" -mindepth 1 -maxdepth 1 -type d)
                mv "${TOP_DIR}"/* "${SDK_TEMP_DIR}"/
                rmdir "${TOP_DIR}"
            fi
            ;;
        *)
            log_error "Unsupported archive format. Only .tar.bz2 and .zip are supported"
            exit 1
            ;;
    esac
    log_success "SDK archive extracted successfully"
else
    log_info "No SDK archive provided, will use magiclane_maps_flutter from pub.dev"
fi

if ${BUILD_IOS}; then
    if ! command -v xcodebuild >/dev/null; then
        log_error "xcodebuild not found. Please install Xcode from the App Store."
        exit 1
    fi

    log_info "Checking for installed iOS SDKs..."

    SIMULATOR_SDK=$(xcodebuild -showsdks 2>/dev/null | grep "iphonesimulator" | tail -1 | sed -n 's/.*iphonesimulator\([0-9.]*\)/\1/p')
    DEVICE_SDK=$(xcodebuild -showsdks 2>/dev/null | grep -E "iphoneos[0-9]" | tail -1 | sed -n 's/.*iphoneos\([0-9.]*\)/\1/p')

    if [[ -z "${SIMULATOR_SDK}" ]]; then
        log_error "No iOS Simulator SDK found."
        log_error "Please install iOS platform components:"
        log_error "  Xcode > Settings > Platforms > iOS"
        log_error "  Or: Xcode > Settings > Components"
        exit 1
    fi

    if [[ -z "${DEVICE_SDK}" ]]; then
        log_error "No iOS Device SDK found."
        log_error "Please install iOS platform components:"
        log_error "  Xcode > Settings > Platforms > iOS"
        exit 1
    fi

    log_info "Found iOS Simulator SDK: ${SIMULATOR_SDK}"
    log_info "Found iOS Device SDK: ${DEVICE_SDK}"

    if [[ "${SIMULATOR_SDK}" != "${DEVICE_SDK}" ]]; then
        log_error "SDK version mismatch:"
        log_error "  Simulator SDK: ${SIMULATOR_SDK}"
        log_error "  Device SDK: ${DEVICE_SDK}"
        log_error "Please ensure both are updated to the same latest version:"
        log_error "  Xcode > Settings > Platforms > iOS (update all components)"
        exit 1
    fi

    log_success "iOS SDK verification passed (version ${DEVICE_SDK})"
fi

pushd "${MY_DIR}" &>/dev/null

[ -d "_APK" ] && rm -rf _APK
${BUILD_ANDROID} && mkdir _APK

[ -d "_WEB" ] && rm -rf _WEB
${BUILD_WEB} && mkdir _WEB

popd &>/dev/null

# Find paths that contain an app module
mapfile -t EXAMPLE_PROJECTS < <(find "${MY_DIR}" -maxdepth 1 -type d -exec [ -d "{}/plugins" ] \; -exec realpath {} \; 2>/dev/null)

for EXAMPLE_PATH in "${EXAMPLE_PROJECTS[@]}"; do
    EXAMPLE_NAME="$(basename "${EXAMPLE_PATH}")"

    if [[ -n "${SDK_ARCHIVE_PATH}" ]]; then
        cp -R "${SDK_TEMP_DIR}"/magiclane_maps_flutter "${EXAMPLE_PATH}"/plugins/
    fi

    pushd "${EXAMPLE_PATH}" &>/dev/null

    printf '\n'
    log_step "Building example: ${EXAMPLE_NAME}"

    log_info "Running flutter pub get..."
    flutter pub get

    log_info "Checking for outdated packages..."
    flutter pub outdated

    if ${UPGRADE}; then
        log_info "Upgrading packages..."
        flutter pub upgrade
    fi

    if ${BUILD_IOS}; then
        if [[ -f "ios/Podfile" ]]; then
            log_info "Installing CocoaPods dependencies..."
            (cd ios; pod install; cd ..)
        else
            log_warning "Skipping pod install - no Podfile found in ios/"
        fi

        log_info "Building iOS release..."
        flutter build ios --release --no-codesign
        log_success "iOS build completed"
    fi

    if ${BUILD_ANDROID}; then
        log_info "Building Android APK..."
        flutter build apk --release --dart-define=CI=true
        log_success "Android APK build completed"
    fi

    if ${BUILD_WEB}; then
        log_info "Building Web release..."
        flutter build web --release
        log_success "Web build completed"
    fi

    if ${ANALYZE}; then
        log_info "Analyzing Dart code..."
        flutter analyze --preamble --no-pub --no-fatal-infos --no-fatal-warnings
        log_success "Code analysis completed"
    fi

    if ${BUILD_ANDROID}; then
        log_info "Copying APK to output directory..."
        mv "build/app/outputs/flutter-apk"/app-release.apk "${MY_DIR}/_APK/${EXAMPLE_NAME}_app-release.apk"
    fi
    
    if ${BUILD_WEB}; then
        log_info "Copying Web build to output directory..."
        mkdir -p "${MY_DIR}/_WEB/${EXAMPLE_NAME}"
        mv "build/web"/* "${MY_DIR}/_WEB/${EXAMPLE_NAME}"/
    fi

    clean_example "${EXAMPLE_PATH}"

    popd &>/dev/null
done

log_success "All examples built successfully"

exit 0
