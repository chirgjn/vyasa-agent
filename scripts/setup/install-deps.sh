#!/usr/bin/env bash
# Install project dependencies via uv sync
# Must be run from the project root (where pyproject.toml lives)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

echo "Project dependencies"

if ! command -v uv &>/dev/null; then
    fail "uv not found — run scripts/setup/install-uv.sh first"
fi

if [[ ! -f pyproject.toml ]]; then
    fail "pyproject.toml not found.
       Run this script from the project root directory.
       Current directory: $(pwd)"
fi

info "running uv sync..."
uv sync
ok "dependencies installed"

# --- Install git hooks via prek ---
info "installing git hooks via prek..."
uv run prek install -t pre-commit -t post-merge -t post-checkout
ok "git hooks installed (prek)"
