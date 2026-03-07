#!/usr/bin/env bash
# Append-only claim log for vyasa audit runs.
#
# Agents use this script to claim exclusive write access to one or more
# documents before editing them. The log is append-only. A claim is confirmed
# only when the agent reads back the log and finds its entry is the sole claim
# for each doc-id in this run. No other synchronisation mechanism is used.
#
# Usage:
#   vyasa-claim.sh claim   <run-id> <agent> <doc-id> [<doc-id> ...]   # append claims
#   vyasa-claim.sh confirm <run-id> <agent> <doc-id> [<doc-id> ...]   # check all uncontested
#   vyasa-claim.sh commit  <run-id> <agent> <doc-id> [<doc-id> ...]   # append committed entries
#   vyasa-claim.sh release <run-id> <agent> <doc-id> [<doc-id> ...]   # append released entries (on abort)
#   vyasa-claim.sh status  <run-id> <doc-id>                          # print all log entries for a doc
#
# Exit codes:
#   0 — success (all claims confirmed, committed, etc.)
#   1 — conflict detected (another agent has claimed one or more doc-ids)
#   2 — usage error
#   3 — precondition not met (confirm called without a prior claim, etc.)
#
# Log location:
#   .vyasa/<run-id>/changes.log
#
# Log format (one JSON line per entry):
#   {"ts":<unix-ts>,"run_id":"...","doc_id":"...","agent":"...","action":"claim|committed|released"}

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

usage() {
    echo "Usage:" >&2
    echo "  $(basename "$0") claim   <run-id> <agent> <doc-id> [<doc-id> ...]" >&2
    echo "  $(basename "$0") confirm <run-id> <agent> <doc-id> [<doc-id> ...]" >&2
    echo "  $(basename "$0") commit  <run-id> <agent> <doc-id> [<doc-id> ...]" >&2
    echo "  $(basename "$0") release <run-id> <agent> <doc-id> [<doc-id> ...]" >&2
    echo "  $(basename "$0") status  <run-id> <doc-id>" >&2
    exit 2
}

log_path() {
    local run_id="$1"
    echo ".vyasa/${run_id}/changes.log"
}

# Append one JSON line to the log.
# Uses >> which is atomic for small writes on local filesystems (POSIX O_APPEND).
append_entry() {
    local run_id="$1"
    local doc_id="$2"
    local agent="$3"
    local action="$4"
    local log
    log="$(log_path "$run_id")"
    local ts
    ts="$(date +%s)"

    mkdir -p "$(dirname "$log")"
    printf '{"ts":%s,"run_id":"%s","doc_id":"%s","agent":"%s","action":"%s"}\n' \
        "$ts" "$run_id" "$doc_id" "$agent" "$action" >> "$log"
}

# Print all log entries for a given doc-id in a given run.
doc_entries() {
    local run_id="$1"
    local doc_id="$2"
    local log
    log="$(log_path "$run_id")"

    if [[ ! -f "$log" ]]; then
        return
    fi

    # Match lines containing the doc_id and run_id — grep is safe here since
    # doc_id and run_id are controlled identifiers (no special chars).
    grep "\"doc_id\":\"${doc_id}\"" "$log" | grep "\"run_id\":\"${run_id}\"" || true
}

# Count how many claim entries exist for this doc-id in this run.
claim_count() {
    local run_id="$1"
    local doc_id="$2"
    doc_entries "$run_id" "$doc_id" | grep -c '"action":"claim"'
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

cmd_claim() {
    local run_id="$1" agent="$2"
    shift 2
    for doc_id in "$@"; do
        append_entry "$run_id" "$doc_id" "$agent" "claim"
    done
}

cmd_confirm() {
    local run_id="$1" agent="$2"
    shift 2
    local log
    log="$(log_path "$run_id")"

    if [[ ! -f "$log" ]]; then
        echo "error: no log found at $log — was 'claim' called first?" >&2
        exit 3
    fi

    local conflict=0
    for doc_id in "$@"; do
        # Check this agent has a claim entry
        local own_claim
        own_claim=$(doc_entries "$run_id" "$doc_id" \
            | grep '"action":"claim"' \
            | grep -c "\"agent\":\"${agent}\"")

        if [[ "$own_claim" -eq 0 ]]; then
            echo "error: no claim found for agent '${agent}' on doc '${doc_id}' — call 'claim' first." >&2
            exit 3
        fi

        # Check total claim count — must be exactly 1
        local total
        total="$(claim_count "$run_id" "$doc_id")"

        if [[ "$total" -ne 1 ]]; then
            echo "conflict: ${total} claims found for doc '${doc_id}' in run '${run_id}'." >&2
            echo "Contested claims:" >&2
            doc_entries "$run_id" "$doc_id" | grep '"action":"claim"' >&2
            conflict=1
        fi
    done

    [[ "$conflict" -eq 0 ]] || exit 1
}

cmd_commit() {
    local run_id="$1" agent="$2"
    shift 2
    for doc_id in "$@"; do
        append_entry "$run_id" "$doc_id" "$agent" "committed"
    done
}

cmd_release() {
    local run_id="$1" agent="$2"
    shift 2
    for doc_id in "$@"; do
        append_entry "$run_id" "$doc_id" "$agent" "released"
    done
}

cmd_status() {
    local run_id="$1" doc_id="$2"
    local entries
    entries="$(doc_entries "$run_id" "$doc_id")"
    if [[ -z "$entries" ]]; then
        echo "No log entries for doc '${doc_id}' in run '${run_id}'."
    else
        echo "$entries"
    fi
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

CMD="${1:-}"

case "$CMD" in
    claim)
        [[ $# -ge 4 ]] || usage
        cmd_claim "$2" "$3" "${@:4}"
        ;;
    confirm)
        [[ $# -ge 4 ]] || usage
        cmd_confirm "$2" "$3" "${@:4}"
        ;;
    commit)
        [[ $# -ge 4 ]] || usage
        cmd_commit "$2" "$3" "${@:4}"
        ;;
    release)
        [[ $# -ge 4 ]] || usage
        cmd_release "$2" "$3" "${@:4}"
        ;;
    status)
        [[ $# -eq 3 ]] || usage
        cmd_status "$2" "$3"
        ;;
    *)
        usage
        ;;
esac
