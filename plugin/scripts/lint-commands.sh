#!/usr/bin/env bash
# Checks that commands listed in AGENTS.md commands section exist.
# Usage: lint-commands.sh <agents-md-path>
# Emits REMAINING lines for missing commands. No auto-fix. Exit 0 always.

set -euo pipefail

AGENTS_FILE="${1:?Usage: lint-commands.sh <agents-md-path>}"
PROJECT_ROOT="$(dirname "$AGENTS_FILE")"

# Common system binaries to skip checking
SYSTEM_BINS="^(git|pnpm|npm|yarn|cargo|go|python|python3|uv|make|docker|kubectl|brew)$"

# Extract lines from inside ```bash ... ``` blocks in AGENTS.md
# Then grab the first token (the command itself)
commands=()
while IFS= read -r cmd; do
    commands+=("$cmd")
done < <(awk '
    /^```bash/ { in_block=1; next }
    /^```/     { in_block=0; next }
    in_block   { print }
' "$AGENTS_FILE" | grep -oE '^[a-zA-Z0-9_./-]+' | sort -u || true)

for cmd in "${commands[@]+"${commands[@]}"}"; do
    # Skip system binaries
    if echo "$cmd" | grep -qE "$SYSTEM_BINS"; then
        continue
    fi
    # Check if it's a local path (contains /) — verify file exists
    if [[ "$cmd" == */* ]]; then
        if [[ ! -f "$PROJECT_ROOT/$cmd" ]]; then
            echo "REMAINING: error — commands: \`$cmd\` listed in AGENTS.md but does not exist"
        fi
    fi
done
