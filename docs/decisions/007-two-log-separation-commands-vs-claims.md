# 007 Two-log separation: commands vs. claims

**Status:** Accepted
**Date:** 2026-03-08

## Context

The pipeline needed to track two distinct kinds of events during a run: which scripts each agent
invoked (for observability and debugging), and which documents each `doc-editor` instance claimed,
confirmed, and committed (for correctness of concurrent edits). Both event types needed to be
written concurrently by parallel agents without coordination.

Combining them into a single log was considered. A unified log would have all events in one file,
but it would conflate two consumers with different read patterns: the claim `confirm` step scans
for a second `claim` on the same `doc-id` to detect conflicts; a debugging tool reads command
events to reconstruct what ran and why. Mixed event types complicate both reads.

## Decision

The pipeline uses two separate append-only JSONL logs. `commands.log` records every script
invocation wrapped by `vyasa-run.sh` — one `start` entry before the command and one `done` entry
after, with timestamp, agent, and exit code. `changes.log` records claim lifecycle events written
by `vyasa-claim.sh` — `claim`, `confirm`, `commit`, and `release`. Both logs use POSIX `O_APPEND`
for concurrent writes (see ADR 005).

## Consequences

- The `confirm` step in `vyasa-claim.sh` scans only `changes.log` — no filtering needed to
  isolate claim events from unrelated command noise
- `commands.log` is independently inspectable after a run to reconstruct the sequence and timing
  of every script call, without parsing claim semantics
- Any agent-invoked script that should appear in the audit trail must be wrapped with
  `vyasa-run.sh`; unwrapped calls are invisible to the command log — this is an invariant the
  agent prompts must enforce, not the script itself
- Two files to manage per run instead of one; both must be created and both accumulate across the
  run lifetime

## Alternatives considered

**Single unified log with an event type field.** All events go to one file; readers filter by
`"event":"claim"` vs. `"event":"cmd"`. Simpler file management, but the `confirm` step must
filter on every scan, and post-run inspection requires understanding both event schemas at once.
Rejected because the two consumers have no reason to share a file — their read patterns and
retention needs are independent.

**No command log; rely on agent context.** Skip `vyasa-run.sh` entirely and let agents' own
context serve as the record of what ran. Rejected because agent context is ephemeral — it
disappears at the end of the session and cannot be inspected after the fact or compared across
runs.
