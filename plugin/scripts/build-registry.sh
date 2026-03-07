#!/usr/bin/env bash
# Build audit registry from project markdown files.
#
# Usage:
#   build-registry.sh <output_path> [<project_root>]
#
# Generates registry.json with stable doc-ids assigned in alphabetical order.
# Excludes: .vyasa/, node_modules/, .git/
#
# Registry format:
#   {
#     "doc-001": { "original_path": "README.md", "current_path": "README.md" },
#     ...
#   }
#
# Exit codes:
#   0 - Success
#   1 - Write or parse error
#   2 - Invalid arguments

set -euo pipefail

if [ $# -lt 1 ]; then
    sed -n 's/^# \{0,1\}//p' "$0" | head -20 >&2
    exit 2
fi

OUTPUT_PATH="$1"
PROJECT_ROOT="${2:-$(pwd)}"

if [ ! -d "$PROJECT_ROOT" ]; then
    echo "Error: Project root does not exist: $PROJECT_ROOT" >&2
    exit 2
fi

# Create parent directory
mkdir -p "$(dirname "$OUTPUT_PATH")"

# Find all markdown files, sorted alphabetically, excluding unwanted dirs
# Uses find with pruning for .vyasa, node_modules, .git
md_files=()
while IFS= read -r f; do
    md_files+=("$f")
done < <(
    find "$PROJECT_ROOT" \
        \( -name '.vyasa' -o -name 'node_modules' -o -name '.git' \) -prune \
        -o -name '*.md' -print \
    | sed "s|^$PROJECT_ROOT/||" \
    | LC_ALL=C sort
)

if [ ${#md_files[@]} -eq 0 ]; then
    echo "Warning: No markdown files found" >&2
fi

# Build JSON registry
{
    echo "{"
    count=0
    total=${#md_files[@]}
    for f in "${md_files[@]}"; do
        count=$((count + 1))
        doc_id="$(printf 'doc-%03d' "$count")"
        # Escape backslashes and double quotes in path (paths shouldn't have these but be safe)
        escaped="$(printf '%s' "$f" | sed 's/\\/\\\\/g; s/"/\\"/g')"
        if [ "$count" -lt "$total" ]; then
            printf '  "%s": { "original_path": "%s", "current_path": "%s" },\n' \
                "$doc_id" "$escaped" "$escaped"
        else
            printf '  "%s": { "original_path": "%s", "current_path": "%s" }\n' \
                "$doc_id" "$escaped" "$escaped"
        fi
    done
    echo "}"
} > "$OUTPUT_PATH"

# Verify it's valid JSON by parsing it back
if ! jq empty "$OUTPUT_PATH" 2>/dev/null; then
    echo "Error: Registry parse failed — output is not valid JSON" >&2
    rm -f "$OUTPUT_PATH"
    exit 1
fi

echo "Registry written: $OUTPUT_PATH"
echo "Documents: ${#md_files[@]}"
