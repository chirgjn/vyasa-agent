#!/usr/bin/env bash
set -euo pipefail
# Lint shell scripts with shellcheck.
# Usage: shellcheck-lint.sh [file ...]  (defaults to scripts/ and plugin/scripts/ if no args)
if [ $# -eq 0 ]; then
    # shellcheck disable=SC2046
    set -- $(find scripts/ plugin/scripts/ -name '*.sh' -type f)
fi
uv run shellcheck -x --source-path=scripts/setup "$@"
