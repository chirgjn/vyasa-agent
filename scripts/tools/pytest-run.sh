#!/usr/bin/env bash
set -euo pipefail
# Run pytest.
# Usage: pytest-run.sh [args ...]  (defaults to tests/ if no args)
if [ $# -eq 0 ]; then
    uv run pytest tests/
else
    uv run pytest "$@"
fi
