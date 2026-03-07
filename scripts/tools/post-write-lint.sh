#!/usr/bin/env bash
# Dev hook: lint/format a file after Write or Edit.
# Routes to the appropriate dev tool based on file extension.
# Called by .claude/settings.json PostToolUse hook.
set -euo pipefail

FILE=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.file_path // ""')

if [ -z "$FILE" ]; then
    exit 0
fi

case "$FILE" in
    *.py)
        scripts/tools/ruff-fix.sh "$FILE"
        ;;
    *.md)
        echo "$FILE" >> "${CLAUDE_PROJECT_DIR}/.claude/vyasa-md-changed"
        ;;
    *.sh)
        scripts/tools/shellcheck-lint.sh "$FILE"
        ;;
    *.toml)
        scripts/tools/taplo-fmt.sh "$FILE"
        ;;
    *.yaml|*.yml)
        scripts/tools/yamllint-fmt.sh "$FILE"
        case "$FILE" in
            .github/workflows/*|./.github/workflows/*)
                uv run actionlint "$FILE"
                ;;
        esac
        ;;
esac
