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

set -eEuo pipefail

MY_DIR="$(cd "$(dirname "$0")" && pwd)"

msg "Checking prerequisites..."

if ! command -v flutter >/dev/null; then
    error_msg "flutter command not found. Please get it from: https://docs.flutter.dev/get-started/install"
    echo
    exit 2
fi

flutter doctor || ( error_msg "flutter doctor failed"; exit 1 ) 

# Find paths that contain an app module
EXAMPLE_PROJECTS=( $(find "${MY_DIR}/.." -maxdepth 2 -type d -exec [ -d {}/plugins ] \; -print -prune | while read -r DIR; do realpath "${DIR}"; done) )

for EXAMPLE_PATH in "${EXAMPLE_PROJECTS[@]}"; do
	if [ -d "${EXAMPLE_PATH}"/plugins/gem_kit ]; then
		msg "Deleting plugin sources from '${EXAMPLE_PATH}/plugins/gem_kit/'..."

		rm -rf "${EXAMPLE_PATH:?}"/plugins/gem_kit
		if [[ ${?} != 0 ]]; then
			error_msg "Error deleting plugin sources"
			echo
			exit 1
		fi
	fi
done
