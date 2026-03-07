#!/usr/bin/env bash
set -euo pipefail
# Type-check Python files with basedpyright.
# Usage: basedpyright-lint.sh  (always checks the whole project — basedpyright ignores filenames)
uv run basedpyright --level error
