#!/usr/bin/env bash
# Fails if the plugin version lacks a -dev suffix.
# Used as a pre-commit hook — the release workflow (which produces a non-dev commit) runs in CI without pre-commit.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MANIFEST="$REPO_ROOT/plugin/.claude-plugin/plugin.json"

version=$(jq -r '.version' "$MANIFEST")

if [[ "$version" == *-dev ]]; then
    exit 0
fi

echo "plugin version '$version' is missing the -dev suffix." >&2
echo "Bump the version and add -dev before pushing:" >&2
echo "  scripts/bump-plugin-version.sh patch" >&2
exit 1
