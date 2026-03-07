#!/usr/bin/env bash
# Lookup tool: find occurrences of given words across all docs.
# Usage: find-word-contexts.sh <docs-dir> <word1> [word2 ...]
# Output: file:line_number:matching_line for each hit. Exit 0 always.
#
# Called on-demand by duplication-detect agent with words it finds interesting.

set -euo pipefail

DOCS_DIR="${1:?Usage: find-word-contexts.sh <docs-dir> <word1> [word2 ...]}"
shift
if [[ $# -eq 0 ]]; then
    exit 0
fi

# Build grep pattern from all words (case-insensitive, whole word)
pattern=$(printf '%s\n' "$@" | paste -sd '|' -)

grep -rniE --include="*.md" "\b($pattern)\b" "$DOCS_DIR" || true
