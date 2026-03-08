#!/usr/bin/env bash
# Bumps the patch version in .claude-plugin/plugin.json.
# Usage: scripts/bump-plugin-version.sh [major|minor|patch]
#   Defaults to "patch" if no argument given.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$REPO_ROOT/plugin/.claude-plugin/plugin.json"

bump_type="${1:-patch}"

current_version=$(jq -r '.version' "$MANIFEST")
# Strip pre-release suffix (e.g. -dev) before parsing, reattach after
numeric="${current_version%%-*}"
suffix="${current_version#"$numeric"}"  # empty string or e.g. "-dev"

IFS='.' read -r major minor patch <<< "$numeric"

case "$bump_type" in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
  *) echo "Usage: $0 [major|minor|patch]" >&2; exit 1 ;;
esac

new_version="$major.$minor.$patch$suffix"

# Update manifest in place
jq --arg v "$new_version" '.version = $v' "$MANIFEST" > "$MANIFEST.tmp"
mv "$MANIFEST.tmp" "$MANIFEST"

echo "$new_version"
