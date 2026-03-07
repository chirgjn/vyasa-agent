# Pipeline Dispatch Spec

**Status:** Accepted
**Date:** 2026-03-08

Read this before implementing or modifying dispatch behavior in `full-audit`,
`fix-orchestrator`, or any orchestrator agent. This spec exhaustively describes how
orchestrators dispatch subagents, pass arguments, restrict agent allowlists, and batch
documents across phases. For pipeline architecture — phases, gates, report formats, agent inventory —
see `docs/audit-pipeline.md`. For the decisions behind phasing and handoff, see `docs/decisions/`.

---

## Dispatch Mechanism

Claude Code dispatches subagents via the `Agent` tool. Orchestrators do not write raw tool-call
JSON. The system prompt describes the task in plain text, names the target agent, and Claude
invokes the `Agent` tool automatically. The only channel from orchestrator to subagent is the
prompt string — all arguments must be embedded in it.

Orchestrators pass arguments as plain `key: value` pairs on a single line. No JSON encoding.

**Example prompt for a Phase 1 dispatch:**

```
Run doc-audit for doc-id: doc-001, run-id: a3f2b1c9
```

Each subagent's system prompt states "You will be invoked with: `doc-id` and `run-id`" —
this matches the format above.

---

## Subagent Constraint

Only orchestrators may list `Agent` in `tools:`. Claude Code does not permit subagents to spawn
further subagents. Auditors, fixers, and `doc-editor` must not include `Agent` in their
frontmatter tools list.

---

## Allowlist Syntax

Orchestrators use the `Agent(name, ...)` syntax to restrict which agents they may spawn. Bare
`"Agent"` is not used — it permits spawning any agent and provides no guard against accidental
dispatch.

```
# full-audit tools entry:
"Agent(doc-audit, structure-audit, prose-audit, convention-audit, content-audit, discoverability-audit, staleness-audit, health-audit)"

# fix-orchestrator tools entry:
"Agent(doc-fixer, structure-fixer, prose-fixer, convention-fixer, content-fixer, discoverability-fixer, staleness-fixer, health-fixer, doc-editor)"
```

---

## Batching

Orchestrators process documents in fixed-size batches. Within a batch all agents are invoked in
parallel. The next batch does not start until the current batch is fully complete. Batch sizes are
hardcoded in each orchestrator — there is no shared constant mechanism in this plugin.

### Audit pipeline batch sizes

Batch sizes by phase:

| Phase | Docs per batch | Parallel agents per batch | Rationale                                                 |
| ----- | -------------- | ------------------------- | --------------------------------------------------------- |
| 1     | 10             | 10                        | One agent per doc; 10 is safe and fast                    |
| 2     | 5              | 20 (5 × 4 auditors)       | Four auditors per doc; cap total at 20                    |
| 3     | 10             | 30 (10 × 3 auditors)      | Three auditors per doc; mechanical checks are lightweight |

### Fix pipeline batch sizes

Fixer agents use the same batch sizes as their audit-phase counterparts: Phase 1 — 10, Phase 2
— 5, Phase 3 — 10.

`doc-editor` is capped at 10 tasks per gate dispatch. Tasks are already partially sequenced by
`depends_on` in the claim log, but an explicit cap bounds orchestrator context growth for large
fix sets.
