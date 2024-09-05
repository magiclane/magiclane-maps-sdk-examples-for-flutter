#!/usr/bin/env bash
# vim:ts=4:sts=4:sw=4:et

# Copyright (C) 2019-2024, Magic Lane B.V.
# All rights reserved.
#
# This software is confidential and proprietary information of Magic Lane
# ("Confidential Information"). You shall not disclose such Confidential
# Information and shall use it only in accordance with the terms of the
# license agreement you entered into with Magic Lane.

function msg() {
    echo -e "\033[33;1m[*] $*\033[0m\n"
}

function error_msg() {
    echo -e "\033[31;1m[!] $*\033[0m\n" >&2
}

function ctrl_c()
{
    exit 1
}
trap ctrl_c INT

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

function check_cmd() {
    type "${1}" >/dev/null 2>&1;
}

if is_mac; then
    if ! check_cmd brew; then
        error_msg "Missing Homebrew. Run: \n\
$ bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi

    if [ ! -f "$(brew --prefix)/opt/gnu-getopt/bin/getopt" ]; then
        error_msg "Missing gnu-getopt. Run 'brew install gnu-getopt && brew link --force gnu-getopt'"
        exit 1
    fi
    export PATH="$(brew --prefix)/opt/gnu-getopt/bin:${PATH}"

    if ! brew ls --versions gnu-sed > /dev/null; then
        error_msg "Missing gnu-sed. Run 'brew install gnu-sed && brew link --force gnu-sed'"
        exit 1
    fi
    export PATH="$(brew --prefix)/opt/gnu-sed/libexec/gnubin:${PATH}"

    if ! brew ls --versions grep > /dev/null; then
        error_msg "Missing grep. Run 'brew install grep && brew link --force grep'"
        exit 1
    fi
    export PATH="$(brew --prefix)/opt/grep/libexec/gnubin:${PATH}"

    if ! brew ls --versions coreutils > /dev/null; then
        error_msg "Missing coreutils. Run 'brew install coreutils && brew link --force coreutils'"
        exit 1
    fi
    export PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:${PATH}"

    if ! brew ls --versions findutils > /dev/null; then
        error_msg "Missing findutils. Run 'brew install findutils && brew link --force findutils'"
        exit 1
    fi
    export PATH="$(brew --prefix)/opt/findutils/libexec/gnubin:${PATH}"

    if ! brew ls --versions rename > /dev/null; then
        error_msg "Missing rename. Run 'brew install rename && brew link --force rename'"
        exit 1
    fi
    export PATH="$(brew --prefix)/opt/rename/libexec/gnubin:${PATH}"
else
	if ! check_cmd rename; then
		error_msg "Missing rename. Run 'apt install rename'"
		echo
		exit 2
	fi
fi

set -eEuo pipefail

if ! check_cmd flutter; then
    error_msg "Missing flutter. Please get it from: https://docs.flutter.dev/get-started/install"
    echo
    exit 2
fi

flutter doctor || ( error_msg "flutter doctor failed"; exit 1 ) 

MY_DIR="$(cd "$(dirname "${0}")" && pwd)"

# Find paths that contain an app module
EXAMPLE_PROJECTS=( $(find "${MY_DIR}/.." -maxdepth 2 -type d -exec [ -d {}/plugins ] \; -print -prune) )

for i in "${!EXAMPLE_PROJECTS[@]}"; do
    msg "Check '${EXAMPLE_PROJECTS[${i}]}'..."

    EXAMPLE_I="$(basename ${EXAMPLE_PROJECTS[${i}]})"
    for j in "${!EXAMPLE_PROJECTS[@]}"; do
        if [ ${i} -eq ${j} ]; then
            continue
        fi

        EXAMPLE_J="$(basename ${EXAMPLE_PROJECTS[${j}]})"
        if grep -irl "${EXAMPLE_J}" ${EXAMPLE_PROJECTS[${i}]}; then
            msg "Found mismatch string: '${EXAMPLE_J}' in '${EXAMPLE_I}'"
            find ${EXAMPLE_PROJECTS[${i}]} -type f -not \( -wholename "*/.git*" -prune \) -exec sed -i "s/${EXAMPLE_J}/${EXAMPLE_I}/g" {} +
        fi
        EXAMPLE_J_NO_UNDERSCORE=${EXAMPLE_J//_}
        if grep -irl --exclude "*.dart" --exclude-dir "*/gem_kit" "${EXAMPLE_J_NO_UNDERSCORE}" ${EXAMPLE_PROJECTS[${i}]}; then
            msg "Found mismatch string: '${EXAMPLE_J_NO_UNDERSCORE}' in '${EXAMPLE_I}'"
            find ${EXAMPLE_PROJECTS[${i}]} -type f -not \( -wholename "*/.git*" -or -name "*.dart" -prune \) -not -path "*/gem_kit" -exec sed -i "s/${EXAMPLE_J_NO_UNDERSCORE}/${EXAMPLE_I//_}/gI" {} +
        fi
        MISMATCH_DIRS=( $(find "${EXAMPLE_PROJECTS[${i}]}" -type d -not \( -wholename "*/.git*" -prune \) -not -path "*/gem_kit" -name "${EXAMPLE_J}" 2>/dev/null) )
		if [ ${#MISMATCH_DIRS[@]} -gt 0 ]; then
			msg "Found mismatch folder: '${EXAMPLE_J}' in '${EXAMPLE_I}'"
			find ${EXAMPLE_PROJECTS[${i}]} -depth -type d -not \( -wholename "*/.git*" -prune \) -not -path "*/gem_kit" -name "${EXAMPLE_J}" -execdir rename -v "s/${EXAMPLE_J}/${EXAMPLE_I}/" '{}' +
		fi
    done
done
