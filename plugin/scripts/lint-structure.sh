#!/usr/bin/env bash
# Compares AGENTS.md structure map against actual top-level directories.
# Usage: lint-structure.sh <agents-md-path>
# Emits REMAINING lines. No auto-fix (descriptions require judgment). Exit 0 always.

set -euo pipefail

AGENTS_FILE="${1:?Usage: lint-structure.sh <agents-md-path>}"
PROJECT_ROOT="$(dirname "$AGENTS_FILE")"

# Dirs to always ignore
IGNORE="^\.git$|^\.worktrees$|^node_modules$|^__pycache__$|^\.venv$"

# Actual top-level directories on disk
actual_dirs=()
while IFS= read -r d; do
    actual_dirs+=("$d")
done < <(find "$PROJECT_ROOT" -maxdepth 1 -mindepth 1 -type d \
    | while IFS= read -r p; do basename "$p"; done \
    | grep -vE "$IGNORE" | sort)

# Dirs mentioned in the structure map (lines matching "dirname/" in code block)
mapped_dirs=()
while IFS= read -r d; do
    mapped_dirs+=("$d")
done < <(grep -oE '^[a-z._-]+/' "$AGENTS_FILE" | tr -d '/' | sort -u || true)

# Dirs on disk but not in structure map
for d in "${actual_dirs[@]+"${actual_dirs[@]}"}"; do
    if ! printf '%s\n' "${mapped_dirs[@]+"${mapped_dirs[@]}"}" | grep -qx "$d"; then
        echo "REMAINING: warning — structure-map: directory \`$d/\` exists on disk but is unlisted in AGENTS.md structure map"
    fi
done

# Dirs in structure map but not on disk
for d in "${mapped_dirs[@]+"${mapped_dirs[@]}"}"; do
    if ! printf '%s\n' "${actual_dirs[@]+"${actual_dirs[@]}"}" | grep -qx "$d"; then
        echo "REMAINING: warning — structure-map: \`$d/\` listed in structure map but does not exist on disk (stale entry, missing)"
    fi
done
