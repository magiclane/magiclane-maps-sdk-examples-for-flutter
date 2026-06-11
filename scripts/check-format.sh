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
        log_success "Format check completed successfully"
    else
        log_error "Format check failed (exit code ${EXIT_CODE})"
    fi

    printf '\n'
    log_info "Bye-Bye"

    exit "${EXIT_CODE}"
}
trap on_exit EXIT

function main()
{
    local SCRIPT_DIR
    local PROJECT_DIR
    local -a EXAMPLE_PROJECTS
    local EXAMPLE_PATH EXAMPLE_NAME
    local RESULT STATUS
    local FORMAT_OK

    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

    setup_mac_deps

    log_step "Checking prerequisites..."

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

    log_step "Discovering examples..."

    mapfile -t EXAMPLE_PROJECTS < <(
        find "${PROJECT_DIR}" -maxdepth 2 -type d -exec [ -d "{}/plugins" ] \; -print 2>/dev/null | sort
    )

    if [[ ${#EXAMPLE_PROJECTS[@]} -eq 0 ]]; then
        log_error "No examples found under ${PROJECT_DIR} (expected <example>/plugins)"
        exit 1
    fi

    log_info "Found ${#EXAMPLE_PROJECTS[@]} example(s)"

    log_step "Running 'dart format' to check examples dart style..."

    FORMAT_OK=true

    for EXAMPLE_PATH in "${EXAMPLE_PROJECTS[@]}"; do
        EXAMPLE_NAME="$(basename "${EXAMPLE_PATH}")"
        log_info "Checking '${EXAMPLE_NAME}'..."

        pushd "${EXAMPLE_PATH}" > /dev/null || continue

        flutter clean > /dev/null 2>&1 || true
        flutter pub get > /dev/null 2>&1 || true

        set +e
        RESULT="$(dart format --output write lib 2>&1)"
        STATUS=$?
        set -e

        if [[ ${STATUS} -ne 0 ]]; then
            log_error "Format command failed for '${EXAMPLE_NAME}'"
            popd > /dev/null || true
            exit 2
        elif [[ "${RESULT}" == *"0 changed"* ]]; then
            log_success "'${EXAMPLE_NAME}' format is good"
        else
            log_warning "'${EXAMPLE_NAME}' files were formatted:"
            printf '%s\n' "${RESULT}"
            FORMAT_OK=false
        fi

        popd > /dev/null || true
    done

    log_step "Summary"

    if ! "${FORMAT_OK}"; then
        log_warning "Some Dart files were formatted"
        exit 1
    fi

    exit 0
}

# =============================================================================
# Main
# =============================================================================

main "$@"
