#!/usr/bin/env bash
# Install playwright-cli globally via pnpm
# Used for mermaid diagram verification (see docs/mermaid-guidelines.md)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

echo "playwright-cli"

if command -v playwright-cli &>/dev/null; then
    ok "playwright-cli $(playwright-cli --version 2>/dev/null || echo 'found') (already installed)"
    exit 0
fi

if ! command -v pnpm &>/dev/null; then
    fail "pnpm not found — run scripts/setup/install-pnpm.sh first"
fi

info "installing playwright-cli via pnpm..."
pnpm add -g playwright-cli
ok "playwright-cli installed"
