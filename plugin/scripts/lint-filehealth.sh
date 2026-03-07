#!/usr/bin/env bash
# Checks file health: line count, filename conventions, index-only detection.
# Usage: lint-filehealth.sh <doc-path>
# Emits REMAINING lines. No auto-fix. Exit 0 always.

set -euo pipefail

DOC_FILE="${1:?Usage: lint-filehealth.sh <doc-path>}"
filename="$(basename "$DOC_FILE")"

# Line count (non-blank lines)
nonblank=$(grep -c '.' "$DOC_FILE" || true)
if [[ "$nonblank" -lt 15 ]]; then
    echo "REMAINING: warning — thin file: $filename has $nonblank non-blank lines (<15, merge candidate)"
elif [[ "$nonblank" -gt 200 ]]; then
    echo "REMAINING: warning — bloated file: $filename has $nonblank non-blank lines (>200, split candidate)"
fi

# Filename: must be lowercase, hyphen-separated, no version numbers
if echo "$filename" | grep -qE '[A-Z]|_|v[0-9]+\.'; then
    echo "REMAINING: info — filename: $filename should be lowercase, hyphen-separated, no version numbers"
fi

# Index-only: >80% of non-blank lines are markdown links
total_lines="$nonblank"
link_lines=$(grep -cE '^\s*[-*] \[|^\| .* \[|\[.+\]\(.+\)' "$DOC_FILE" || true)
if [[ "$total_lines" -gt 5 ]]; then
    # Use awk for integer division
    ratio=$(awk -v l="$link_lines" -v t="$total_lines" 'BEGIN { printf "%d", (l/t)*100 }')
    if [[ "$ratio" -gt 80 ]]; then
        echo "REMAINING: warning — index-only: $filename is ${ratio}% links (>80%, consider deleting — routing table already provides navigation)"
    fi
fi
