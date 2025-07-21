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

# shellcheck disable=SC2317
function ctrl_c()
{
    exit 1
}
trap ctrl_c INT

# shellcheck disable=SC2317
function on_exit()
{
    msg "Bye-Bye"
}
trap 'on_exit' EXIT

function is_mac() {
    local OS_NAME
    OS_NAME=$(uname | tr "[:upper:]" "[:lower:]")
    if [[ ${OS_NAME} =~ "darwin" ]]; then
        return 0
    fi

    return 1
}

if is_mac; then
    if [ ! -f "$(brew --prefix)/opt/gnu-getopt/bin/getopt" ]; then
        error_msg "This script requires 'brew install gnu-getopt && brew link --force gnu-getopt'"
        exit 1
    fi

    PATH="$(brew --prefix)/opt/gnu-getopt/bin:${PATH}"
fi

set -eEuo pipefail

GEM_KIT_PATH=""

MY_DIR="$(cd "$(dirname "$0")" && pwd)"

function usage()
{
    echo -e "\033[32;1m
Usage: ${PROGNAME} [options] 

Options:
    [REQUIRED] --gem_kit=<path>
                    Set path to gem_kit
\033[0m\n"
}

LONGOPTS_LIST=(
    "gem_kit:"
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
        --gem_kit)
            shift
            GEM_KIT_PATH="${1}"
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

if [[ ! -d "${GEM_KIT_PATH}" ]]; then
    error_msg "You must provide local path to gem_kit"
    usage
    exit 1
fi

if ! command -v flutter >/dev/null; then
    error_msg "flutter command not found. Please get it from: https://docs.flutter.dev/get-started/install"
    printf '\n'
    exit 2
fi

flutter doctor || ( error_msg "flutter doctor failed"; exit 1 ) 

# Find paths that contain an app module
mapfile -t EXAMPLE_PROJECTS < <(find "${MY_DIR}/.." -maxdepth 2 -type d -exec [ -d "{}/plugins" ] \; -exec realpath {} \; 2>/dev/null)

for EXAMPLE_PATH in "${EXAMPLE_PROJECTS[@]}"; do
	if [[ ! -d "${EXAMPLE_PATH}"/plugins/gem_kit ]]; then
		mkdir -p "${EXAMPLE_PATH}"/plugins/gem_kit
	fi

    msg "Copying plugin sources to '${EXAMPLE_PATH}/plugins/gem_kit/'..."

	if ! cp -a "${GEM_KIT_PATH}"/* "${EXAMPLE_PATH}/plugins/gem_kit/"; then
		error_msg "Error copying plugin sources"
		printf '\n'
		exit 1
	fi
done
