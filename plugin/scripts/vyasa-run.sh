#!/usr/bin/env bash
# Run a command and log it to the audit run's command log.
#
# Usage:
#   vyasa-run.sh <run-id> <agent> <command> [<args>...]
#   vyasa-run.sh <run-id> <agent> -c '<shell expression>'
#
# Appends JSONL entries to .vyasa/<run-id>/commands.log before and after running the command.
# Passes through the exit code of the wrapped command.
#
# Log entry format (two entries per invocation):
#   {"ts":"<iso8601>","run_id":"<id>","agent":"<agent>","event":"start","cmd":"<cmd>"}
#   {"ts":"<iso8601>","run_id":"<id>","agent":"<agent>","event":"done","cmd":"<cmd>","exit":<code>}
#
# Exit codes:
#   Passes through the exit code of the wrapped command.
#   Exit 2 if called with fewer than 3 arguments.

set -euo pipefail

if [ $# -lt 3 ]; then
    echo "Usage: vyasa-run.sh <run-id> <agent> <command> [<args>...]" >&2
    echo "       vyasa-run.sh <run-id> <agent> -c '<shell expression>'" >&2
    exit 2
fi

RUN_ID="$1"
AGENT="$2"
shift 2

LOG=".vyasa/${RUN_ID}/commands.log"
mkdir -p ".vyasa/${RUN_ID}"

ts() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

escape_json() {
    # Escape backslashes, double quotes, and control characters for JSON string
    printf '%s' "$1" \
        | sed 's/\\/\\\\/g; s/"/\\"/g' \
        | tr '\n' ' ' \
        | tr '\t' ' '
}

# Build display string for the log
if [ "$1" = "-c" ]; then
    CMD_DISPLAY="$2"
else
    CMD_DISPLAY="$*"
fi

CMD_ESC="$(escape_json "$CMD_DISPLAY")"

# Log start
printf '{"ts":"%s","run_id":"%s","agent":"%s","event":"start","cmd":"%s"}\n' \
    "$(ts)" "$RUN_ID" "$AGENT" "$CMD_ESC" >> "$LOG"

# Run the command
exit_code=0
if [ "$1" = "-c" ]; then
    bash -c "$2" || exit_code=$?
else
    "$@" || exit_code=$?
fi

# Log completion
printf '{"ts":"%s","run_id":"%s","agent":"%s","event":"done","cmd":"%s","exit":%d}\n' \
    "$(ts)" "$RUN_ID" "$AGENT" "$CMD_ESC" "$exit_code" >> "$LOG"

exit "$exit_code"
