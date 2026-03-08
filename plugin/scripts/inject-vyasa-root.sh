#!/usr/bin/env bash
# inject-vyasa-root.sh — Replace @@VYASA_ROOT@@ in agent files with the real plugin path.
#
# Called from SessionStart. The marker file (<plugin-root>/agents/.vyasa-root-injected)
# stores the list of injected agent filenames (one per line). On each run, any agent
# not in the marker is injected and the marker is updated — so new agents added after
# first install are picked up automatically.

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AGENTS_DIR="$PLUGIN_ROOT/agents"
MARKER="$AGENTS_DIR/.vyasa-root-injected"

if [[ ! -d "$AGENTS_DIR" ]]; then
    echo "inject-vyasa-root: error: agents dir not found: $AGENTS_DIR" >&2
    exit 1
fi

count=0
for f in "$AGENTS_DIR"/*.md; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f")"

    # Skip if already recorded in the marker.
    if [[ -f "$MARKER" ]] && grep -qxF "$name" "$MARKER"; then
        continue
    fi

    if grep -qF '@@VYASA_ROOT@@' "$f"; then
        sed -i '' "s|@@VYASA_ROOT@@|$PLUGIN_ROOT|g" "$f"
        echo "$name" >> "$MARKER"
        count=$((count + 1))
    fi
done

if [[ $count -gt 0 ]]; then
    echo "inject-vyasa-root: injected VYASA_ROOT into $count agent file(s)" >&2
fi
