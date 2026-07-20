#!/usr/bin/env bash
# vim:ts=4:sts=4:sw=4:et

# SPDX-FileCopyrightText: 2026 Magic Lane International B.V. <info@magiclane.com>
# SPDX-License-Identifier: Apache-2.0
#
# Contact Magic Lane at <info@magiclane.com> for SDK licensing options.
#
# Serves this folder over HTTP and opens the example gallery in a dedicated,
# throwaway Chrome instance with web security disabled. This is needed because
# the web SDK fetches its runtime (WASM/JS) cross-origin from
# developer.magiclane.com; until that host sends CORS headers, a normal browser
# blocks it. Runs in the foreground; Ctrl+C stops it.

set -eEuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

if ! command -v npx >/dev/null 2>&1; then
    echo "Node.js is required to run the local server." >&2
    echo "Install it from https://nodejs.org and run this again." >&2
    exit 1
fi

# Locate a Chrome/Chromium binary (macOS app bundle or Linux/Debian/Ubuntu paths).
CHROME=""
for CANDIDATE in \
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "/Applications/Chromium.app/Contents/MacOS/Chromium" \
    "/usr/bin/google-chrome-stable" \
    "/usr/bin/google-chrome" \
    "/usr/bin/chromium-browser" \
    "/usr/bin/chromium" \
    "/snap/bin/chromium"; do
    if [[ -x "${CANDIDATE}" ]]; then CHROME="${CANDIDATE}"; break; fi
done
if [[ -z "${CHROME}" ]]; then
    for CANDIDATE in google-chrome-stable google-chrome chromium chromium-browser; do
        if command -v "${CANDIDATE}" >/dev/null 2>&1; then CHROME="${CANDIDATE}"; break; fi
    done
fi

# Open the gallery: prefer a dedicated web-security-disabled Chrome; otherwise
# fall back to the default browser (map tiles may fail to load without CORS).
open_gallery()
{
    local url="${1}"
    if [[ -n "${CHROME}" ]]; then
        local profile
        profile="$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/ml-web-gallery-profile.$$")"
        echo "Opening ${url} in a dedicated Chrome (web security disabled, throwaway profile)."
        echo "Dev use only - do not browse other sites in this window."
        "${CHROME}" \
            --user-data-dir="${profile}" \
            --disable-web-security \
            --no-first-run \
            --no-default-browser-check \
            --new-window "${url}" >/dev/null 2>&1 &
    else
        echo "WARNING: Chrome/Chromium not found. Opening your default browser;"
        echo "         examples may fail to load until developer.magiclane.com sends CORS headers."
        if command -v xdg-open >/dev/null 2>&1; then
            xdg-open "${url}" >/dev/null 2>&1 || true
        elif command -v open >/dev/null 2>&1; then
            open "${url}" >/dev/null 2>&1 || true
        fi
    fi
}

echo "Starting a local server for the Flutter Maps SDK web examples..."
echo "Press Ctrl+C to stop."
echo

# `serve` sets correct MIME types (incl. .wasm) unlike `python3 -m http.server`.
# --yes skips the npx install prompt; no --single (would break /<example>/ routing).
OPENED=""
npx --yes serve@14 . --no-clipboard 2>&1 | while IFS= read -r LINE; do
    printf '%s\n' "${LINE}"
    if [[ -z "${OPENED}" && "${LINE}" =~ (http://localhost:[0-9]+) ]]; then
        open_gallery "${BASH_REMATCH[1]}"
        OPENED=1
    fi
done
