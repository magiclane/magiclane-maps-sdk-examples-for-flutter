#!/usr/bin/env bash
# vim:ts=4:sts=4:sw=4:et
# shellcheck disable=SC2317,SC2329

# SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
# SPDX-License-Identifier: Apache-2.0
#
# Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

set -eEuo pipefail

declare -r PROGNAME="${0##*/}"

declare -r COLOR_RESET_DEFAULT="\033[0m"
declare -r COLOR_RED_DEFAULT="\033[31;1m"
declare -r COLOR_GREEN_DEFAULT="\033[32;1m"
declare -r COLOR_YELLOW_DEFAULT="\033[33;1m"
declare -r COLOR_BLUE_DEFAULT="\033[34;1m"
declare -r COLOR_CYAN_DEFAULT="\033[36;1m"

COLOR_RESET="${COLOR_RESET_DEFAULT}"
COLOR_RED="${COLOR_RED_DEFAULT}"
COLOR_GREEN="${COLOR_GREEN_DEFAULT}"
COLOR_YELLOW="${COLOR_YELLOW_DEFAULT}"
COLOR_BLUE="${COLOR_BLUE_DEFAULT}"
COLOR_CYAN="${COLOR_CYAN_DEFAULT}"

CONSOLE_MODE="auto"

function log_timestamp()
{
    date "+%Y-%m-%d %H:%M:%S"
}

function log_info()
{
    printf '%b\n' "${COLOR_CYAN}[$(log_timestamp)] [INFO]${COLOR_RESET} $*"
}

function log_success()
{
    printf '%b\n' "${COLOR_GREEN}[$(log_timestamp)] [SUCCESS]${COLOR_RESET} $*"
}

function log_warning()
{
    printf '%b\n' "${COLOR_YELLOW}[$(log_timestamp)] [WARNING]${COLOR_RESET} $*"
}

function log_error()
{
    printf '%b\n' "${COLOR_RED}[$(log_timestamp)] [ERROR]${COLOR_RESET} $*" >&2
}

function log_step()
{
    printf '\n%b\n\n' "${COLOR_BLUE}[$(log_timestamp)] [STEP]${COLOR_RESET} $*"
}

function apply_console_mode()
{
    function _disable_colors()
    {
        COLOR_RESET=""
        COLOR_RED=""
        COLOR_GREEN=""
        COLOR_YELLOW=""
        COLOR_BLUE=""
        COLOR_CYAN=""
    }

    case "${CONSOLE_MODE}" in
        auto)
            if [[ ! -t 1 ]]; then
                _disable_colors
            fi
            ;;
        plain)
            _disable_colors
            ;;
        colored)
            :
            ;;
        verbose)
            set -x
            ;;
        *)
            log_error "Invalid --console value: '${CONSOLE_MODE}'. Allowed: auto, plain, colored, verbose"
            usage
            exit 1
            ;;
    esac
}

function check_cmd()
{
    command -v "${1}" >/dev/null 2>&1
}

function is_mac()
{
    local OS_NAME
    OS_NAME="$(uname | tr '[:upper:]' '[:lower:]')"
    [[ "${OS_NAME}" =~ darwin ]]
}

function is_ci()
{
    if [[ -n "${CI:-}" ]] && [[ "${CI}" != "false" ]] && [[ "${CI}" != "0" ]]; then
        return 0
    fi

    local -a CI_VARS=(
        GITHUB_ACTIONS
        GITLAB_CI
        JENKINS_URL
        TEAMCITY_VERSION
        BUILDKITE
        CIRCLECI
        TRAVIS
        APPVEYOR
        TF_BUILD
        BITBUCKET_BUILD_NUMBER
        DRONE
        SEMAPHORE
        CODEBUILD_BUILD_ID
    )

    local VAR
    for VAR in "${CI_VARS[@]}"; do
        [[ -n "${!VAR:-}" ]] && return 0
    done

    return 1
}

function setup_mac_deps()
{
    is_mac || return 0

    if ! check_cmd brew; then
        log_error "Missing Homebrew. Run:"
        # shellcheck disable=SC2016
        log_error '$ bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        exit 1
    fi

    local BREW_PREFIX
    BREW_PREFIX="$(brew --prefix)"

    # package:path_suffix
    local -a DEPS=(
        "gnu-getopt:gnu-getopt/bin"
        "grep:grep/libexec/gnubin"
        "coreutils:coreutils/libexec/gnubin"
        "findutils:findutils/libexec/gnubin"
    )

    local DEP PKG PATH_SUFFIX
    for DEP in "${DEPS[@]}"; do
        PKG="${DEP%%:*}"
        PATH_SUFFIX="${DEP##*:}"

        if ! brew ls --versions "${PKG}" > /dev/null 2>&1; then
            log_error "Missing ${PKG}. Run 'brew install ${PKG}'"
            exit 1
        fi

        export PATH="${BREW_PREFIX}/opt/${PATH_SUFFIX}:${PATH}"
    done
}

function contains_in_array()
{
    local NEEDLE="$1"
    shift

    local NEEDLE_LC
    NEEDLE_LC="$(printf '%s' "${NEEDLE}" | tr '[:upper:]' '[:lower:]')"

    local ITEM ITEM_LC
    for ITEM in "$@"; do
        ITEM_LC="$(printf '%s' "${ITEM}" | tr '[:upper:]' '[:lower:]')"
        [[ "${ITEM_LC}" == "${NEEDLE_LC}" ]] && return 0
    done

    return 1
}

function filtering_active()
{
    [[ ${#ONLY_EXAMPLES[@]} -gt 0 ]] || [[ ${#EXCLUDE_EXAMPLES[@]} -gt 0 ]]
}

function validate_filter_names()
{
    local NAME EXAMPLE_PATH EXAMPLE_NAME
    local FOUND
    local -a UNKNOWN_ONLY=()
    local -a UNKNOWN_EXCLUDE=()

    for NAME in "${ONLY_EXAMPLES[@]}"; do
        FOUND=false
        for EXAMPLE_PATH in "${EXAMPLE_PROJECTS[@]}"; do
            EXAMPLE_NAME="$(basename "${EXAMPLE_PATH}")"
            if contains_in_array "${NAME}" "${EXAMPLE_NAME}"; then
                FOUND=true
                break
            fi
        done
        if ! "${FOUND}"; then
            UNKNOWN_ONLY+=("${NAME}")
        fi
    done

    for NAME in "${EXCLUDE_EXAMPLES[@]}"; do
        FOUND=false
        for EXAMPLE_PATH in "${EXAMPLE_PROJECTS[@]}"; do
            EXAMPLE_NAME="$(basename "${EXAMPLE_PATH}")"
            if contains_in_array "${NAME}" "${EXAMPLE_NAME}"; then
                FOUND=true
                break
            fi
        done
        if ! "${FOUND}"; then
            UNKNOWN_EXCLUDE+=("${NAME}")
        fi
    done

    if [[ ${#UNKNOWN_ONLY[@]} -gt 0 ]]; then
        log_error "Unknown example(s) in --only: ${UNKNOWN_ONLY[*]}"
        log_error "Use --list-examples to see available examples"
        exit 1
    fi

    if [[ ${#UNKNOWN_EXCLUDE[@]} -gt 0 ]]; then
        log_warning "Unknown example(s) in --exclude (ignored): ${UNKNOWN_EXCLUDE[*]}"
    fi
}

SDK_TEMP_DIR=""
SCRIPT_DIR=""
SHOW_EXIT_MESSAGE=true
CURRENT_BUILD_PID=""

declare -a EXAMPLE_PROJECTS=()
declare -a ONLY_EXAMPLES=()
declare -a EXCLUDE_EXAMPLES=()

# Flutter iOS builds all use "Runner" as the Xcode project name
function clean_xcode_derived_data_runner()
{
    local DERIVED_BASE="${HOME}/Library/Developer/Xcode/DerivedData"
    [[ -d "${DERIVED_BASE}" ]] || return 0

    rm -rf "${DERIVED_BASE}"/Runner-* 2>/dev/null || true
}

function clear_spm_cache()
{
    log_info "Clearing Swift Package Manager cache..."
    rm -rf "${HOME}/Library/Caches/org.swift.swiftpm" 2>/dev/null || true
    rm -rf "${HOME}/Library/org.swift.swiftpm" 2>/dev/null || true
    log_info "SPM cache cleared"
}

function clean_example()
{
    local EXAMPLE_PATH="${1}"
    local EXAMPLE_NAME

    [[ -z "${EXAMPLE_PATH}" || ! -d "${EXAMPLE_PATH}" ]] && return 0

    EXAMPLE_NAME="$(basename "${EXAMPLE_PATH}")"
    log_info "Cleaning example '${EXAMPLE_NAME}'..."

    (
        cd "${EXAMPLE_PATH}" || exit 0

        # Flutter project artifacts (replaces slow 'flutter clean')
        rm -rf \
            build \
            .dart_tool \
            .flutter-plugins \
            .flutter-plugins-dependencies \
            .packages \
            2>/dev/null || true

        # Plugin checkout/symlink
        rm -rf plugins/magiclane_maps_flutter 2>/dev/null || true

        # Android
        rm -rf \
            android/.gradle \
            android/app/.gradle \
            android/.kotlin \
            android/.cxx \
            android/app/.cxx \
            android/app/build \
            android/build \
            android/app/src/main/java/io/flutter/plugins \
            2>/dev/null || true
        rm -f android/local.properties 2>/dev/null || true

        # iOS
        rm -rf \
            ios/Pods \
            ios/.symlinks \
            ios/Flutter/.symlinks \
            2>/dev/null || true
        rm -f ios/Podfile.lock 2>/dev/null || true
    )

    clean_xcode_derived_data_runner
}

function dist_clean()
{
    [ "${CLEAN_ON_EXIT}" = true ] || return 0

    if [[ ${#EXAMPLE_PROJECTS[@]} -gt 0 ]]; then
        for EXAMPLE_PATH in "${EXAMPLE_PROJECTS[@]}"; do
            clean_example "${EXAMPLE_PATH}"
        done
    fi

    clean_xcode_derived_data_runner
}

function ctrl_c()
{
    # Example builds run as background jobs (see the main loop) and would
    # otherwise survive an interrupt; terminate the one in flight first.
    if [[ -n "${CURRENT_BUILD_PID}" ]]; then
        pkill -TERM -P "${CURRENT_BUILD_PID}" 2>/dev/null || true
        kill -TERM "${CURRENT_BUILD_PID}" 2>/dev/null || true
    fi
    exit 1
}
trap ctrl_c INT TERM

function on_error()
{
    local EXIT_CODE="${1:-1}"
    local LINE="${2:-unknown}"
    local COMMAND="${3:-unknown}"

    log_error "Command failed at line ${LINE}: ${COMMAND}"
    log_error "Exit code: ${EXIT_CODE}"

    if [[ ${#FUNCNAME[@]} -gt 2 ]]; then
        log_error "Call stack:"
        for ((I = 1; I < ${#FUNCNAME[@]} - 1; I++)); do
            log_error "  ${FUNCNAME[I]}() at ${BASH_SOURCE[I]}:${BASH_LINENO[I - 1]}"
        done
    fi
}
trap 'on_error "$?" "${LINENO}" "${BASH_COMMAND}"' ERR

function on_exit()
{
    local EXIT_CODE=$?
    set +e

    dist_clean

    if [[ -n "${SDK_TEMP_DIR}" ]] && [[ -d "${SDK_TEMP_DIR}" ]]; then
        rm -rf "${SDK_TEMP_DIR:?}"
    fi

    if "${SHOW_EXIT_MESSAGE}"; then
        if [[ ${EXIT_CODE} -eq 0 ]]; then
            "${BUILD_ANDROID}" && log_info "APKs: ${SCRIPT_DIR}/_APK"
            "${BUILD_WEB}" && log_info "Web:  ${SCRIPT_DIR}/_WEB"
            "${BUILD_WEB}" && ! "${NO_GALLERY}" && log_info "Gallery: open _WEB/serve.command (double-click) or run _WEB/serve.sh"
        fi

        printf '\n'
        log_info "Bye-Bye"
    fi

    exit "${EXIT_CODE}"
}
trap on_exit EXIT

function usage()
{
    SHOW_EXIT_MESSAGE=false

    printf '%b\n' "${COLOR_GREEN}
Usage: ${PROGNAME} [options]

Options:
    -h, --help                   Show this help message

    --sdk-archive=<path>         Set path to the Maps SDK for Flutter archive
                                 (.tar.bz2 or .zip)
                                 If not provided, magiclane_maps_flutter will be
                                 downloaded from pub.dev

    --api-token=<token>          Magic Lane API token to build the examples with
                                 (passed as --dart-define=YOUR_API_TOKEN_HERE).
                                 Without it, the map runs in watermarked
                                 evaluation mode

    --android                    Build examples for Android

    --ios                        Build examples for iOS

    --web                        Build examples for Web

    --web-thumbnails             Build for Web and capture real example
                                 screenshots via headless Chrome for the gallery
                                 (best-effort; falls back to placeholder tiles)

    --no-gallery                 Skip generating the _WEB gallery landing page
                                 and launcher

    --list-examples              List detected example names and exit

    --only <name>                Build only this example (can be repeated)

    --exclude <name>             Exclude this example from build (can be repeated)

    --analyze                    Analyze dart code for all examples

    --upgrade                    Upgrade the current package's dependencies to
                                 latest versions

    --fail-fast                  Stop at the first example that fails to build
                                 (default: continue with the remaining examples
                                 and report a failure summary at the end)

    --clean                      Clear the SPM cache up front, remove build artifacts on exit
                                 (default: on in CI, off locally)

    --console=(auto|plain|colored|verbose)
                                 Specifies which type of console output to generate

                                 auto:    colored when attached to a terminal,
                                          plain otherwise (default)
                                 plain:   plain text only; disables all color
                                 colored: colored output
                                 verbose: colored output and verbose logging
${COLOR_RESET}"
}

function extract_sdk_archive()
{
    [[ -n "${SDK_ARCHIVE_PATH}" ]] || return 0

    log_info "Extracting SDK archive..."

    SDK_TEMP_DIR="$(mktemp -d)"

    case "${SDK_ARCHIVE_PATH}" in
        *.tar.bz2)
            tar -xvf "${SDK_ARCHIVE_PATH}" --strip-components=1 -C "${SDK_TEMP_DIR}"
            ;;
        *.zip)
            if ! check_cmd unzip; then
                log_error "unzip command not found. Please install unzip to extract .zip archives"
                exit 2
            fi
            unzip -q "${SDK_ARCHIVE_PATH}" -d "${SDK_TEMP_DIR}"
            # Handle potential top-level directory in zip
            if [[ $(find "${SDK_TEMP_DIR}" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ') -eq 1 ]]; then
                local TOP_DIR
                TOP_DIR="$(find "${SDK_TEMP_DIR}" -mindepth 1 -maxdepth 1 -type d)"
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
}

function check_ios_prerequisites()
{
    "${BUILD_IOS}" || return 0

    if ! is_mac; then
        log_error "Examples can be built for iOS only under macOS"
        exit 1
    fi

    if ! check_cmd xcodebuild; then
        log_error "xcodebuild not found. Please install Xcode from the App Store"
        exit 1
    fi

    log_info "Checking for installed iOS SDKs..."

    local SIMULATOR_SDK DEVICE_SDK

    SIMULATOR_SDK="$(xcodebuild -showsdks 2>/dev/null | grep "iphonesimulator" | tail -1 | sed -n 's/.*iphonesimulator\([0-9.]*\)/\1/p')"
    DEVICE_SDK="$(xcodebuild -showsdks 2>/dev/null | grep -E "iphoneos[0-9]" | tail -1 | sed -n 's/.*iphoneos\([0-9.]*\)/\1/p')"

    if [[ -z "${SIMULATOR_SDK}" ]]; then
        log_error "No iOS Simulator SDK found"
        log_error "Please install iOS platform components:"
        log_error "  Xcode > Settings > Platforms > iOS"
        exit 1
    fi

    if [[ -z "${DEVICE_SDK}" ]]; then
        log_error "No iOS Device SDK found"
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
}

function discover_examples()
{
    log_step "Discovering examples..."

    mapfile -t EXAMPLE_PROJECTS < <(
        find "${SCRIPT_DIR}" -maxdepth 1 -type d -exec [ -d "{}/plugins" ] \; -print 2>/dev/null | sort
    )

    if [[ ${#EXAMPLE_PROJECTS[@]} -eq 0 ]]; then
        log_error "No examples found under ${SCRIPT_DIR} (expected <example>/plugins)"
        exit 1
    fi

    log_info "Found ${#EXAMPLE_PROJECTS[@]} example(s)"
}

function list_examples()
{
    SHOW_EXIT_MESSAGE=false

    local EXAMPLE_PATH
    for EXAMPLE_PATH in "${EXAMPLE_PROJECTS[@]}"; do
        printf '%s\n' "$(basename "${EXAMPLE_PATH}")"
    done
}

function filter_examples()
{
    local -a FILTERED=()
    local EXAMPLE_PATH EXAMPLE_NAME

    if [[ ${#ONLY_EXAMPLES[@]} -gt 0 ]] && [[ ${#EXCLUDE_EXAMPLES[@]} -gt 0 ]]; then
        log_error "Do not use --only and --exclude together"
        usage
        exit 1
    fi

    for EXAMPLE_PATH in "${EXAMPLE_PROJECTS[@]}"; do
        EXAMPLE_NAME="$(basename "${EXAMPLE_PATH}")"

        if [[ ${#ONLY_EXAMPLES[@]} -gt 0 ]]; then
            if contains_in_array "${EXAMPLE_NAME}" "${ONLY_EXAMPLES[@]}"; then
                FILTERED+=("${EXAMPLE_PATH}")
            fi
            continue
        fi

        if [[ ${#EXCLUDE_EXAMPLES[@]} -gt 0 ]]; then
            if contains_in_array "${EXAMPLE_NAME}" "${EXCLUDE_EXAMPLES[@]}"; then
                continue
            fi
        fi

        FILTERED+=("${EXAMPLE_PATH}")
    done

    EXAMPLE_PROJECTS=("${FILTERED[@]}")

    if [[ ${#EXAMPLE_PROJECTS[@]} -eq 0 ]]; then
        log_error "After filtering, no examples remain to build"
        exit 1
    fi

    log_info "Selected ${#EXAMPLE_PROJECTS[@]} example(s): $(printf '%s ' "${EXAMPLE_PROJECTS[@]##*/}")"
}

function build_example()
{
    local EXAMPLE_PATH="${1}"
    local CURRENT_INDEX="${2}"
    local TOTAL_COUNT="${3}"
    local EXAMPLE_NAME
    EXAMPLE_NAME="$(basename "${EXAMPLE_PATH}")"

    # Pass the SDK API token to the app (read via String.fromEnvironment) when
    # provided; without it the map runs in watermarked evaluation mode.
    local -a TOKEN_DEFINE=()
    [[ -n "${API_TOKEN}" ]] && TOKEN_DEFINE+=("--dart-define=YOUR_API_TOKEN_HERE=${API_TOKEN}")

    if [[ -n "${SDK_ARCHIVE_PATH}" ]]; then
        cp -R "${SDK_TEMP_DIR}"/magiclane_maps_flutter "${EXAMPLE_PATH}"/plugins/
    fi

    pushd "${EXAMPLE_PATH}" > /dev/null || return 1

    log_step "Building example (${CURRENT_INDEX}/${TOTAL_COUNT}): ${EXAMPLE_NAME}"
    log_info "Running flutter pub get..."
    flutter pub get

    log_info "Checking for outdated packages..."
    flutter pub outdated || true

    if "${UPGRADE}"; then
        log_info "Upgrading packages..."
        flutter pub upgrade
    fi

    if "${BUILD_IOS}"; then
        if [[ -f "ios/Podfile" ]]; then
            log_info "Installing CocoaPods dependencies..."
            (cd ios && pod install)
        else
            log_warning "Skipping pod install - no Podfile found in ios/"
        fi

        log_info "Building iOS release..."
        flutter build ios --release --no-codesign "${TOKEN_DEFINE[@]+"${TOKEN_DEFINE[@]}"}"
        log_success "iOS build completed"
    fi

    if "${BUILD_ANDROID}"; then
        log_info "Building Android APK..."
        flutter build apk --release --dart-define=CI=true "${TOKEN_DEFINE[@]+"${TOKEN_DEFINE[@]}"}"
        log_success "Android APK build completed"
    fi

    if "${BUILD_WEB}"; then
        log_info "Building Web release..."
        # Per-example base href so each app works when served under
        # _WEB/<example>/. --pwa-strategy=none keeps a service worker from
        # serving stale content after rebuilds; --no-wasm-dry-run silences
        # the repeated WASM-incompatibility notes.
        flutter build web --release --base-href "/${EXAMPLE_NAME}/" \
            --pwa-strategy=none --no-wasm-dry-run "${TOKEN_DEFINE[@]+"${TOKEN_DEFINE[@]}"}"
        log_success "Web build completed"
    fi

    if "${ANALYZE}"; then
        log_info "Analyzing Dart code..."
        flutter analyze --preamble --no-pub --no-fatal-infos --no-fatal-warnings
        log_success "Code analysis completed"
    fi

    if "${BUILD_ANDROID}"; then
        mv "build/app/outputs/flutter-apk/app-release.apk" "${SCRIPT_DIR}/_APK/${EXAMPLE_NAME}_app-release.apk"
    fi

    if "${BUILD_WEB}"; then
        # Move the whole directory (a glob would drop dotfiles and fail on
        # an empty build dir).
        rm -rf "${SCRIPT_DIR}/_WEB/${EXAMPLE_NAME}"
        mv "build/web" "${SCRIPT_DIR}/_WEB/${EXAMPLE_NAME}"
    fi

    if "${CLEAN_ON_EXIT}"; then
        clean_example "${EXAMPLE_PATH}"
    fi

    popd > /dev/null || true
}

function json_escape()
{
    # Escape a string for a JSON double-quoted value. README catalog entries are
    # single-line, so escaping backslash and double-quote is sufficient.
    local S="${1}"
    S="${S//\\/\\\\}"
    S="${S//\"/\\\"}"
    printf '%s' "${S}"
}

function title_case()
{
    # add_markers -> Add Markers
    printf '%s' "${1//_/ }" | awk '{ for (I = 1; I <= NF; I++) { $I = toupper(substr($I, 1, 1)) substr($I, 2) } print }'
}

function capture_web_thumbnails()
{
    # Best-effort screenshots via headless Chrome. Never fails the build.
    local WEB_DIR="${1}"
    shift
    local -a NAMES=("$@")

    local CHROME=""
    local -a CANDIDATES=(
        # macOS
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
        "/Applications/Chromium.app/Contents/MacOS/Chromium"
        "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
        # Linux (Debian/Ubuntu and other distros, including snap packages)
        "/usr/bin/google-chrome-stable"
        "/usr/bin/google-chrome"
        "/usr/bin/chromium-browser"
        "/usr/bin/chromium"
        "/snap/bin/chromium"
        "/usr/bin/microsoft-edge"
    )
    local C
    for C in "${CANDIDATES[@]}"; do
        [[ -x "${C}" ]] && CHROME="${C}" && break
    done
    if [[ -z "${CHROME}" ]]; then
        for C in google-chrome-stable google-chrome chromium chromium-browser microsoft-edge; do
            if check_cmd "${C}"; then CHROME="${C}"; break; fi
        done
    fi
    if [[ -z "${CHROME}" ]]; then
        log_warning "Chrome/Chromium not found - skipping thumbnail capture (placeholders will be used)"
        return 0
    fi
    if ! check_cmd npx; then
        log_warning "npx (Node.js) not found - skipping thumbnail capture (placeholders will be used)"
        return 0
    fi
    if ! check_cmd curl; then
        log_warning "curl not found - skipping thumbnail capture (placeholders will be used)"
        return 0
    fi

    log_info "Capturing example thumbnails with headless Chrome (best-effort)..."

    local PORT=4999
    local SERVE_LOG
    SERVE_LOG="$(mktemp)"
    ( cd "${WEB_DIR}" && exec npx --yes serve@14 . --no-clipboard -l "${PORT}" > "${SERVE_LOG}" 2>&1 ) &
    local SERVE_PID=$!

    local URL=""
    local I
    for ((I = 0; I < 60; I++)); do
        URL="$(grep -oE 'http://localhost:[0-9]+' "${SERVE_LOG}" 2>/dev/null | head -1 || true)"
        if [[ -n "${URL}" ]] && curl -fsS -o /dev/null "${URL}/" 2>/dev/null; then
            break
        fi
        URL=""
        sleep 0.25
    done

    if [[ -z "${URL}" ]]; then
        log_warning "Local preview server did not start - skipping thumbnail capture (placeholders will be used)"
    else
        mkdir -p "${WEB_DIR}/thumbnails"

        # A fully-rendered map screenshot is large; a near-blank capture (map/WASM
        # failed to load) is a tiny, near-solid-color PNG. Discard anything below
        # this size so the tile falls back to the styled placeholder instead of
        # showing an empty screenshot.
        local MIN_THUMB_BYTES=30000
        # Real wall-clock render wait (ms) for the DevTools capture path - long
        # enough for the map's async tiles / POIs to load before the frame.
        local RENDER_DELAY_MS=8000
        # Fallback (chrome --screenshot) only: virtual-time budget and the max
        # seconds to wait for that screenshot before giving up on an example.
        local RENDER_MS=30000
        local CAPTURE_TIMEOUT=70
        # Capture tall, then centre-crop to the tile's 16:10 so the map's middle is
        # framed and the app bar is dropped.
        local SHOT_W=1200 SHOT_H=1000 CROP_W=1200 CROP_H=750 THUMB_W=600

        # Preferred capture: drive Chrome via DevTools with a real render delay
        # (reliable). Falls back to `chrome --screenshot` if Node/WebSocket is
        # unavailable.
        local CAPTURE_MJS="${SCRIPT_DIR}/scripts/web-gallery/capture.mjs"
        local NODE_BIN=""
        check_cmd node && NODE_BIN="node"

        # Optional post-processing tool to crop + downscale (best-effort).
        local IMG_TOOL=""
        if check_cmd sips; then IMG_TOOL="sips"
        elif check_cmd magick; then IMG_TOOL="magick"
        elif check_cmd convert; then IMG_TOOL="convert"
        fi

        local NAME OUT BYTES PROFILE CPID WAITED
        for NAME in "${NAMES[@]}"; do
            OUT="${WEB_DIR}/thumbnails/${NAME}.png"
            rm -f "${OUT}"

            if ! { [[ -n "${NODE_BIN}" && -f "${CAPTURE_MJS}" ]] \
                    && "${NODE_BIN}" "${CAPTURE_MJS}" "${CHROME}" "${URL}/${NAME}/" "${OUT}" \
                        "${SHOT_W}" "${SHOT_H}" "${RENDER_DELAY_MS}" 2>/dev/null \
                    && [[ -s "${OUT}" ]]; }; then
                # Fallback: chrome --screenshot with virtual time (racier). Disable
                # web security (needs a throwaway profile) to get past CORS in
                # headless; allow SwiftShader so CanvasKit's WebGL renders without a
                # GPU. --no-sandbox: required when running as root (e.g. CI); capture
                # targets are localhost-only.
                rm -f "${OUT}"
                PROFILE="$(mktemp -d)"
                "${CHROME}" --headless=new --disable-gpu --no-sandbox \
                    --user-data-dir="${PROFILE}" --disable-web-security \
                    --enable-unsafe-swiftshader --hide-scrollbars \
                    --force-device-scale-factor=1 --window-size="${SHOT_W},${SHOT_H}" \
                    --virtual-time-budget="${RENDER_MS}" --screenshot="${OUT}" \
                    "${URL}/${NAME}/" > /dev/null 2>&1 &
                CPID=$!

                # Chrome writes the screenshot around the virtual-time budget but
                # does not reliably exit afterwards (CanvasKit keeps rendering), so
                # wait for the file rather than the process, then stop Chrome.
                WAITED=0
                while kill -0 "${CPID}" 2>/dev/null && [[ ${WAITED} -lt ${CAPTURE_TIMEOUT} ]]; do
                    if [[ -s "${OUT}" ]]; then sleep 2; break; fi
                    sleep 1
                    WAITED=$((WAITED + 1))
                done
                kill "${CPID}" 2>/dev/null || true
                wait "${CPID}" 2>/dev/null || true
                rm -rf "${PROFILE}"
            fi

            if [[ -s "${OUT}" ]]; then
                BYTES="$(wc -c < "${OUT}" | tr -d ' ')"
                if [[ "${BYTES}" -lt "${MIN_THUMB_BYTES}" ]]; then
                    rm -f "${OUT}"
                    log_warning "  ${NAME}: capture looked blank (${BYTES} bytes) - using placeholder"
                else
                    # Centre-crop out the app bar and downscale to a light thumbnail.
                    case "${IMG_TOOL}" in
                        sips)
                            sips -c "${CROP_H}" "${CROP_W}" "${OUT}" > /dev/null 2>&1 || true
                            sips --resampleWidth "${THUMB_W}" "${OUT}" > /dev/null 2>&1 || true
                            ;;
                        magick|convert)
                            "${IMG_TOOL}" "${OUT}" -gravity center \
                                -crop "${CROP_W}x${CROP_H}+0+0" +repage \
                                -resize "${THUMB_W}" "${OUT}" > /dev/null 2>&1 || true
                            ;;
                    esac
                    log_info "  captured ${NAME}"
                fi
            else
                rm -f "${OUT}"
                log_warning "  could not capture ${NAME} (placeholder will be used)"
            fi
        done
    fi

    kill "${SERVE_PID}" > /dev/null 2>&1 || true
    wait "${SERVE_PID}" 2>/dev/null || true
    local SERVE_PORT="${URL##*:}"
    [[ -z "${SERVE_PORT}" ]] && SERVE_PORT="${PORT}"
    lsof -ti "tcp:${SERVE_PORT}" 2>/dev/null | xargs kill 2>/dev/null || true
    rm -f "${SERVE_LOG}"
}

function generate_web_gallery()
{
    local WEB_DIR="${SCRIPT_DIR}/_WEB"
    local TEMPLATE_DIR="${SCRIPT_DIR}/scripts/web-gallery"
    local README="${SCRIPT_DIR}/README.md"

    [[ -d "${WEB_DIR}" ]] || return 0

    if [[ ! -f "${TEMPLATE_DIR}/index.html" || ! -f "${TEMPLATE_DIR}/serve.command" || ! -f "${TEMPLATE_DIR}/serve.sh" ]]; then
        log_warning "Gallery templates missing under ${TEMPLATE_DIR} - skipping gallery generation"
        return 0
    fi

    log_step "Generating web gallery..."

    cp "${TEMPLATE_DIR}/index.html" "${WEB_DIR}/index.html"
    cp "${TEMPLATE_DIR}/serve.command" "${WEB_DIR}/serve.command"
    cp "${TEMPLATE_DIR}/serve.sh" "${WEB_DIR}/serve.sh"
    chmod +x "${WEB_DIR}/serve.command" "${WEB_DIR}/serve.sh"

    # Examples actually built = _WEB subdirs that contain an index.html.
    local -a NAMES=()
    local DIR NAME
    for DIR in "${WEB_DIR}"/*/; do
        NAME="$(basename "${DIR}")"
        [[ "${NAME}" == "thumbnails" ]] && continue
        [[ -f "${DIR}index.html" ]] && NAMES+=("${NAME}")
    done

    if [[ ${#NAMES[@]} -eq 0 ]]; then
        log_warning "No built web examples found in _WEB - skipping gallery data"
        return 0
    fi

    if "${WEB_THUMBNAILS}"; then
        capture_web_thumbnails "${WEB_DIR}" "${NAMES[@]}"
    fi

    local SDK_VERSION=""
    local VLOCK="${SCRIPT_DIR}/${NAMES[0]}/pubspec.lock"
    if [[ -f "${VLOCK}" ]]; then
        SDK_VERSION="$(awk '
            /^  magiclane_maps_flutter:/ { inblk = 1; next }
            inblk && /^  [A-Za-z]/       { inblk = 0 }
            inblk && /^    version:/     { v = $2; gsub(/"/, "", v); print v; exit }
        ' "${VLOCK}")"
    fi

    local DATA="${WEB_DIR}/gallery-data.js"
    {
        printf '// Generated by build_all.sh - do not edit.\n'
        printf 'window.__GALLERY_VERSION__ = "%s";\n' "$(json_escape "${SDK_VERSION}")"
        printf 'window.__GALLERY__ = [\n'
    } > "${DATA}"

    local FIRST=1 TITLE DESC THUMB LINE
    for NAME in "${NAMES[@]}"; do
        TITLE=""
        DESC=""
        THUMB=""
        if [[ -f "${README}" ]]; then
            # Catalog format: * [Title](name) - Description.
            LINE="$(grep -E "^\* \[.*\]\(${NAME}\) - " "${README}" 2>/dev/null | head -1 || true)"
            if [[ -n "${LINE}" ]]; then
                TITLE="$(printf '%s' "${LINE}" | sed -E "s/^\* \[(.*)\]\(${NAME}\) - .*/\1/")"
                DESC="$(printf '%s' "${LINE}" | sed -E "s/^\* \[.*\]\(${NAME}\) - (.*)$/\1/")"
            fi
        fi
        [[ -z "${TITLE}" ]] && TITLE="$(title_case "${NAME}")"
        [[ -f "${WEB_DIR}/thumbnails/${NAME}.png" ]] && THUMB="thumbnails/${NAME}.png"

        [[ ${FIRST} -eq 0 ]] && printf ',\n' >> "${DATA}"
        FIRST=0
        printf '  {"name":"%s","title":"%s","description":"%s","thumb":"%s"}' \
            "$(json_escape "${NAME}")" \
            "$(json_escape "${TITLE}")" \
            "$(json_escape "${DESC}")" \
            "$(json_escape "${THUMB}")" >> "${DATA}"
    done
    printf '\n];\n' >> "${DATA}"

    log_success "Web gallery generated (${#NAMES[@]} example(s)): ${WEB_DIR}/index.html"
}

# =============================================================================
# Main
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

setup_mac_deps

SDK_ARCHIVE_PATH=""
API_TOKEN=""
BUILD_ANDROID=false
BUILD_IOS=false
BUILD_WEB=false
WEB_THUMBNAILS=false
NO_GALLERY=false
ANALYZE=false
UPGRADE=false
FAIL_FAST=false
CLEAN_ON_EXIT=false
LIST_EXAMPLES=false

if is_ci; then
    CLEAN_ON_EXIT=true
fi

SHORTOPTS="h"
LONGOPTS_LIST=(
    "help"
    "sdk-archive:"
    "api-token:"
    "android"
    "ios"
    "web"
    "web-thumbnails"
    "no-gallery"
    "list-examples"
    "only:"
    "exclude:"
    "analyze"
    "upgrade"
    "fail-fast"
    "clean"
    "console:"
)

if ! PARSED_OPTIONS="$(getopt \
    -s bash \
    --options "${SHORTOPTS}" \
    --longoptions "$(printf "%s," "${LONGOPTS_LIST[@]}")" \
    --name "${PROGNAME}" \
    -- "$@")"; then
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
        --api-token)
            shift
            API_TOKEN="${1}"
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
        --web-thumbnails)
            BUILD_WEB=true
            WEB_THUMBNAILS=true
            ;;
        --no-gallery)
            NO_GALLERY=true
            ;;
        --list-examples)
            LIST_EXAMPLES=true
            ;;
        --only)
            shift
            ONLY_EXAMPLES+=("${1}")
            ;;
        --exclude)
            shift
            EXCLUDE_EXAMPLES+=("${1}")
            ;;
        --analyze)
            ANALYZE=true
            ;;
        --upgrade)
            UPGRADE=true
            ;;
        --fail-fast)
            FAIL_FAST=true
            ;;
        --clean)
            CLEAN_ON_EXIT=true
            ;;
        --console)
            shift
            CONSOLE_MODE="${1}"
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

apply_console_mode

log_step "Checking prerequisites..."

if "${BUILD_IOS}" && ! is_mac; then
    log_error "Examples can be built for iOS only under macOS"
    exit 1
fi

if ! is_mac && [[ -z "${SDK_ARCHIVE_PATH}" ]]; then
    log_error "On Linux, the --sdk-archive option is required because the pub.dev version"
    log_error "includes iOS dependencies that cannot be resolved on non-macOS systems"
    log_error ""
    log_error "Please provide an SDK archive:"
    log_error "  ${PROGNAME} --sdk-archive=/path/to/sdk.tar.bz2 --android --analyze"
    exit 1
fi

# Avoid dependency resolution errors
if is_mac; then
    log_info "Enabling Swift Package Manager on macOS..."
    flutter config --enable-swift-package-manager 2>/dev/null || true

    if "${CLEAN_ON_EXIT}"; then
        clear_spm_cache
    fi
fi

if [[ -n "${SDK_ARCHIVE_PATH}" ]] && [[ ! -f "${SDK_ARCHIVE_PATH}" ]]; then
    log_error "SDK archive file not found: ${SDK_ARCHIVE_PATH}"
    usage
    exit 1
fi

if ! check_cmd flutter; then
    log_error "flutter command not found"
    log_error "Please get it from: https://docs.flutter.dev/get-started/install"
    exit 2
fi

log_info "Running flutter doctor..."
if ! flutter doctor; then
    log_error "flutter doctor failed"
    exit 1
fi

check_ios_prerequisites

extract_sdk_archive

if [[ -z "${SDK_ARCHIVE_PATH}" ]]; then
    log_info "No SDK archive provided, will use magiclane_maps_flutter from pub.dev"
fi

discover_examples

if "${LIST_EXAMPLES}"; then
    list_examples
    exit 0
fi

if filtering_active; then
    validate_filter_names
fi
filter_examples

# Setup output directories
pushd "${SCRIPT_DIR}" > /dev/null || exit 1

if "${BUILD_ANDROID}"; then
    rm -rf _APK
    mkdir -p _APK
fi

if "${BUILD_WEB}"; then
    rm -rf _WEB
    mkdir -p _WEB
fi

popd > /dev/null || true

TOTAL_EXAMPLES=${#EXAMPLE_PROJECTS[@]}
CURRENT_INDEX=0
declare -a FAILED_EXAMPLES=()

for EXAMPLE_PATH in "${EXAMPLE_PROJECTS[@]}"; do
    CURRENT_INDEX=$((CURRENT_INDEX + 1))

    # Run each build as a background job
    build_example "${EXAMPLE_PATH}" "${CURRENT_INDEX}" "${TOTAL_EXAMPLES}" &
    CURRENT_BUILD_PID=$!
    if ! wait "${CURRENT_BUILD_PID}"; then
        FAILED_EXAMPLES+=("$(basename "${EXAMPLE_PATH}")")
        log_error "Build failed for '$(basename "${EXAMPLE_PATH}")'"

        if "${FAIL_FAST}"; then
            exit 1
        fi
    fi
    CURRENT_BUILD_PID=""
done

# Generate the gallery for whatever did build, even if some examples failed.
if "${BUILD_WEB}" && ! "${NO_GALLERY}"; then
    generate_web_gallery
fi

if [[ ${#FAILED_EXAMPLES[@]} -gt 0 ]]; then
    log_error "${#FAILED_EXAMPLES[@]} of ${TOTAL_EXAMPLES} example(s) failed to build: ${FAILED_EXAMPLES[*]}"
    exit 1
fi

exit 0
