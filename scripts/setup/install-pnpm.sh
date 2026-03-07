#!/usr/bin/env bash
# Install pnpm if not already present.
# macOS:  brew → official installer
# Linux:  apt-get → dnf → yum → official installer
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

echo "pnpm"

if command -v pnpm &>/dev/null; then
    ok "pnpm $(pnpm --version) (already installed)"
    exit 0
fi

USER_SHELL=$(basename "${SHELL:-bash}")
case "$USER_SHELL" in
    zsh)  PROFILE="$HOME/.zshrc" ;;
    bash) PROFILE="${BASH_ENV:-${HOME}/.bashrc}" ;;
    fish) PROFILE="$HOME/.config/fish/config.fish" ;;
    *)    PROFILE="$HOME/.profile" ;;
esac

source_profile() {
    if [[ "$USER_SHELL" == "fish" ]]; then
        warn "fish shell detected — cannot source profile from bash."
        warn "Open a new terminal and re-run this script."
        return 0
    fi
    if [[ -f "$PROFILE" ]]; then
        # shellcheck disable=SC1090
        source "$PROFILE"
    else
        warn "Profile $PROFILE not found — pnpm may not be on PATH yet."
        warn "Try opening a new terminal and re-running this script."
    fi
}

pnpm_setup() {
    # pnpm setup creates PNPM_HOME, adds it to PATH in the shell profile,
    # and copies the pnpm executable there — the canonical way to configure pnpm.
    pnpm setup
    source_profile
}

if [[ "$(uname)" == "Darwin" ]]; then
    if command -v brew &>/dev/null; then
        info "installing pnpm via brew..."
        brew install pnpm
        if command -v pnpm &>/dev/null; then
            pnpm_setup
            ok "pnpm $(pnpm --version)"
            exit 0
        fi
    fi
else
    if command -v apt-get &>/dev/null; then
        info "installing pnpm via apt-get..."
        sudo apt-get install -y pnpm >/dev/null 2>&1
        if command -v pnpm &>/dev/null; then
            pnpm_setup
            ok "pnpm $(pnpm --version)"
            exit 0
        fi
    elif command -v dnf &>/dev/null; then
        info "installing pnpm via dnf..."
        sudo dnf install -y pnpm >/dev/null 2>&1
        if command -v pnpm &>/dev/null; then
            pnpm_setup
            ok "pnpm $(pnpm --version)"
            exit 0
        fi
    elif command -v yum &>/dev/null; then
        info "installing pnpm via yum..."
        sudo yum install -y pnpm >/dev/null 2>&1
        if command -v pnpm &>/dev/null; then
            pnpm_setup
            ok "pnpm $(pnpm --version)"
            exit 0
        fi
    fi
fi

# Fall back to official installer
info "installing pnpm via official installer (profile: $PROFILE)..."
TMPFILE=$(mktemp)
curl -fsSL https://get.pnpm.io/install.sh -o "$TMPFILE"
SHELL="$(command -v "$USER_SHELL")" sh "$TMPFILE"
rm -f "$TMPFILE"

# The official installer already runs pnpm setup internally;
# source the updated profile to pick up PNPM_HOME in this session.
source_profile

if ! command -v pnpm &>/dev/null; then
    fail "pnpm not found on PATH after install.
       The install likely succeeded but PATH is not updated yet.
       Open a new terminal and verify with: pnpm --version
       If still missing, check that $PROFILE contains the pnpm PATH line."
fi

ok "pnpm $(pnpm --version)"
