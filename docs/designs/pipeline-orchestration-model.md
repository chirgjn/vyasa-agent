# Pipeline Orchestration Model Design

**Status:** Under Review
**Date:** 2026-03-08
**Author:** Engineering

The audit and fix pipelines need context isolation, specialised workers, and parallelism —
requirements the current agent-based model cannot satisfy: subagents cannot spawn other
subagents in Claude Code.

---

## Problem

The audit pipeline (`full-audit`) and fix pipeline (`fix-orchestrator`) are implemented as
subagents that dispatch worker subagents in parallel. This model fails at runtime: Claude
Code does not allow subagents to spawn other subagents. When `full-audit` runs as a
subagent and attempts to dispatch `doc-audit × N`, the spawning is silently misrouted —
Claude attempts to invoke workers as skills instead, which also fails because no matching
skills exist.

The spawning failure is not the only problem. The current model also fails on three
requirements that any viable replacement must satisfy:

1. **Context isolation between the main conversation and the pipeline.** The audit
   pipeline reads many documents, runs many checks, and produces verbose intermediate
   state. This must not accumulate in the user's main conversation context.

2. **Context isolation between workers.** A `doc-audit` instance checking `setup.md`
   should not see findings from the `doc-audit` instance checking `api.md`. Cross-worker
   noise degrades output quality and wastes tokens.

3. **Token efficiency.** Specialised workers should carry only the context relevant to
   their task. An auditor checking prose style does not need the full taxonomy guide; a
   validity checker does not need the prose style guide. Loading everything into every
   worker is expensive and degrades reasoning.

The constraint is that Claude Code's subagent model is a strict two-level hierarchy: the
main thread can spawn subagents; subagents cannot spawn further subagents. Any
orchestration pattern that requires a third level breaks.

---

## Alternatives considered

### Option A: Main-thread orchestration with forked worker skills

Convert all workers to skills with `context: fork`. The orchestrator runs inline in the
main conversation — it is a plain (non-forked) skill that the user invokes. The main
thread uses `TaskCreate` for parallel worker invocations. Each forked skill runs in
isolation.

**Pros:**

- Parallelism works natively via `TaskCreate` in the main thread
- Workers are fully isolated — each forked skill has its own context window
- `${CLAUDE_SKILL_DIR}` resolves paths natively; no injection script needed
- No spawning constraint — the main thread is not a subagent

**Cons:**

- The orchestrator accumulates context across all three phases in the main conversation.
  Phase 1 reads N reports, Phase 2 reads 4×N reports, Phase 3 reads 3×N reports — all in
  the same context window
- The user's main conversation is polluted with pipeline state for the duration of the run
- No resumability — if the orchestrator is interrupted mid-pipeline, there is no clean
  recovery path without manual intervention

### Option B: Forked orchestrator with file-based spawn handoff

The orchestrator runs as a `context: fork` skill (isolated subagent). Workers are also
forked skills. Since the orchestrator cannot spawn workers directly, it writes a
structured spawn-request file to disk and exits. The main thread reads the file, spawns
the requested workers in parallel, collects their results, and re-invokes the orchestrator
with a resume signal. The orchestrator reads its checkpoint file and continues from the
last gate.

**Pros:**

- Orchestrator context is fully isolated from the main conversation — the user sees only
  final results
- Workers are isolated from each other and from the orchestrator
- File-based checkpointing gives crash recovery: if the orchestrator is interrupted at any
  gate, the main thread can re-invoke it and it resumes from the last written checkpoint
- If re-invoked, a new orchestrator instance picks up from the checkpoint — no state is
  lost
- The main thread acts as a dumb spawner with no domain knowledge; all pipeline logic
  stays in the orchestrator

**Cons:**

- Each phase gate requires a round-trip: orchestrator exits → main thread spawns workers
  → main thread re-invokes orchestrator. Three phases means at minimum six
  main-thread interactions (spawn-request + resume per phase). The user sees the main
  conversation pause and re-activate multiple times mid-run, which is visibly jarring
- The main thread must parse a structured spawn-request file correctly; a malformed or
  missing file stalls the pipeline with no automatic recovery
- More moving parts: checkpoint files, spawn-request files, resume signals, re-invocation
  logic — more surface area for subtle bugs

### Option C: Subagent-as-orchestrator with direct skill dispatch (rejected during design)

The orchestrator is a subagent that dispatches workers by invoking skills via the Skill
tool. Forked skills are themselves subagents — so this is subagent spawning subagent.
Rejected immediately: Claude Code does not permit this. Included for completeness because
it was the original implementation intent.

---

## Recommendation

**Recommended: Option B — forked orchestrator with file-based spawn handoff**

Option A keeps the orchestrator in the main conversation, which defeats the context
isolation goal. As the pipeline processes more documents, the main thread accumulates all
phase reports, gate decisions, and briefings. This is precisely the problem we are solving.

Option B isolates the orchestrator and preserves all three requirements. The round-trip
cost is real but bounded — three phases means a fixed number of handoffs regardless of
document count. The main thread acts as a thin relay: it reads a spawn-request, invokes
the workers, and re-invokes the orchestrator. No pipeline logic lives in the main thread.

Option A is operationally simpler — no spawn-request files, no resume signals, no
re-invocation logic. If context isolation were not a requirement, Option A would be the
right choice. It is not the right choice here.

The file-based checkpoint is a genuine advantage over Option A: interrupted pipelines are
recoverable without re-running from scratch. Given that the audit pipeline can run for
several minutes across a large doc set, this matters operationally.

The deciding factor over Option A is the context isolation requirement. The orchestrator's
context window must not grow into the main conversation. Option B achieves this; Option A
does not.

---

## Design: Option B in detail

### Component model

```mermaid
flowchart TD
    user["User: 'audit my docs'"]
    relay["vyasa:full-audit relay skill\n(context: inherit)\nMain-thread loop driver"]
    orch["full-audit skill\n(context: fork)\nOrchestrator"]
    workers["Worker skills\n(context: fork)\nOne per doc/check"]
    disk[".vyasa/<run-id>/\nReports, checkpoint,\nspawn-request"]

    user -->|invokes| relay
    relay -->|invokes| orch
    orch -->|writes spawn-request| disk
    orch -->|exits: SPAWN_READY signal| relay
    relay -->|spawns in parallel via TaskCreate| workers
    workers -->|write reports| disk
    relay -->|re-invokes with resume signal| orch
    orch -->|reads reports + checkpoint| disk
    orch -->|exits with final report| relay
    relay -->|presents| user
```

### Skill types

| Role                                                   | Type                     | Isolation                                  | Path resolution       |
| ------------------------------------------------------ | ------------------------ | ------------------------------------------ | --------------------- |
| `full-audit` relay                                     | `context: inherit` skill | Runs in main conversation; drives the loop | n/a                   |
| `full-audit` orchestrator                              | `context: fork` skill    | Isolated from main conversation            | `${CLAUDE_SKILL_DIR}` |
| `fix-orchestrator`                                     | `context: fork` skill    | Isolated from main conversation            | `${CLAUDE_SKILL_DIR}` |
| Worker auditors (`doc-audit`, `structure-audit`, etc.) | `context: fork` skills   | Isolated from each other and orchestrator  | `${CLAUDE_SKILL_DIR}` |
| Worker fixers (`doc-fixer`, `structure-fixer`, etc.)   | `context: fork` skills   | Isolated from each other and orchestrator  | `${CLAUDE_SKILL_DIR}` |

All agents become skills. No agent files remain.

### Spawn-request protocol

When the orchestrator needs workers spawned, it writes a spawn-request file before exiting:

```
.vyasa/<run-id>/spawn-request.json
```

```json
{
  "resume_after": "phase-1",
  "workers": [
    { "skill": "doc-audit", "args": "doc-id=doc-001 run-id=<run-id>" },
    { "skill": "doc-audit", "args": "doc-id=doc-002 run-id=<run-id>" }
  ]
}
```

When the orchestrator exits, it outputs a structured signal on its last line:

```
SPAWN_READY run-id=<run-id> phase=<N>
```

The relay skill watches for this signal. On seeing it, the relay reads
`.vyasa/<run-id>/spawn-request.json`, spawns all listed workers in parallel via
`TaskCreate`, waits for all tasks to complete, then re-invokes the orchestrator:

```
/vyasa:full-audit resume run-id=<run-id>
```

The orchestrator reads its checkpoint, skips completed phases, and continues.

### Checkpoint protocol

The orchestrator writes a checkpoint after each gate decision:

```
.vyasa/<run-id>/checkpoint.json
```

```json
{
  "run-id": "<run-id>",
  "phase_completed": 1,
  "gate_1_decisions": { "doc-001": "proceed", "doc-002": "skip" },
  "phase_2_list": ["doc-001"]
}
```

On resume, the orchestrator reads the checkpoint and continues from `phase_completed + 1`.
If the checkpoint is absent or malformed, the orchestrator restarts from Phase 1.

### Features retained from agent model

| Feature                               | Agent model                                                        | Skill model                                                                                                                                                |
| ------------------------------------- | ------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Context isolation (main conversation) | No — orchestrator runs as subagent in main thread if invoked wrong | Yes — `context: fork`                                                                                                                                      |
| Context isolation (between workers)   | Yes                                                                | Yes — each forked skill isolated                                                                                                                           |
| Parallelism                           | Broken — subagents can't spawn subagents                           | Yes — main thread uses `TaskCreate`                                                                                                                        |
| Path resolution                       | Broken — `CLAUDE_PLUGIN_ROOT` not available in agent prompts       | Yes — `${CLAUDE_SKILL_DIR}`                                                                                                                                |
| Resumability                          | No                                                                 | Yes — checkpoint file                                                                                                                                      |
| `color` per worker                    | Yes                                                                | No                                                                                                                                                         |
| `model` per worker                    | Yes (`opus` for orchestrators)                                     | Not enforceable — `model:` frontmatter field exists in the skill spec but is not respected at runtime by Claude Code; all skills inherit the session model |
| `tools` restriction per worker        | Yes                                                                | Via `allowed-tools` frontmatter                                                                                                                            |

`color` is lost. `model` per worker is not enforceable — the `model:` frontmatter field
exists in the skill spec but Claude Code does not respect it at runtime; all skills use
whatever model the session is running on. The relay skill warns the user at startup that
the pipeline is designed for Sonnet medium/high thinking and that results will degrade on
lower models. `tools` restrictions are preserved via `allowed-tools`.

### Design decisions

#### Relay skill placement: where does the loop logic live?

Three options were considered for where to put the logic that drives the
orchestrator-spawn-resume loop:

**Option 1: Raw main conversation (no relay skill).** The user invokes the orchestrator
directly, and the main conversation Claude reads the `SPAWN_READY` signal and acts on it
without any skill driving the loop. Rejected: the main conversation has no guaranteed
instructions for parsing the signal or driving the loop correctly. Behaviour would depend
on whatever is in the session context, making it fragile and non-reproducible.

**Option 2: Relay agent (context: fork).** A forked subagent drives the loop. Rejected
immediately: `TaskCreate` is only available from the main conversation context. A forked
subagent cannot call `TaskCreate`, so it cannot dispatch workers in parallel.

**Option 3: Relay skill (context: inherit) — chosen.** A non-forked skill runs in the
main conversation, carrying explicit loop instructions. It can call `TaskCreate` because
it runs in the main thread. All pipeline logic stays in the skill, not in the ambient
conversation context. Reproducible and self-contained.

#### Exit signal format: how does the relay know to act?

Two options were considered for how the orchestrator signals the relay that workers need
spawning:

**Option 1: Prose output.** The orchestrator exits with human-readable prose ("The phase
1 workers are ready. Please invoke them now.") and the relay interprets it. Rejected: prose
is ambiguous and interpretation is unreliable. Edge cases in wording could cause the relay
to miss the signal or act on it incorrectly.

**Option 2: Structured token — chosen.** The orchestrator outputs `SPAWN_READY
run-id=<run-id> phase=<N>` as its last line. The relay pattern-matches on this token.
Unambiguous, machine-readable, and easy to specify exhaustively in the spec.

#### Model handling: what to do when the user is not on the expected model?

Three options were considered, given that `model:` frontmatter is not enforced at runtime
by Claude Code (all skills inherit the session model regardless of what is specified):

**Option 1: Hard block.** The relay refuses to proceed if the user is not on Sonnet
medium/high. Rejected: Claude Code provides no reliable programmatic way to detect the
active model from within a skill, making enforcement impossible in practice.

**Option 2: Silent accept.** Make no mention of model expectations. Rejected: users on
weaker models will get degraded results with no explanation, leading to confusion about
pipeline quality.

**Option 3: Startup warning — chosen.** The relay skill warns the user at invocation time
that the pipeline is designed for Sonnet medium/high thinking and that results will degrade
on lower models. No enforcement; the user decides. Honest about the limitation without
being a hard blocker.

### Agent-to-skill migration

All 26 agent files in `plugin/agents/` are converted to skills in `plugin/skills/`. The
`@@VYASA_ROOT@@` template placeholder and `inject-vyasa-root.sh` are removed — replaced by
`${CLAUDE_SKILL_DIR}` which resolves natively. The `SessionStart` hook context message is
updated to reflect skill invocation.

---

## Open questions

- ~~**How does the main thread know to read `spawn-request.json`?** The orchestrator must
  communicate this in its exit output. The exact prose the orchestrator should output to
  prompt the main thread to act needs to be specified. The format is TBD — to be defined
  in the spec.~~ _Resolved: the orchestrator exits with a structured `SPAWN_READY
run-id=<run-id> phase=<N>` signal on its last line. The relay skill watches for this
  signal and drives the loop. Exact format to be exhaustively specified in the spec._

- ~~**What model do workers use?** With `model: inherit`, workers use whatever model the
  user is running. For `full-audit` this was previously `opus`. Do we need to enforce
  `opus` for the orchestrator via frontmatter, or is `inherit` acceptable? _Open — needs
  user decision._~~ _Resolved: `model:` frontmatter is not enforced at runtime by Claude
  Code; all skills inherit the session model regardless. No enforcement is possible. The
  relay skill warns the user at startup that the pipeline is designed for Sonnet
  medium/high thinking and that results will degrade on lower models._

- ~~**Parallel skill invocation from main thread** — does `TaskCreate` work for forked
  skills invoked from the main thread, or only for background tasks? _Needs verification
  against Claude Code docs._~~ _Resolved: `TaskCreate` is the only parallelism mechanism
  available in Claude Code. It is used from the relay skill (main conversation context)
  to dispatch forked worker skills in parallel._

---

## Out of scope

- The fix pipeline (`fix-orchestrator`, `doc-editor`, fixers) — same pattern applies but
  migration is a separate implementation task
- The `author-*` and `agents-md-lint` standalone skills — not part of the pipeline, not
  affected by this change
- The `inject-vyasa-root.sh` mechanism and ADR 012 — superseded by this design if
  approved; cleanup is part of implementation
- Per-worker model selection — accepted loss; not addressed in this design

---

## Extracted artifacts

_Populated after approval._
