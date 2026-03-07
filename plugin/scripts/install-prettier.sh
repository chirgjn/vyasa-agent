#!/usr/bin/env bash
# Install prettier into the plugin directory so runtime scripts can use it
# without requiring a global install or polluting the consumer project.
#
# Usage: install-prettier.sh <plugin-root>
#   plugin-root: path to the installed plugin directory (CLAUDE_PLUGIN_ROOT)
#
# Install priority:
#   macOS:  pnpm → npm → brew install prettier (symlinked) → official pnpm installer → pnpm
#   Linux:  pnpm → npm → apt-get/dnf/yum install pnpm → official pnpm installer → pnpm
#
# After install, prettier is available at:
#   <plugin-root>/node_modules/.bin/prettier
set -euo pipefail

PLUGIN_ROOT="${1:-}"
if [[ -z "$PLUGIN_ROOT" ]]; then
    echo "error: plugin root path required" >&2
    echo "Usage: install-prettier.sh <plugin-root>" >&2
    exit 1
fi

PRETTIER_BIN="${PLUGIN_ROOT}/node_modules/.bin/prettier"

if [[ -x "$PRETTIER_BIN" ]]; then
    echo "OK: prettier $("$PRETTIER_BIN" --version) (already installed at ${PLUGIN_ROOT})"
    exit 0
fi

# --- Helpers ---

install_with_pnpm() {
    command -v pnpm &>/dev/null || return 1
    echo "INSTALLING: prettier into ${PLUGIN_ROOT} via pnpm..."
    pnpm install --prefix "$PLUGIN_ROOT" --silent
}

install_with_npm() {
    command -v npm &>/dev/null || return 1
    echo "INSTALLING: prettier into ${PLUGIN_ROOT} via npm..."
    npm install --prefix "$PLUGIN_ROOT" --silent
}

# Run pnpm setup (idempotent) to configure PNPM_HOME and update PATH in the shell
# profile, then source the profile so pnpm is available in the current session.
source_profile() {
    local user_shell profile
    user_shell=$(basename "${SHELL:-bash}")
    pnpm setup
    case "$user_shell" in
        fish) return 0 ;;  # fish syntax incompatible with bash source
        zsh)  profile="$HOME/.zshrc" ;;
        bash) profile="${BASH_ENV:-${HOME}/.bashrc}" ;;
        *)    profile="$HOME/.profile" ;;
    esac
    # shellcheck disable=SC1090
    [[ -f "$profile" ]] && source "$profile" || true
}

# --- macOS fallback: brew install prettier, symlink into plugin dir ---

install_via_brew() {
    command -v brew &>/dev/null || return 1
    echo "INSTALLING: prettier via brew..."
    brew install prettier >/dev/null 2>&1 || return 1
    local brew_bin
    brew_bin="$(command -v prettier 2>/dev/null || true)"
    [[ -x "$brew_bin" ]] || return 1
    mkdir -p "${PLUGIN_ROOT}/node_modules/.bin"
    ln -sf "$brew_bin" "$PRETTIER_BIN"
}

# --- pnpm via official curl installer (macOS and Linux) ---

install_pnpm_via_curl() {
    command -v curl &>/dev/null || { echo "FAILED: curl required to install pnpm" >&2; return 1; }
    echo "INSTALLING: pnpm via official installer..."
    local user_shell tmpfile
    user_shell=$(basename "${SHELL:-bash}")
    tmpfile=$(mktemp)
    curl -fsSL https://get.pnpm.io/install.sh -o "$tmpfile"
    SHELL="$(command -v "$user_shell")" sh "$tmpfile"
    rm -f "$tmpfile"
    source_profile
    command -v pnpm &>/dev/null || { echo "FAILED: pnpm not on PATH after install — open a new terminal and re-run /vyasa:setup" >&2; return 1; }
}

# --- Linux fallback: install pnpm via system package manager or curl, then use it ---

install_pnpm_linux() {
    if command -v apt-get &>/dev/null; then
        echo "INSTALLING: pnpm via apt-get..."
        sudo apt-get install -y pnpm >/dev/null 2>&1 && source_profile
        command -v pnpm &>/dev/null && return 0
    fi
    if command -v dnf &>/dev/null; then
        echo "INSTALLING: pnpm via dnf..."
        sudo dnf install -y pnpm >/dev/null 2>&1 && source_profile
        command -v pnpm &>/dev/null && return 0
    fi
    if command -v yum &>/dev/null; then
        echo "INSTALLING: pnpm via yum..."
        sudo yum install -y pnpm >/dev/null 2>&1 && source_profile
        command -v pnpm &>/dev/null && return 0
    fi
    install_pnpm_via_curl
}

# --- Main ---

# Source the user's shell profile so pnpm is on PATH even if just installed
source_profile

if install_with_pnpm; then
    true
elif install_with_npm; then
    true
elif [[ "$(uname)" == "Darwin" ]]; then
    if ! install_via_brew; then
        # brew missing or failed — install pnpm via official installer then use it
        # shellcheck disable=SC2015
        install_pnpm_via_curl && install_with_pnpm || { echo "FAILED: could not install prettier — all methods failed" >&2; exit 1; }
    fi
else
    # shellcheck disable=SC2015
    install_pnpm_linux && install_with_pnpm || { echo "FAILED: could not install pnpm or prettier" >&2; echo "  Install pnpm (https://pnpm.io/installation) and re-run /vyasa:setup" >&2; exit 1; }
fi

if [[ ! -x "$PRETTIER_BIN" ]]; then
    echo "FAILED: prettier not found after install at ${PRETTIER_BIN}" >&2
    exit 1
fi

echo "OK: prettier $("$PRETTIER_BIN" --version) installed at ${PLUGIN_ROOT}"
