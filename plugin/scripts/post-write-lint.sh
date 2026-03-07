#!/usr/bin/env bash
# Consumer hook: flag markdown files for deferred formatting after Write or Edit.
# Prettier runs once at turn end via stop-prettier.sh (Stop hook).
# Called by plugin/hooks/hooks.json PostToolUse hook.
set -euo pipefail

FILE=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.file_path // ""')

if [ -z "$FILE" ]; then
    exit 0
fi

case "$FILE" in
    *.md)
        echo "$FILE" >> "${CLAUDE_PROJECT_DIR}/.claude/vyasa-md-changed"
        ;;
esac
