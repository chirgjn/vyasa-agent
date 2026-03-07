#!/usr/bin/env bash
# Verify yamllint, yamlfix, and actionlint are available via uv run (installed by install-deps.sh via uv sync)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

echo "yamllint + yamlfix + actionlint"

if uv run yamllint --version &>/dev/null && uv run yamlfix --version &>/dev/null && uv run actionlint -version &>/dev/null; then
    ok "yamllint $(uv run yamllint --version), yamlfix $(uv run yamlfix --version | sed -n 's/.*yamlfix: *//p'), actionlint $(uv run actionlint -version | head -1) (already installed)"
    exit 0
fi

info "installing via uv sync..."
uv sync

if ! uv run yamllint --version &>/dev/null; then
    fail "yamllint was not found after uv sync.
       Ensure yamllint is listed in pyproject.toml dev dependencies."
fi
if ! uv run yamlfix --version &>/dev/null; then
    fail "yamlfix was not found after uv sync.
       Ensure yamlfix is listed in pyproject.toml dev dependencies."
fi
if ! uv run actionlint -version &>/dev/null; then
    fail "actionlint was not found after uv sync.
       Ensure actionlint-py is listed in pyproject.toml dev dependencies."
fi

ok "yamllint $(uv run yamllint --version), yamlfix $(uv run yamlfix --version | sed -n 's/.*yamlfix: *//p'), actionlint $(uv run actionlint -version | head -1)"
