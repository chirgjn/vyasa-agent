#!/usr/bin/env bash
set -euo pipefail
# Format TOML files with taplo.
# Usage: taplo-fmt.sh [--check] [file ...]  (defaults to all *.toml in the project if no args)
#   --check  Dry-run: report unformatted files without modifying them (used in CI)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="${REPO_ROOT}/.local/bin:${PATH}"

CHECK=""
if [ "${1-}" = "--check" ]; then
    CHECK="--check"
    shift
fi

if [ $# -eq 0 ]; then
    # shellcheck disable=SC2046
    set -- $(find . -name '*.toml' -not -path './.venv/*' -not -path './.git/*')
fi
# shellcheck disable=SC2086
taplo fmt $CHECK "$@"
