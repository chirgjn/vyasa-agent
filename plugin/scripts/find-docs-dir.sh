#!/usr/bin/env bash
# Resolves the docs directory for a given file or directory path.
#
# Walks up from the given path to find the nearest layout.md, then reads
# the `docs:` field from its YAML frontmatter.
#
# Usage:
#   find-docs-dir.sh <path>
#
# Output:
#   Prints the absolute path to the docs directory, e.g. /repo/services/payments/docs
#
# Exit codes:
#   0 — docs directory found and printed
#   1 — layout.md not found or docs: field missing (prints error to stderr)
#
# All other vyasa scripts call this rather than hardcoding docs/.
# If this exits 1, the caller should fail fast and tell the user to run /vyasa:setup.

set -euo pipefail

TARGET="${1:?Usage: find-docs-dir.sh <path>}"

# Resolve to absolute path, allow non-existent files (for new files being written)
if [[ -e "$TARGET" ]]; then
    TARGET="$(cd "$(dirname "$TARGET")" && pwd)/$(basename "$TARGET")"
else
    # For non-existent paths, resolve the nearest existing parent
    parent="$TARGET"
    while [[ ! -e "$parent" && "$parent" != "/" ]]; do
        parent="$(dirname "$parent")"
    done
    TARGET="$(cd "$parent" && pwd)"
fi

# If TARGET is a file, start from its directory
if [[ -f "$TARGET" ]]; then
    search_dir="$(dirname "$TARGET")"
else
    search_dir="$TARGET"
fi

# Walk up the directory tree looking for layout.md
dir="$search_dir"
while true; do
    layout_file="$dir/layout.md"
    if [[ -f "$layout_file" ]]; then
        # Extract the docs: field from YAML frontmatter
        # Frontmatter is delimited by --- on its own line
        docs_rel=$(awk '
            /^---[[:space:]]*$/ && !in_front { in_front=1; next }
            /^---[[:space:]]*$/ && in_front  { exit }
            in_front && /^docs:[[:space:]]*/ {
                sub(/^docs:[[:space:]]*/, "")
                sub(/[[:space:]]*$/, "")
                # Strip optional surrounding quotes
                gsub(/^["'"'"']|["'"'"']$/, "")
                print
                exit
            }
        ' "$layout_file")

        if [[ -z "$docs_rel" ]]; then
            echo "error: layout.md found at $layout_file but has no 'docs:' field." >&2
            echo "Run /vyasa:setup to configure the docs directory." >&2
            exit 1
        fi

        # Resolve relative to the layout.md's directory
        docs_abs="$dir/$docs_rel"
        echo "$docs_abs"
        exit 0
    fi

    # Stop at filesystem root
    parent="$(dirname "$dir")"
    if [[ "$parent" == "$dir" ]]; then
        break
    fi
    dir="$parent"
done

echo "error: no layout.md found in $search_dir or any parent directory." >&2
echo "Run /vyasa:setup to initialise the project." >&2
exit 1
