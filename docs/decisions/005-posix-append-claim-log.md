# 005 POSIX O_APPEND for concurrent claim log writes

**Status:** Accepted
**Date:** 2026-03-08

## Context

Multiple `doc-editor` instances run in parallel, each needing to record claim, commit,
and release events to a shared log (`.vyasa/<run-id>/changes.log`). The log is used by
the `confirm` step to detect if two agents have claimed the same document.

Concurrent writes to a shared file require either coordination (a lock) or a write
mechanism with atomicity guarantees. A lock (advisory or OS-level) introduces a
coordination point that can deadlock or leave the lock held if an agent crashes.

## Decision

The claim log is append-only JSONL. Each agent appends via the shell `>>` operator, which
uses `O_APPEND`. POSIX guarantees that `write()` calls under `PIPE_BUF` bytes (at least
512, typically 4096) are atomic when a file is opened with `O_APPEND`. A single JSONL
line is well under that limit, so concurrent appends produce complete, non-interleaved
lines without coordination.

The orchestrator's design constraint provides the primary correctness guarantee: it never
assigns the same `doc-id` to two agents simultaneously. The `confirm` step (scanning the
log for a second `claim` from a different agent) is belt-and-suspenders — it catches
orchestrator bugs, not expected concurrent writes.

## Consequences

- No lock management; no risk of deadlock or stale locks from agent crashes
- The log is inspectable as plain JSONL after a run
- Atomicity guarantee holds on local filesystems (ext4, APFS, tmpfs); NFS and FUSE mounts
  are not supported deployment targets for `.vyasa/`
- Concurrent writes are safe only up to `PIPE_BUF` bytes per write — JSONL lines must
  stay under this limit; multi-line or large-payload log entries would break atomicity
- The `confirm` step catching a conflict signals an orchestrator bug, not a race condition
  the system is designed to handle — it fails loudly and does not retry

## Alternatives considered

**Advisory lock file.** Create `.vyasa/<run-id>/<doc-id>.lock` before editing, delete
after. Simpler to reason about, but requires cleanup if an agent crashes while holding
the lock, and adds filesystem churn proportional to the number of concurrent edits.

**SQLite.** Append-only table with WAL mode; SQLite's concurrent write guarantees are
well-understood. More robust but introduces a dependency and makes the log less
inspectable without tooling.
