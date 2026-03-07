#!/usr/bin/env bash
# Format markdown with prettier. Auto-fixes locally; check-only in CI.
# Usage: prettier-fix.sh [--check] [file ...]
#   --check  Report unformatted files without modifying them (used in CI)
#
# With no file arguments, formats the docs directory discovered from layout.md,
# plus any .md files at the project root. Fails fast if layout.md is missing.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CHECK=0
if [ "${1-}" = "--check" ]; then
    CHECK=1
    shift
fi

if [ $# -eq 0 ]; then
    DOCS_DIR="$("$REPO_ROOT/plugin/scripts/find-docs-dir.sh" "$(pwd)")" || {
        echo "error: could not resolve docs directory. Run /vyasa:setup first." >&2
        exit 1
    }
    TARGETS=("$DOCS_DIR/**/*.md" "AGENTS.md" "README.md")
else
    TARGETS=("$@")
fi

cd "$REPO_ROOT" || exit 1
if [ "$CHECK" -eq 1 ]; then
    pnpm exec prettier --check "${TARGETS[@]}"
else
    pnpm exec prettier --write "${TARGETS[@]}" || true
    pnpm exec prettier --check "${TARGETS[@]}"
fi
