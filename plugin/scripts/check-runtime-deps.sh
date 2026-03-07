#!/usr/bin/env bash
# Checks runtime dependencies required by vyasa plugin scripts.
# Attempts to install missing deps via the available package manager
# (apt-get, dnf/yum on Linux; brew on macOS). If none are available,
# prints the official install URL for each missing tool.
# prettier is installed into the plugin directory via pnpm (installed if needed).
# Exit 0 if all deps present or successfully installed. Exit 1 if any missing.
#
# Usage: check-runtime-deps.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEPS="git jq"

# Official install URLs shown when no package manager is available
# shellcheck disable=SC2034
git_url="https://git-scm.com/downloads"
# shellcheck disable=SC2034
jq_url="https://jqlang.org/download/"

# openssl is used for run-id generation; /dev/urandom is the fallback.
# Check separately — missing openssl is a warning, not a hard failure.
if ! command -v openssl >/dev/null 2>&1; then
    if [[ -r /dev/urandom ]]; then
        echo "OK: openssl not found — using /dev/urandom fallback for run-id generation"
    else
        echo "WARNING: openssl not found and /dev/urandom not readable — run-id generation will fail"
        echo "  Install openssl via your package manager or homebrew"
    fi
else
    echo "OK: openssl $(openssl version 2>/dev/null | head -1)"
fi

ok=true

check_dep() {
    local dep="$1"
    if command -v "$dep" >/dev/null 2>&1; then
        echo "OK: $dep $(command -v "$dep")"
        return 0
    fi
    return 1
}

install_dep() {
    local dep="$1"
    if command -v apt-get >/dev/null 2>&1; then
        echo "INSTALLING: $dep via apt-get..."
        if sudo apt-get install -y "$dep" >/dev/null 2>&1; then
            echo "OK: $dep installed successfully"
            return 0
        else
            echo "FAILED: could not install $dep via apt-get"
        fi
    fi
    if command -v dnf >/dev/null 2>&1; then
        echo "INSTALLING: $dep via dnf..."
        if sudo dnf install -y "$dep" >/dev/null 2>&1; then
            echo "OK: $dep installed successfully"
            return 0
        else
            echo "FAILED: could not install $dep via dnf"
        fi
    elif command -v yum >/dev/null 2>&1; then
        echo "INSTALLING: $dep via yum..."
        if sudo yum install -y "$dep" >/dev/null 2>&1; then
            echo "OK: $dep installed successfully"
            return 0
        else
            echo "FAILED: could not install $dep via yum"
        fi
    fi
    if [[ "$(uname)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
        echo "INSTALLING: $dep via brew..."
        if brew install "$dep" >/dev/null 2>&1; then
            echo "OK: $dep installed successfully"
            return 0
        else
            echo "FAILED: could not install $dep via brew"
        fi
    fi
    return 1
}

for dep in $DEPS; do
    if check_dep "$dep"; then
        continue
    fi

    echo "MISSING: $dep"

    if install_dep "$dep"; then
        continue
    fi

    # No package manager worked — show official URL
    url_var="${dep}_url"
    # shellcheck disable=SC2016
    url="${!url_var:-}"
    if [[ -n "$url" ]]; then
        echo "  Install manually: $url"
    fi
    ok=false
done

# prettier — installed into the plugin directory
PRETTIER_BIN="${SCRIPT_DIR}/../node_modules/.bin/prettier"
if [[ -x "$PRETTIER_BIN" ]]; then
    echo "OK: prettier $("$PRETTIER_BIN" --version) (${PRETTIER_BIN})"
else
    echo "MISSING: prettier"
    if "${SCRIPT_DIR}/install-prettier.sh" "${SCRIPT_DIR}/.."; then
        PRETTIER_BIN="${SCRIPT_DIR}/../node_modules/.bin/prettier"
    else
        echo "  Install manually: ${SCRIPT_DIR}/install-prettier.sh ${SCRIPT_DIR}/.."
        ok=false
    fi
fi

echo ""
if $ok; then
    echo "All vyasa runtime dependencies are present."
    exit 0
else
    echo "Some dependencies are missing. Install them and re-run /vyasa:setup"
    exit 1
fi
