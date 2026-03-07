#!/usr/bin/env bash
# Detects documentation file changes from PostToolUse hook input and suggests
# which vyasa agent to dispatch. Reads tool result JSON from stdin.
#
# Exit 0 always (non-blocking suggestion only).
# Outputs JSON with systemMessage naming the agent(s) to consider dispatching.

set -euo pipefail

input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Only process Write and Edit tool calls with a file path
if [[ -z "$file_path" ]]; then
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

agents=()

# Normalize to basename and relative path for matching
basename=$(basename "$file_path")
basename_lower=$(echo "$basename" | tr '[:upper:]' '[:lower:]')

# Check: AGENTS.md or CLAUDE.md modified
if [[ "$basename_lower" == "agents.md" || "$basename_lower" == "claude.md" ]]; then
  agents+=("agents-md-lint")
fi

# Check: layout.md modified — structural change, trigger doc-maintenance
if [[ "$basename_lower" == "layout.md" ]]; then
  agents+=("doc-maintenance")
fi

# Check: file is inside a known docs directory.
# Resolve the docs dir from the nearest layout.md to the changed file.
# Silently skip if layout.md is not set up yet (non-blocking hook).
docs_dir="$("$SCRIPT_DIR/find-docs-dir.sh" "$file_path" 2>/dev/null || true)"
if [[ -n "$docs_dir" && "$file_path" == "$docs_dir"/* ]]; then
  agents+=("doc-lint")
fi

# Check: Mermaid code block in written content
# For Write tool, check if content contains a mermaid block
if [[ "$tool_name" == "Write" ]]; then
  has_mermaid=$(echo "$input" | jq -r '.tool_input.content // empty' | grep -c '```mermaid' || true)
  if [[ "$has_mermaid" -gt 0 ]]; then
    agents+=("diagram-lint")
  fi
fi

# For Edit tool, check if new_string contains a mermaid block
if [[ "$tool_name" == "Edit" ]]; then
  has_mermaid=$(echo "$input" | jq -r '.tool_input.new_string // empty' | grep -c '```mermaid' || true)
  if [[ "$has_mermaid" -gt 0 ]]; then
    agents+=("diagram-lint")
  fi
fi

# Check: structural change — a file was written to a new top-level directory
# that is not a known docs, config, or tool directory.
# Use layout.md to identify known top-level dirs rather than a hardcoded list.
project_dir="${CLAUDE_PROJECT_DIR:-}"
if [[ -n "$project_dir" && "$file_path" == "$project_dir"/* ]]; then
  relative="${file_path#"$project_dir"/}"
  top_dir=$(echo "$relative" | cut -d'/' -f1)
  layout_file="$project_dir/layout.md"
  # Only flag if layout.md exists and the new top-level dir is not listed in it
  if [[ -f "$layout_file" && "$relative" == */* ]]; then
    if ! grep -qE "(^|[[:space:]])\`?${top_dir}/?\`?" "$layout_file" 2>/dev/null; then
      agents+=("doc-maintenance")
    fi
  fi
fi

# If no agents to suggest, exit silently
if [[ ${#agents[@]} -eq 0 ]]; then
  exit 0
fi

# Deduplicate and build comma-separated list
agent_list=$(printf '%s\n' "${agents[@]}" | sort -u | paste -sd ',' - | sed 's/,/, /g')
message="Documentation file changed: $(basename "$file_path"). Consider dispatching: ${agent_list}."

echo "{\"systemMessage\": $(echo "$message" | jq -Rs .)}"
