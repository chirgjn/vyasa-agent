#!/usr/bin/env bash
# Parse PHASE SUMMARY block from an audit report file.
#
# Usage:
#   parse-phase-summary.sh <report_file>
#
# Outputs JSON to stdout:
#   {
#     "doc_id": "doc-001",
#     "phase": "1 — doc-audit",
#     "findings": "1 error, 0 warnings, 0 info",
#     "context": "Optional context line"
#   }
#
# Exit codes:
#   0 - Success
#   1 - Parse error (invalid or missing PHASE SUMMARY)
#   2 - Invalid arguments

set -euo pipefail

if [ $# -ne 1 ]; then
    sed -n 's/^# \{0,1\}//p' "$0" | head -20 >&2
    exit 2
fi

REPORT_FILE="$1"

if [ ! -f "$REPORT_FILE" ]; then
    echo "Error: Report file not found: $REPORT_FILE" >&2
    exit 2
fi

# Extract PHASE SUMMARY block fields using awk.
# The block looks like:
#   PHASE SUMMARY
#   Doc-ID: doc-001
#   Phase: 1 — doc-audit
#   Findings: 0 errors, 0 warnings, 0 info
#   Context: optional line   (may be absent)
result="$(awk '
    /^PHASE SUMMARY[[:space:]]*$/ { in_block=1; next }
    in_block && /^Doc-ID:[[:space:]]*/ {
        sub(/^Doc-ID:[[:space:]]*/, "")
        doc_id=$0
        next
    }
    in_block && /^Phase:[[:space:]]*/ {
        sub(/^Phase:[[:space:]]*/, "")
        phase=$0
        next
    }
    in_block && /^Findings:[[:space:]]*/ {
        sub(/^Findings:[[:space:]]*/, "")
        findings=$0
        next
    }
    in_block && /^Context:[[:space:]]*/ {
        sub(/^Context:[[:space:]]*/, "")
        context=$0
        next
    }
    in_block && /^[[:space:]]*$/ && doc_id != "" && phase != "" && findings != "" {
        # Blank line after we have required fields — done
        exit
    }
    END {
        if (doc_id == "" || phase == "" || findings == "") {
            exit 0
        }
        # Escape double quotes and backslashes for JSON
        gsub(/\\/, "\\\\", doc_id);   gsub(/"/, "\\\"", doc_id)
        gsub(/\\/, "\\\\", phase);    gsub(/"/, "\\\"", phase)
        gsub(/\\/, "\\\\", findings); gsub(/"/, "\\\"", findings)
        gsub(/\\/, "\\\\", context);  gsub(/"/, "\\\"", context)
        printf "{\"doc_id\":\"%s\",\"phase\":\"%s\",\"findings\":\"%s\",\"context\":\"%s\"}\n",
            doc_id, phase, findings, context
    }
' "$REPORT_FILE")"

if [ -z "$result" ]; then
    echo "Error: PHASE SUMMARY block not found or invalid" >&2
    exit 1
fi

echo "$result"
