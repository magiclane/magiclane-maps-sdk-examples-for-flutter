#!/usr/bin/env bash
# vim:ts=4:sts=4:sw=4:et

# SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
# SPDX-License-Identifier: BSD-3-Clause
#
# Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

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

if ! command -v flutter >/dev/null; then
    error_msg "flutter command not found. Please get it from: https://docs.flutter.dev/get-started/install"
    printf '\n'
    exit 2
fi

flutter doctor || ( error_msg "flutter doctor failed"; exit 1 ) 

msg "Running 'dart format' to check examples dart style."

MY_DIR="$(cd "$(dirname "${0}")" && pwd)"

# Find paths that contain an app module
mapfile -t EXAMPLE_PROJECTS < <(find "${MY_DIR}/.." -maxdepth 1 -type d -exec [ -d "{}/plugins" ] \; -exec realpath {} \; 2>/dev/null)

FORMAT_OK=1
for EXAMPLE_PATH in "${EXAMPLE_PROJECTS[@]}"; do
	EXAMPLE_NAME="$(basename "${EXAMPLE_PATH}")"

    msg "Check '${EXAMPLE_PATH}'..."
    
	if [ ! -d "${EXAMPLE_PATH}"/plugins/gem_kit ]; then
		error_msg "Can not format '${EXAMPLE_NAME}'. Copy gem_kit to '${EXAMPLE_PATH}/plugins/'"
		exit 2
	fi

    pushd "${EXAMPLE_PATH}" &>/dev/null

	flutter clean > /dev/null 2>&1

    flutter pub get --offline > /dev/null 2>&1

    RESULT=$(dart format --output write lib)
    STATUS=${?}

    if (( STATUS != 0 )); then
        error_msg "Format command failed"
        exit 2
    elif [[ ${RESULT} == *"0 changed"* ]]; then
        msg "All format is good"
    else
        error_msg "${RESULT}"
        FORMAT_OK=0
    fi

    popd &>/dev/null
done

if [[ ${FORMAT_OK} -eq 0 ]]; then
     msg "*** Some Dart files were formatted ***"
     exit 1
fi

exit 0
