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
	PATH="$(brew --prefix)/opt/gnu-getopt/bin:${PATH}"
	export PATH

    if ! brew ls --versions gnu-sed > /dev/null; then
        error_msg "Missing gnu-sed. Run 'brew install gnu-sed && brew link --force gnu-sed'"
        exit 1
    fi
    PATH="$(brew --prefix)/opt/gnu-sed/libexec/gnubin:${PATH}"
    export PATH

    if ! brew ls --versions grep > /dev/null; then
        error_msg "Missing grep. Run 'brew install grep && brew link --force grep'"
        exit 1
    fi
    PATH="$(brew --prefix)/opt/grep/libexec/gnubin:${PATH}"
    export PATH

    if ! brew ls --versions coreutils > /dev/null; then
        error_msg "Missing coreutils. Run 'brew install coreutils && brew link --force coreutils'"
        exit 1
    fi
    PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:${PATH}"
    export PATH

    if ! brew ls --versions findutils > /dev/null; then
        error_msg "Missing findutils. Run 'brew install findutils && brew link --force findutils'"
        exit 1
    fi
    PATH="$(brew --prefix)/opt/findutils/libexec/gnubin:${PATH}"
	export PATH

    if ! brew ls --versions rename > /dev/null; then
        error_msg "Missing rename. Run 'brew install rename && brew link --force rename'"
        exit 1
    fi
    PATH="$(brew --prefix)/opt/rename/libexec/gnubin:${PATH}"
	export PATH
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
    printf '\n'
    exit 2
fi

flutter doctor || ( error_msg "flutter doctor failed"; exit 1 ) 

MY_DIR="$(cd "$(dirname "${0}")" && pwd)"

# Find paths that contain an app module
mapfile -t EXAMPLE_PROJECTS < <(find "${MY_DIR}/.." -maxdepth 2 -type d -exec [ -d "{}/plugins" ] \; -exec realpath {} \; 2>/dev/null)

function check_app_identifiers() {
	local RC=0

	for i in "${!EXAMPLE_PROJECTS[@]}"; do
		msg "Check '${EXAMPLE_PROJECTS[i]}' for app identifiers..."
		
		EXAMPLE_I="$(basename "${EXAMPLE_PROJECTS[i]}")"
		EXAMPLE_I_NO_UNDERSCORE=${EXAMPLE_I//_}
		if [[ "${EXAMPLE_I}" != "${EXAMPLE_I_NO_UNDERSCORE}" ]]; then
			if grep -irl --exclude "*.dart" --exclude "README.md" --exclude-dir "gem_kit" "${EXAMPLE_I_NO_UNDERSCORE}" "${EXAMPLE_PROJECTS[i]}"; then
				msg "Found wrong app identifier: '${EXAMPLE_I_NO_UNDERSCORE}' in '${EXAMPLE_I}'"
				RC=1
				find "${EXAMPLE_PROJECTS[i]}" -path "*/plugins/gem_kit" -prune -o \
					\( -type f -not \( -wholename "*/.git*" -or -name "*.dart" -or -name "README.md" \) \) -exec sed -i "s/${EXAMPLE_I_NO_UNDERSCORE}/${EXAMPLE_I}/gI" {} +
			fi
		fi
		find "${EXAMPLE_PROJECTS[i]}" -path "*/plugins/gem_kit" -prune -o \
			\( -type f -not \( -wholename "*/.git*" -or -name "*.dart" \) \) -exec sed -i "s/PRODUCT_BUNDLE_IDENTIFIER = com\.example\./PRODUCT_BUNDLE_IDENTIFIER = com.magiclane.gem_kit.examples./g" {} +
		find "${EXAMPLE_PROJECTS[i]}" -path "*/plugins/gem_kit" -prune -o \
			\( -type f -not \( -wholename "*/.git*" -or -name "*.dart" \) \) -exec sed -i "s/PRODUCT_COPYRIGHT = Copyright © 2024 com\.example\. All rights reserved./PRODUCT_COPYRIGHT = 1995-2025 Magic Lane International B.V. <info@magiclane.com>/g" {} +
	done

	return ${RC}
}	
		
function check_mismatch() {
	local RC=0

	for i in "${!EXAMPLE_PROJECTS[@]}"; do
		msg "Check '${EXAMPLE_PROJECTS[i]}' for mismatches..."

		EXAMPLE_I="$(basename "${EXAMPLE_PROJECTS[i]}")"
		for j in "${!EXAMPLE_PROJECTS[@]}"; do
			if [[ "${i}" == "${j}" ]]; then
				continue
			fi

			EXAMPLE_J="$(basename "${EXAMPLE_PROJECTS[j]}")"
			if grep -irl --exclude "*.dart" --exclude "*.style" --exclude-dir "gem_kit" "${EXAMPLE_J}" "${EXAMPLE_PROJECTS[i]}" > /dev/null 2>&1; then
				if [[ "${EXAMPLE_PROJECTS[i]}" != *"${EXAMPLE_J}"* ]]; then
					error_msg "(!)Found mismatch string: '${EXAMPLE_J}' in '${EXAMPLE_I}'"
					RC=1
					find "${EXAMPLE_PROJECTS[i]}" -path "*/plugins/gem_kit" -prune -o \
						\( -type f -not \( -wholename "*/.git*" -or -name "*.dart" -or -name "*.style" \) \) -exec sed -i "s/${EXAMPLE_J}/${EXAMPLE_I}/g" {} +
				fi
			fi

			EXAMPLE_I_NO_UNDERSCORE=${EXAMPLE_I//_}
			EXAMPLE_J_NO_UNDERSCORE=${EXAMPLE_J//_}
			if grep -irl --exclude "*.dart" --exclude "*.style" --exclude-dir "gem_kit" "${EXAMPLE_J_NO_UNDERSCORE}" "${EXAMPLE_PROJECTS[i]}" > /dev/null 2>&1; then
				if [[ "${EXAMPLE_I_NO_UNDERSCORE}" != *"${EXAMPLE_J_NO_UNDERSCORE}"* ]]; then
					error_msg "(!!)Found mismatch string: '${EXAMPLE_J_NO_UNDERSCORE}' in '${EXAMPLE_I}'"
					RC=1
					find "${EXAMPLE_PROJECTS[i]}" -path "*/plugins/gem_kit" -prune -o \
						\( -type f -not \( -wholename "*/.git*" -or -name "*.dart" -or -name "*.style" \) \) -exec sed -i "s/${EXAMPLE_J_NO_UNDERSCORE}/${EXAMPLE_I//_}/gI" {} +
				fi
			fi

			if [[ "${EXAMPLE_I}" != *"${EXAMPLE_J}"* ]]; then
				mapfile -t MISMATCH_DIRS < <(find "${EXAMPLE_PROJECTS[i]}" -path "*/plugins/gem_kit" -prune -o \( -type d -not -wholename "*/.git*" -name "${EXAMPLE_J}" \) -print 2>/dev/null)
				if [ ${#MISMATCH_DIRS[@]} -gt 0 ]; then
					error_msg "Found mismatch folder: '${EXAMPLE_J}' in '${EXAMPLE_I}'"
					RC=1
					find "${EXAMPLE_PROJECTS[i]}" -path "*/plugins/gem_kit" -prune -o \
						\( -type d -not \( -wholename "*/.git*" \) -name "${EXAMPLE_J}" \) -execdir rename -v "s/${EXAMPLE_J}/${EXAMPLE_I}/" '{}' +
				fi
			fi
		done
	done

	return ${RC}
}

function check_secrets() {
	local RC=0

	for i in "${!EXAMPLE_PROJECTS[@]}"; do
		msg "Check '${EXAMPLE_PROJECTS[i]}' for secrets..."

		MAIN_FILES=()
		mapfile -t MAIN_FILES < <(find "${EXAMPLE_PROJECTS[i]}" -path "*/plugins/gem_kit" -prune -o \( -type f -name "main.dart" \) -print 2>/dev/null)
		if ((${#MAIN_FILES[@]} == 0)); then
			continue
		fi

		for file in "${MAIN_FILES[@]}"; do
			if ! grep -q "projectApiToken.*fromEnvironment.*GEM_TOKEN" "${file}"; then
				error_msg "main.dart in ${EXAMPLE_PROJECTS[i]} may contain secrets (projectApiToken)"
				RC=1
			fi
			if ! grep -Eq "appAuthorization\s*:\s*projectApiToken" "${file}"; then
				error_msg "main.dart in ${EXAMPLE_PROJECTS[i]} may contain secrets (appAuthorization)"
				RC=1
			fi
		done
	done

	if [[ ${RC} -eq 1 ]]; then
		error_msg "Secrets found. Please check"
	fi

	return ${RC}
}

function check_license() {
	local RC=0

	local SOURCES_WITH_MISSING_SPDX_IDENTIFIERS=()
	local SOURCES=()

	local FILE_EXT=(
		"*.h"
		"*.dart"
		"*.swift"
		"*.kt"
		"*.sh"
	)

	local FILE_EXCEPTIONS="GeneratedPluginRegistrant.*|\
AppDelegate.swift|\
Runner-Bridging-Header.h|\
RunnerTests.swift|\
my_application.h|\
generated_plugin_registrant.h"

	for i in "${!EXAMPLE_PROJECTS[@]}"; do
		msg "Check '${EXAMPLE_PROJECTS[i]}' for license..."

		SOURCES_WITH_MISSING_SPDX_IDENTIFIERS=()
		SOURCES=()
		
		pushd "${EXAMPLE_PROJECTS[i]}" > /dev/null || continue

		mapfile -t SOURCES < <(git ls-files "${FILE_EXT[@]}")

		while IFS= read -r file; do
			if ! grep -qE "SPDX-License-Identifier:.+" "${file}"; then
				SOURCES_WITH_MISSING_SPDX_IDENTIFIERS+=("${file}")
			fi
		done < <(printf '%s\n' "${SOURCES[@]}" | sort -u | grep -vE "${FILE_EXCEPTIONS}")

		if ((${#SOURCES_WITH_MISSING_SPDX_IDENTIFIERS[@]} > 0)); then
			error_msg "Following files are missing SPDX-license header in '${EXAMPLE_PROJECTS[i]}':"
			printf '    @ %s\n' "${SOURCES_WITH_MISSING_SPDX_IDENTIFIERS[@]}"
			printf '\n'
			RC=1
		fi

		popd > /dev/null || true
	done

	if [[ ${RC} -eq 1 ]]; then
		error_msg "Missing license identifiers. Please check"
	fi

	return ${RC}
}

RC=0

echo -e "\n"
msg "Check application identifiers..."
check_app_identifiers || RC=1
echo -e "\n"
msg "Check folder/file mismatches..."
check_mismatch || RC=1
echo -e "\n"
msg "Check secrets..."
check_secrets || RC=1
echo -e "\n"
msg "Check licenses..."
check_license || RC=1

exit ${RC}
