#!/usr/bin/env bash
set -euo pipefail
# Lint GitHub Actions workflow files with actionlint.
# Usage: actionlint-lint.sh [file ...]  (defaults to all workflows in .github/workflows/)
if [ $# -eq 0 ]; then
    uv run actionlint
else
    uv run actionlint "$@"
fi
