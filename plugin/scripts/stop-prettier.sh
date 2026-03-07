#!/usr/bin/env bash
# Consumer Stop hook: run prettier once on all markdown files touched during the turn.
# Reads paths from ${CLAUDE_PROJECT_DIR}/.claude/vyasa-md-changed (written by post-write-lint.sh),
# runs prettier on them in a single batch, then clears the flag file.
# Called by plugin/hooks/hooks.json Stop hook.
set -euo pipefail

FLAG="${CLAUDE_PROJECT_DIR}/.claude/vyasa-md-changed"

if [ ! -f "$FLAG" ]; then
    exit 0
fi

mapfile -t FILES < "$FLAG"
rm -f "$FLAG"

# Filter to files that still exist
EXISTING=()
for f in "${FILES[@]}"; do
    [[ -f "$f" ]] && EXISTING+=("$f")
done

if [ ${#EXISTING[@]} -eq 0 ]; then
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRETTIER="${SCRIPT_DIR}/../node_modules/.bin/prettier"

if [[ ! -x "$PRETTIER" ]]; then
    exit 0
fi

"$PRETTIER" --write "${EXISTING[@]}" || true
"$PRETTIER" --check "${EXISTING[@]}"
