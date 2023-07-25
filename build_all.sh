#!/bin/bash

# Copyright (C) 2019-2023, Magic Lane B.V.
# All rights reserved.
#
# This software is confidential and proprietary information of Magic Lane
# ("Confidential Information"). You shall not disclose such Confidential
# Information and shall use it only in accordance with the terms of the
# license agreement you entered into with Magic Lane.

function msg() {
    echo -e "[*] $@"
}

function error_msg() {
    echo -e "[!] $@" >&2
}

function is_mac() {
	local OS_NAME=$(uname | tr "[:upper:]" "[:lower:]")
	if [[ ${OS_NAME} =~ "darwin" ]]; then
		return 0
	fi

	return 1
}

function ctrl_c()
{
    exit 1
}
trap 'ctrl_c' INT

function on_err()
{
	error_msg "Error on line $1"
	
	exit 1
}
trap 'on_err ${LINENO}' ERR

function on_exit()
{
	if [[ ! -z ${EXAMPLE_PROJECTS+x} ]]; then
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
}
trap 'on_exit' EXIT


set -euox pipefail

MY_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ "$#" -eq 0 ]]; then
	error_msg "You must provide local path to gem_kit package"
    echo
    exit 1
fi

flutter doctor || ( error_msg "flutter doctor failed"; exit 1 )

GEM_KIT_PATH="${1}"

# Find paths that contain an app module
EXAMPLE_PROJECTS=$(find ${MY_DIR} -maxdepth 1 -type d -exec [ -d {}/plugins ] \; -print -prune)

for EXAMPLE_PATH in ${EXAMPLE_PROJECTS}; do
    cp -R "${GEM_KIT_PATH}" "${EXAMPLE_PATH}/plugins"

    pushd "${EXAMPLE_PATH}" &>/dev/null

	flutter pub get

    if is_mac; then
		(cd ios; pod install --repo-update; cd ..)
		flutter build ios --release --no-codesign

		(cd macos; pod install --repo-update; cd ..)
		flutter build macos --release
    fi

    flutter build apk --release

    flutter build web --release

    popd &>/dev/null
done

pushd "${MY_DIR}" &>/dev/null

if [ -d "WEB" ]; then
	rm -rf "WEB"
fi
mkdir WEB

if [ -d "APK" ]; then
	rm -rf "APK"
fi
mkdir APK

for EXAMPLE_PATH in ${EXAMPLE_PROJECTS}; do
	EXAMPLE_NAME="$(basename ${EXAMPLE_PATH})"
	mkdir -p "WEB/${EXAMPLE_NAME}"
	mkdir -p "APK/${EXAMPLE_NAME}"
    mv "${EXAMPLE_PATH}/build/web"/* "WEB/${EXAMPLE_NAME}"/
    mv "${EXAMPLE_PATH}/build/app/outputs/flutter-apk"/app-release.apk "APK/${EXAMPLE_NAME}/${EXAMPLE_NAME}_app-release.apk"
done

popd &>/dev/null
