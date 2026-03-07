#!/usr/bin/env bash
# Checks all backtick-fenced file paths in a doc for broken references.
# Usage: lint-refs.sh <doc-path>
# Emits REMAINING lines for broken refs. No auto-fix. Exit 0 always.
#
# Validates any backtick-fenced path that looks like a relative file reference.
# Resolution is against git root (or doc's directory if not in a git repo).

set -euo pipefail

DOC_FILE="${1:?Usage: lint-refs.sh <doc-path>}"
PROJECT_ROOT="$(git -C "$(dirname "$DOC_FILE")" rev-parse --show-toplevel 2>/dev/null \
    || dirname "$DOC_FILE")"

# Extract all backtick-fenced paths that look like relative file references.
# Matches paths with at least one directory component: `some-dir/file.ext`
# Does not require a specific set of known directory names.
# shellcheck disable=SC2016
REF_PATTERN='`[a-zA-Z0-9_./-]+/[^` ]+\.[a-zA-Z0-9]+`'
refs=()
while IFS= read -r ref; do
    refs+=("$ref")
done < <(grep -oE "$REF_PATTERN" "$DOC_FILE" \
    | tr -d '`' | sort -u || true)

for ref in "${refs[@]+"${refs[@]}"}"; do
    if [[ ! -f "$PROJECT_ROOT/$ref" ]]; then
        echo "REMAINING: error — broken reference \`$ref\` in $(basename "$DOC_FILE")"
    fi
done
