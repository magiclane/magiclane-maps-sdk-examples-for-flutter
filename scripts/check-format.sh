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
    echo
    exit 2
fi

flutter doctor || ( error_msg "flutter doctor failed"; exit 1 ) 

msg "Running 'dart format' to check examples dart style."

MY_DIR="$(cd "$(dirname "${0}")" && pwd)"

# Find paths that contain an app module
EXAMPLE_PROJECTS=$(find "${MY_DIR}/.." -maxdepth 1 -type d -exec [ -d {}/plugins ] \; -print -prune)

FORMAT_OK=1
for EXAMPLE_PATH in ${EXAMPLE_PROJECTS}; do
    msg "Check '${EXAMPLE_PATH}'..."
    
    pushd "${EXAMPLE_PATH}" &>/dev/null

    RESULT=$(dart format --fix lib)

    if [[ ${?} != 0 ]]; then
        error_msg "Command failed."
    elif [[ ${RESULT} == *"0 changed"* ]]; then
        msg "All format is good"
    else
        error_msg "${RESULT}"
        FORMAT_OK=0
    fi

    popd &>/dev/null
done

if [ ${FORMAT_OK} -eq 0 ]; then
     error_msg "Some files are not well formated"
     exit 1
fi

exit 0
