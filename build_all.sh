#!/bin/bash

# Copyright (C) 2019-2024, Magic Lane B.V.
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
	error_msg "Error on line ${1}"
	
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

BUILD_ANDROID=1
BUILD_IOS=1
BUILD_WEB=1
GEM_KIT_PATH=""

MY_DIR="$(cd "$(dirname "$0")" && pwd)"

if is_mac; then
	if [ ! -f "$(brew --prefix)/opt/gnu-getopt/bin/getopt" ]; then
    	error_msg "This script requires 'brew install gnu-getopt && brew link --force gnu-getopt'"

    	exit 1
    fi

    PATH="$(brew --prefix)/opt/gnu-getopt/bin:$PATH"
fi

OPTIONS="android,ios,web,gem_kit:"
LONGOPTS="android,ios,web,gem_kit:"

PARSED_OPTIONS=$(getopt -n "$0" -o "" -l "${OPTIONS},${LONGOPTS}" -- "$@")
if [ $? -ne 0 ]; then
	error_msg "Parsing options failed"
    echo
    exit 1
fi

eval set -- "${PARSED_OPTIONS}"

while true; do
	case "${1}" in
		--android)
			BUILD_ANDROID=0
			shift
			;;
		--ios)
			BUILD_IOS=0
			shift
			;;
		--web)
			BUILD_WEB=0
			shift
			;;
		--gem_kit)
			GEM_KIT_PATH="${2}"
			shift 2
			;;
		--)
			shift
			break
			;;
		*)
			error_msg "Invalid option: ${1}"
			echo
			exit 1
			;;
	esac
done

if [ ! -d "${GEM_KIT_PATH}" ]; then
	error_msg "You must provide local path to gem_kit package"
    echo
    exit 1
fi

flutter doctor || ( error_msg "flutter doctor failed"; exit 1 )

# Find paths that contain an app module
EXAMPLE_PROJECTS=$(find ${MY_DIR} -maxdepth 1 -type d -exec [ -d {}/plugins ] \; -print -prune)

for EXAMPLE_PATH in ${EXAMPLE_PROJECTS}; do
    cp -R "${GEM_KIT_PATH}" "${EXAMPLE_PATH}/plugins"

    pushd "${EXAMPLE_PATH}" &>/dev/null

	flutter pub get

	if [ ${BUILD_IOS} -eq 0 ]; then
		if is_mac; then
			(cd ios; pod install --repo-update; cd ..)
			flutter build ios --release --no-codesign

			(cd macos; pod install --repo-update; cd ..)
			flutter build macos --release
		fi
	fi

	if [ ${BUILD_ANDROID} -eq 0 ]; then
		flutter build apk --release
	fi

	if [ ${BUILD_WEB} -eq 0 ]; then
		flutter build web --release
	fi

    popd &>/dev/null
done

pushd "${MY_DIR}" &>/dev/null

if [ -d "APK" ]; then
	rm -rf "APK"
fi
if [ ${BUILD_ANDROID} -eq 0 ]; then
	mkdir APK
fi

if [ -d "WEB" ]; then
	rm -rf "WEB"
fi
if [ ${BUILD_WEB} -eq 0 ]; then
	mkdir WEB
fi

for EXAMPLE_PATH in ${EXAMPLE_PROJECTS}; do
	EXAMPLE_NAME="$(basename ${EXAMPLE_PATH})"
	if [ ${BUILD_ANDROID} -eq 0 ]; then
		mkdir -p "APK/${EXAMPLE_NAME}"
		mv "${EXAMPLE_PATH}/build/app/outputs/flutter-apk"/app-release.apk "APK/${EXAMPLE_NAME}/${EXAMPLE_NAME}_app-release.apk"
	fi  
	if [ ${BUILD_WEB} -eq 0 ]; then
		mkdir -p "WEB/${EXAMPLE_NAME}"
		mv "${EXAMPLE_PATH}/build/web"/* "WEB/${EXAMPLE_NAME}"/
	fi
done

popd &>/dev/null
