#!/usr/bin/env bash
# Install prettier as a project dev dependency via pnpm install (repo root)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

echo "prettier"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

PRETTIER_BIN="$ROOT/node_modules/.bin/prettier"

if [[ -x "$PRETTIER_BIN" ]]; then
    ok "prettier $("$PRETTIER_BIN" --version) (already installed)"
    exit 0
fi

# Ensure PNPM_HOME is configured and on PATH (idempotent — safe to call if already set up)
pnpm setup
USER_SHELL=$(basename "${SHELL:-bash}")
if [[ "$USER_SHELL" != "fish" ]]; then
    case "$USER_SHELL" in
        zsh)  PROFILE="$HOME/.zshrc" ;;
        bash) PROFILE="${BASH_ENV:-${HOME}/.bashrc}" ;;
        *)    PROFILE="$HOME/.profile" ;;
    esac
    if [[ -f "$PROFILE" ]]; then
        # shellcheck disable=SC1090
        source "$PROFILE"
    fi
fi

if ! command -v pnpm &>/dev/null; then
    fail "pnpm not found — run scripts/setup/install-pnpm.sh first"
fi

info "installing prettier via pnpm install (repo root)..."
pnpm install --dir "$ROOT"

if [[ ! -x "$PRETTIER_BIN" ]]; then
    fail "prettier not found at $PRETTIER_BIN after install.
       Ensure package.json exists at the repo root and re-run this script."
fi

ok "prettier $("$PRETTIER_BIN" --version)"
