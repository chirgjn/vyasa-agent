#!/usr/bin/env bash
set -euo pipefail
# Block `git commit --no-verify` to ensure pre-commit hooks always run.

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command')

# Strip heredoc bodies (everything from << to the end), then quoted strings,
# so --no-verify inside a commit message doesn't false-positive.
stripped=$(echo "$command" \
    | sed 's/<<.*$//' \
    | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")

if echo "$stripped" | grep -qE 'git\s+commit\b.*--no-verify'; then
    echo '{"decision":"deny","reason":"git commit --no-verify is not allowed — pre-commit hooks must always run."}' >&2
    exit 2
fi
