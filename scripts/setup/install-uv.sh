#!/usr/bin/env bash
# Install uv if not already present
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

echo "uv"

if command -v uv &>/dev/null; then
    ok "uv $(uv --version | awk '{print $2}') (already installed)"
    exit 0
fi

info "installing uv..."
if command -v brew &>/dev/null; then
    brew install uv
else
    TMPFILE=$(mktemp)
    curl -LsSf https://astral.sh/uv/install.sh -o "$TMPFILE"
    sh "$TMPFILE"
    rm -f "$TMPFILE"
    export PATH="$HOME/.local/bin:$PATH"
fi

if ! command -v uv &>/dev/null; then
    fail "uv was not found on PATH after install.
       If installed via the official script, try: export PATH=\"\$HOME/.local/bin:\$PATH\"
       Then verify with: uv --version"
fi

ok "uv $(uv --version | awk '{print $2}')"
