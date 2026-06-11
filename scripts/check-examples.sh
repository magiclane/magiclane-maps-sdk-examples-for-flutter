#!/usr/bin/env bash
# vim:ts=4:sts=4:sw=4:et
# shellcheck disable=SC2317,SC2329

# SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
# SPDX-License-Identifier: Apache-2.0
#
# Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

set -eEuo pipefail

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
        "gnu-sed:gnu-sed/libexec/gnubin"
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

function ctrl_c()
{
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

    if [[ ${EXIT_CODE} -eq 0 ]]; then
        log_success "All checks passed"
    else
        log_error "Some checks failed (exit code ${EXIT_CODE})"
    fi

    printf '\n'
    log_info "Bye-Bye"

    exit "${EXIT_CODE}"
}
trap on_exit EXIT

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

setup_mac_deps

log_step "Checking prerequisites..."

if ! check_cmd flutter; then
    log_error "Missing flutter"
    log_error "Please get it from: https://docs.flutter.dev/get-started/install"
    exit 2
fi

log_info "Running flutter doctor..."
if ! flutter doctor; then
    log_error "flutter doctor failed"
    exit 1
fi

log_step "Discovering examples..."

mapfile -t EXAMPLE_PROJECTS < <(
    find "${PROJECT_DIR}" -maxdepth 2 -type d -exec [ -d "{}/plugins" ] \; -print 2>/dev/null | sort
)

if [[ ${#EXAMPLE_PROJECTS[@]} -eq 0 ]]; then
    log_error "No examples found under ${PROJECT_DIR} (expected <example>/plugins)"
    exit 1
fi

log_info "Found ${#EXAMPLE_PROJECTS[@]} example(s)"

function check_app_identifiers()
{
    local RC=0
    local EXAMPLE_PATH EXAMPLE_NAME EXAMPLE_NAME_NO_UNDERSCORE

    for EXAMPLE_PATH in "${EXAMPLE_PROJECTS[@]}"; do
        EXAMPLE_NAME="$(basename "${EXAMPLE_PATH}")"
        log_info "Check '${EXAMPLE_NAME}' for app identifiers..."

        EXAMPLE_NAME_NO_UNDERSCORE="${EXAMPLE_NAME//_}"

        if [[ "${EXAMPLE_NAME}" != "${EXAMPLE_NAME_NO_UNDERSCORE}" ]]; then
            if grep -irl --exclude "*.dart" --exclude "README.md" --exclude-dir "magiclane_maps_flutter" \
                "${EXAMPLE_NAME_NO_UNDERSCORE}" "${EXAMPLE_PATH}" 2>/dev/null; then
                log_warning "Found wrong app identifier: '${EXAMPLE_NAME_NO_UNDERSCORE}' in '${EXAMPLE_NAME}'"
                RC=1
                find "${EXAMPLE_PATH}" -path "*/plugins/magiclane_maps_flutter" -prune -o \
                    \( -type f -not \( -wholename "*/.git*" -o -name "*.dart" -o -name "README.md" \) \) \
                    -exec sed -i "s/${EXAMPLE_NAME_NO_UNDERSCORE}/${EXAMPLE_NAME}/gI" {} + 2>/dev/null || true
            fi
        fi

        # Fix product bundle identifier
        find "${EXAMPLE_PATH}" -path "*/plugins/magiclane_maps_flutter" -prune -o \
            \( -type f -not \( -wholename "*/.git*" -o -name "*.dart" \) \) \
            -exec sed -i "s/PRODUCT_BUNDLE_IDENTIFIER = com\.example\./PRODUCT_BUNDLE_IDENTIFIER = com.magiclane.magiclane_maps_flutter.examples./g" {} + 2>/dev/null || true

        # Fix product copyright
        find "${EXAMPLE_PATH}" -path "*/plugins/magiclane_maps_flutter" -prune -o \
            \( -type f -not \( -wholename "*/.git*" -o -name "*.dart" \) \) \
            -exec sed -i "s/PRODUCT_COPYRIGHT = Copyright © 2024 com\.example\. All rights reserved./PRODUCT_COPYRIGHT = 2023-2026 Magic Lane International B.V. <info@magiclane.com>/g" {} + 2>/dev/null || true
    done

    return ${RC}
}

function check_mismatch()
{
    local RC=0
    local EXAMPLE_PATH_I EXAMPLE_PATH_J
    local EXAMPLE_NAME_I EXAMPLE_NAME_J
    local EXAMPLE_NAME_I_NO_UNDERSCORE EXAMPLE_NAME_J_NO_UNDERSCORE
    local -a MISMATCH_DIRS
    local DIR DIR_PARENT DIR_NEW

    for EXAMPLE_PATH_I in "${EXAMPLE_PROJECTS[@]}"; do
        EXAMPLE_NAME_I="$(basename "${EXAMPLE_PATH_I}")"
        log_info "Check '${EXAMPLE_NAME_I}' for mismatches..."

        for EXAMPLE_PATH_J in "${EXAMPLE_PROJECTS[@]}"; do
            [[ "${EXAMPLE_PATH_I}" == "${EXAMPLE_PATH_J}" ]] && continue

            EXAMPLE_NAME_J="$(basename "${EXAMPLE_PATH_J}")"

            # Check for example name mismatch in files
            if grep -irl --exclude "*.dart" --exclude "*.style" --exclude-dir "magiclane_maps_flutter" \
                "${EXAMPLE_NAME_J}" "${EXAMPLE_PATH_I}" > /dev/null 2>&1; then
                if [[ "${EXAMPLE_PATH_I}" != *"${EXAMPLE_NAME_J}"* ]]; then
                    log_error "Found mismatch string: '${EXAMPLE_NAME_J}' in '${EXAMPLE_NAME_I}'"
                    RC=1
                    find "${EXAMPLE_PATH_I}" -path "*/plugins/magiclane_maps_flutter" -prune -o \
                        \( -type f -not \( -wholename "*/.git*" -o -name "*.dart" -o -name "*.style" \) \) \
                        -exec sed -i "s/${EXAMPLE_NAME_J}/${EXAMPLE_NAME_I}/g" {} + 2>/dev/null || true
                fi
            fi

            # Check for no-underscore variant mismatch
            EXAMPLE_NAME_I_NO_UNDERSCORE="${EXAMPLE_NAME_I//_}"
            EXAMPLE_NAME_J_NO_UNDERSCORE="${EXAMPLE_NAME_J//_}"

            if grep -irl --exclude "*.dart" --exclude "*.style" --exclude-dir "magiclane_maps_flutter" \
                "${EXAMPLE_NAME_J_NO_UNDERSCORE}" "${EXAMPLE_PATH_I}" > /dev/null 2>&1; then
                if [[ "${EXAMPLE_NAME_I_NO_UNDERSCORE}" != *"${EXAMPLE_NAME_J_NO_UNDERSCORE}"* ]]; then
                    log_error "Found mismatch string: '${EXAMPLE_NAME_J_NO_UNDERSCORE}' in '${EXAMPLE_NAME_I}'"
                    RC=1
                    find "${EXAMPLE_PATH_I}" -path "*/plugins/magiclane_maps_flutter" -prune -o \
                        \( -type f -not \( -wholename "*/.git*" -o -name "*.dart" -o -name "*.style" \) \) \
                        -exec sed -i "s/${EXAMPLE_NAME_J_NO_UNDERSCORE}/${EXAMPLE_NAME_I//_}/gI" {} + 2>/dev/null || true
                fi
            fi

            # Check for mismatched directories
            if [[ "${EXAMPLE_NAME_I}" != *"${EXAMPLE_NAME_J}"* ]]; then
                MISMATCH_DIRS=()
                mapfile -t MISMATCH_DIRS < <(
                    find "${EXAMPLE_PATH_I}" -path "*/plugins/magiclane_maps_flutter" -prune -o \
                        \( -type d -not -wholename "*/.git*" -name "${EXAMPLE_NAME_J}" \) -print 2>/dev/null
                )

                if [[ ${#MISMATCH_DIRS[@]} -gt 0 ]]; then
                    log_error "Found mismatch folder: '${EXAMPLE_NAME_J}' in '${EXAMPLE_NAME_I}'"
                    RC=1

                    for DIR in "${MISMATCH_DIRS[@]}"; do
                        [[ -z "${DIR}" ]] && continue
                        [[ ! -d "${DIR}" ]] && continue

                        DIR_PARENT="$(dirname "${DIR}")"
                        DIR_NEW="${DIR_PARENT}/${EXAMPLE_NAME_I}"

                        if [[ ! -e "${DIR_NEW}" ]]; then
                            mv -v "${DIR}" "${DIR_NEW}" 2>/dev/null || true
                        else
                            log_warning "Cannot rename '${DIR}' -> '${DIR_NEW}' (target exists)"
                        fi
                    done
                fi
            fi
        done
    done

    return ${RC}
}

function check_secrets()
{
    local RC=0
    local EXAMPLE_PATH EXAMPLE_NAME
    local -a MAIN_FILES
    local FILE

    for EXAMPLE_PATH in "${EXAMPLE_PROJECTS[@]}"; do
        EXAMPLE_NAME="$(basename "${EXAMPLE_PATH}")"
        log_info "Check '${EXAMPLE_NAME}' for secrets..."

        MAIN_FILES=()
        mapfile -t MAIN_FILES < <(
            find "${EXAMPLE_PATH}" -path "*/plugins/magiclane_maps_flutter" -prune -o \
                \( -type f -name "main.dart" \) -print 2>/dev/null
        )

        [[ ${#MAIN_FILES[@]} -eq 0 ]] && continue

        for FILE in "${MAIN_FILES[@]}"; do
            [[ -z "${FILE}" ]] && continue

            # Check if projectApiToken is NOT loaded from environment
            if ! grep -q "projectApiToken.*fromEnvironment.*YOUR_API_TOKEN_HERE" "${FILE}" 2>/dev/null; then
                log_error "'${EXAMPLE_NAME}' main.dart: projectApiToken not loaded from environment"
                RC=1
            fi

            # Check if projectApiToken has a hardcoded JWT token value
            if grep -qE '(const|final|var)\s+projectApiToken\s*=\s*"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+"' "${FILE}" 2>/dev/null; then
                log_error "'${EXAMPLE_NAME}' main.dart: contains hardcoded JWT token"
                RC=1
            fi

            # Check if appAuthorization uses projectApiToken (directly or via token variable)
            if ! grep -Eq "appAuthorization\s*:\s*projectApiToken" "${FILE}" 2>/dev/null; then
                if ! grep -Eq "GemKit\.initialize\(appAuthorization:\s*token\)" "${FILE}" 2>/dev/null; then
                    log_error "'${EXAMPLE_NAME}' main.dart: appAuthorization not using projectApiToken or token variable"
                    RC=1
                fi
            fi
        done
    done

    if [[ ${RC} -eq 1 ]]; then
        log_error "Secrets issues found. Please check"
    fi

    return ${RC}
}

function check_license()
{
    local RC=0
    local EXAMPLE_PATH EXAMPLE_NAME
    local -a SOURCES_WITH_MISSING_SPDX
    local -a SOURCES
    local FILE
    local MISSING_COPYRIGHT MISSING_LICENSE

    local FILE_EXCEPTIONS='(^|/)(GeneratedPluginRegistrant\.(h|swift|kt|java)|AppDelegate\.swift|Runner-Bridging-Header\.h|RunnerTests\.swift|my_application\.h|generated_plugin_registrant\.(h|cc))$'
    local DIR_EXCEPTIONS='^\.?/?(plugins|build|\.dart_tool)/'

    for EXAMPLE_PATH in "${EXAMPLE_PROJECTS[@]}"; do
        EXAMPLE_NAME="$(basename "${EXAMPLE_PATH}")"
        log_info "Check '${EXAMPLE_NAME}' for license..."

        SOURCES_WITH_MISSING_SPDX=()
        SOURCES=()

        pushd "${EXAMPLE_PATH}" > /dev/null || continue

        # Collect sources from git or find fallback
        mapfile -t SOURCES < <(
            git ls-files -- '*.h' '*.dart' '*.swift' '*.kt' '*.sh' 2>/dev/null || \
            find . -type f \( -name "*.h" -o -name "*.dart" -o -name "*.swift" -o -name "*.kt" -o -name "*.sh" \) 2>/dev/null
        )

        # Filter and check each file
        while IFS= read -r FILE; do
            [[ -z "${FILE}" ]] && continue

            MISSING_COPYRIGHT=false
            MISSING_LICENSE=false

            # Match comment styles: //, #, /*, or * (multi-line comment continuation)
            if ! grep -qE '^[[:space:]]*(//|#|/\*|\*)[[:space:]]*SPDX-FileCopyrightText:' "${FILE}" 2>/dev/null; then
                MISSING_COPYRIGHT=true
            fi

            if ! grep -qE '^[[:space:]]*(//|#|/\*|\*)[[:space:]]*SPDX-License-Identifier:' "${FILE}" 2>/dev/null; then
                MISSING_LICENSE=true
            fi

            if "${MISSING_COPYRIGHT}" || "${MISSING_LICENSE}"; then
                local REASON=""
                if "${MISSING_COPYRIGHT}" && "${MISSING_LICENSE}"; then
                    REASON="missing both SPDX headers"
                elif "${MISSING_COPYRIGHT}"; then
                    REASON="missing SPDX-FileCopyrightText"
                else
                    REASON="missing SPDX-License-Identifier"
                fi
                SOURCES_WITH_MISSING_SPDX+=("${EXAMPLE_PATH}/${FILE#./} (${REASON})")
            fi
        done < <(printf '%s\n' "${SOURCES[@]}" | sort -u | grep -vE "${DIR_EXCEPTIONS}" | grep -vE "${FILE_EXCEPTIONS}")

        popd > /dev/null || true

        if [[ ${#SOURCES_WITH_MISSING_SPDX[@]} -gt 0 ]]; then
            log_error "Following files have SPDX header issues in '${EXAMPLE_NAME}':"
            printf '    @ %s\n' "${SOURCES_WITH_MISSING_SPDX[@]}"
            printf '\n'
            RC=1
        fi
    done

    if [[ ${RC} -eq 1 ]]; then
        log_error "Missing license/copyright identifiers. Please check"
    fi

    return ${RC}
}

# =============================================================================
# Main
# =============================================================================

RC=0

log_step "Checking app identifiers..."
check_app_identifiers || RC=1

log_step "Checking folder/file mismatches..."
check_mismatch || RC=1

log_step "Checking secrets..."
check_secrets || RC=1

log_step "Checking licenses..."
check_license || RC=1

exit "${RC}"
