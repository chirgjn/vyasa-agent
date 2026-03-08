# Run Infrastructure Spec

**Status:** Live
**Date:** 2026-03-09

Exhaustive description of the runtime infrastructure shared by all audit and fix pipeline
runs: run ID generation, the document registry, the filesystem layout, the claim protocol,
and the task structure. Read this before implementing or modifying any agent that reads or
writes `.vyasa/` artifacts. For pipeline architecture — phases, agents, gates — see
`docs/audit-pipeline.md`. For dispatch mechanics, see `docs/specs/pipeline-dispatch.md`.
For the claim protocol decision, see ADR 005 and ADR 007 (`docs/decisions/`).

---

## Run ID

Each audit run generates a unique 8-character hex run ID via
`plugin/scripts/generate-run-id.sh`, which uses `openssl` if available and falls back to
`/dev/urandom`:

```bash
run_id=$(bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-run-id.sh)
```

The run ID scopes all artifacts for that run under `.vyasa/<run-id>/`.

---

## Document Registry

The registry maps stable `doc-id` values to file paths. It is written by
`plugin/scripts/build-registry.sh` and owned exclusively by the orchestrator — never
written by auditors, fixers, or `doc-editor`.

```json
{
  "doc-001": {
    "original_path": "docs/setup.md",
    "current_path": "docs/setup.md"
  },
  "doc-002": {
    "original_path": "docs/ErrorHandling_v2.md",
    "current_path": "docs/error-handling.md"
  }
}
```

`current_path` is updated by the orchestrator at each fix gate when a fixer recommends a
rename or move. Agents always read `current_path`. The registry is only written between
phases, never during a phase.

**Integrity check:** After writing, the orchestrator re-reads and parses the registry. If
the parse fails (truncated write, empty file), it aborts, deletes the run directory, and
reports the error. Phase summaries are extracted by `plugin/scripts/parse-phase-summary.sh`.

---

## Filesystem Layout

```
.vyasa/                          — ephemeral, not committed
  <run-id>/
    registry.json                — doc-id → path mapping (orchestrator-owned)
    changes.log                  — append-only claim log
    reports/
      phase-1/
        doc-audit/<doc-id>.md
        doc-fixer/<doc-id>.md
      phase-2/
        structure-audit/<doc-id>.md    prose-audit/<doc-id>.md
        convention-audit/<doc-id>.md   content-audit/<doc-id>.md
        structure-fixer/<doc-id>.md    prose-fixer/<doc-id>.md
        convention-fixer/<doc-id>.md   content-fixer/<doc-id>.md
      phase-3/
        discoverability-audit/<doc-id>.md   staleness-audit/<doc-id>.md
        health-audit/<doc-id>.md
        discoverability-fixer/<doc-id>.md   staleness-fixer/<doc-id>.md
        health-fixer/<doc-id>.md
    tasks/
      <task-id>.json             — one per doc-editor task (orchestrator-written)
```

---

## Claim Protocol

Before editing any document, `doc-editor` must claim it via `plugin/scripts/vyasa-claim.sh`.
The claim log (`.vyasa/<run-id>/changes.log`) is append-only JSONL. See ADR 005 for the
POSIX O_APPEND decision and ADR 007 for the two-log separation.

```bash
vyasa-claim.sh claim   <run-id> <agent> <doc-id> [<doc-id> ...]  # register intent
vyasa-claim.sh confirm <run-id> <agent> <doc-id> [<doc-id> ...]  # verify uncontested (exit 1 = conflict)
vyasa-claim.sh commit  <run-id> <agent> <doc-id> [<doc-id> ...]  # record completion
vyasa-claim.sh release <run-id> <agent> <doc-id> [<doc-id> ...]  # release on abort
```

For multi-file tasks, `doc-editor` claims all files in one step before editing any.

The `confirm` step scans the log for a second `claim` on the same `doc-id` from a different
agent. A conflict indicates an orchestrator bug and fails loudly — never retried or silently
skipped. See ADR 003.

Auditors and fixers never claim. Only `doc-editor` claims.

---

## Task Structure

The orchestrator writes each task file to `.vyasa/<run-id>/tasks/<task-id>.json` before
dispatching `doc-editor`. `doc-editor` receives only `task-id` and `run-id` and reads the
task file itself.

```json
{
  "id": "task-003",
  "doc-ids": ["doc-002"],
  "finding": "phase-1 / doc-audit / Warning — wrong filename",
  "change": "Rename docs/ErrorHandling_v2.md to docs/error-handling.md. Update the routing table entry in AGENTS.md.",
  "depends_on": []
}
```
