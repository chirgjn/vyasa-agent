#!/usr/bin/env bash
# Checks routing table integrity in AGENTS.md.
# Usage: lint-routing.sh <agents-md-path>
# Finds orphan doc files (no routing entry) → adds stub entry.
# Finds broken routing entries (file missing) → removes the row.
# Emits FIXED/REMAINING lines to stdout. Exit 0 always.
#
# Docs directory is discovered from layout.md frontmatter via find-docs-dir.sh.
# If layout.md is missing or has no docs: field, exits with an error.

set -euo pipefail

AGENTS_FILE="${1:?Usage: lint-routing.sh <agents-md-path>}"
PROJECT_ROOT="$(dirname "$AGENTS_FILE")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve docs directory from layout.md
DOCS_DIR="$("$SCRIPT_DIR/find-docs-dir.sh" "$PROJECT_ROOT")" || {
    echo "REMAINING: error — could not resolve docs directory. Run /vyasa:setup first." >&2
    exit 1
}

# Find all .md files under the docs directory (exclude archive/)
doc_files=()
while IFS= read -r f; do
    doc_files+=("$f")
done < <(
    find "$DOCS_DIR" -name "*.md" -not -path "*/archive/*" 2>/dev/null | sort || true
)

# Find routing table entries — any backtick-fenced .md paths in AGENTS.md
routing_entries=()
while IFS= read -r entry; do
    routing_entries+=("$entry")
done < <(grep -oE '[^|` ]+\.md' "$AGENTS_FILE" 2>/dev/null | sort -u || true)

# 1. Remove broken routing entries (entry exists but file does not)
for entry in "${routing_entries[@]+"${routing_entries[@]}"}"; do
    full_path="$PROJECT_ROOT/$entry"
    if [[ ! -f "$full_path" ]]; then
        # Remove the table row containing this path (in-place)
        sed -i.bak "/$(echo "$entry" | sed 's/\//\\\//g')/d" "$AGENTS_FILE"
        rm -f "${AGENTS_FILE}.bak"
        echo "FIXED: routing-table — removed broken entry $entry"
    fi
done

# 2. Add stub entries for orphan docs (no routing entry)
for doc in "${doc_files[@]+"${doc_files[@]}"}"; do
    rel="${doc#"$PROJECT_ROOT/"}"
    if ! grep -qF "$rel" "$AGENTS_FILE"; then
        # Find the routing table and append a stub row
        # Look for the last | row in the routing section and insert after it
        stub="| When you are ... | \`$rel\` |"
        # Append after the last table block
        awk -v stub="$stub" '
            /^\| .* \|$/ { last_table_line=NR; lines[NR]=$0; next }
            { lines[NR]=$0 }
            END {
                for (i=1; i<=NR; i++) {
                    print lines[i]
                    if (i==last_table_line) print stub
                }
            }
        ' "$AGENTS_FILE" > "${AGENTS_FILE}.tmp" && mv "${AGENTS_FILE}.tmp" "$AGENTS_FILE"
        echo "FIXED: routing-table — added stub entry for $rel"
    fi
done
