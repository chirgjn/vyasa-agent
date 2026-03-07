# Audit and Fix Pipeline

Reference for the three-phase audit pipeline and the matching fix pipeline. Read this when
working on audit or fix agents, adding a new auditor or fixer, or understanding how the
orchestrators gate between phases. For the framework's placement rules auditors derive their
checks from, see `plugin/framework/managing-project-information.md`.

---

## Design Principles

**Specialisation over breadth.** Each auditor checks one concern type and reads only the guide
governing its domain. This produces actionable findings instead of noise from a monolithic
linter.

**Three-phase gating.** Document validity gates conceptual quality, which gates mechanical
checks. A document in the wrong place shouldn't have its prose audited. The orchestrator applies
judgment at each gate — errors inform but don't mechanically determine decisions.

**File-based handoff.** Agents communicate through structured reports written to
`.vyasa/<run-id>/reports/`. The orchestrator reads these; it never reads project files directly.
This enables parallelism and keeps orchestrator context clean.

**Fixers classify, doc-editor executes.** No agent applies changes autonomously except through
the claim protocol. Fixers produce classifications (`fixable`, `scope`, `reversible`) and
concrete recommendations. The orchestrator routes autonomous fixes to `doc-editor` and escalates
the rest to the user. Nothing runs until it's approved.

**The two-lens principle.** Auditors read the guides (prescriptive — what good looks like), not
`auditing-anti-patterns.md`. That guide is broad but not exhaustive, and complements this
pipeline rather than feeding into it. If a quality criterion exists in a guide but not in
`auditing-anti-patterns.md`, the auditor catches it anyway.

For the reasoning behind each of these principles — what was rejected and why — see
`docs/decisions/`.

---

## Audit Pipeline

### Three phases

The audit runs in three sequential phases, each parallelised within the phase:

| Phase                 | Agents                                                                    | Concern                                          | Parallelism   |
| --------------------- | ------------------------------------------------------------------------- | ------------------------------------------------ | ------------- |
| 1 — Document validity | `doc-audit` × N                                                           | Existence, purpose, placement, filename, outline | One per doc   |
| 2 — Conceptual depth  | `structure-audit`, `prose-audit`, `convention-audit`, `content-audit` × N | Structure, prose, conventions, content placement | Four per doc  |
| 3 — Mechanical checks | `discoverability-audit`, `staleness-audit`, `health-audit` × N            | Routing, broken refs, staleness, file health     | Three per doc |

### Audit data flow

```
full-audit
  │  generates run-id, builds registry, passes both to all agents
  │
  ├── Phase 1 — document validity (parallel, one instance per doc):
  │   └── doc-audit × N     → .vyasa/<run-id>/reports/phase-1/doc-audit/<doc-id>.md
  │
  ├── [Gate 1 — orchestrator judgment per doc]
  │
  ├── Phase 2 — conceptual depth (parallel, informed by Phase 1 context):
  │   ├── structure-audit   → .vyasa/<run-id>/reports/phase-2/structure-audit/<doc-id>.md
  │   ├── prose-audit       → .vyasa/<run-id>/reports/phase-2/prose-audit/<doc-id>.md
  │   ├── convention-audit  → .vyasa/<run-id>/reports/phase-2/convention-audit/<doc-id>.md
  │   └── content-audit     → .vyasa/<run-id>/reports/phase-2/content-audit/<doc-id>.md
  │
  ├── [Gate 2 — orchestrator judgment per doc]
  │
  ├── Phase 3 — mechanical checks (parallel, deterministic):
  │   ├── discoverability-audit → .vyasa/<run-id>/reports/phase-3/discoverability-audit/<doc-id>.md
  │   ├── staleness-audit       → .vyasa/<run-id>/reports/phase-3/staleness-audit/<doc-id>.md
  │   └── health-audit          → .vyasa/<run-id>/reports/phase-3/health-audit/<doc-id>.md
  │
  └── Consolidation: orchestrator reads all reports → severity-ranked report → user
```

### Auditor report format

All auditors use the same two-part structure: finding blocks followed by a phase summary.

**Finding block:**

```
[CHECK N — CHECK NAME]
Severity: Error | Warning | Info
Doc-ID: <doc-id>
Found: One or two sentences — quote the relevant content or heading where useful.
Impact: One sentence on why this matters.
Recommendation: Concrete — name the target location, correct filename, missing section.
```

**Phase summary** (one per report, at the end):

```
PHASE SUMMARY
Doc-ID: <doc-id>
Phase: <1 | 2 | 3> — <auditor name>
Findings: <N errors, N warnings, N info>
Context: <One sentence for the next phase. Omit if no findings.>
```

A report missing its `PHASE SUMMARY` block is treated as an agent failure — the document is
excluded from further phases and surfaced in the consolidation report under `Agent failure`.

### Gate logic

The orchestrator reads phase summaries and decides per document. Errors inform but don't
mechanically determine the decision. The orchestrator may proceed through a gate with errors
present if doing so provides useful additional context.

- **After Phase 1:** Proceed / Proceed with context / Skip Phase 2+3 / Agent failure
- **After Phase 2:** Proceed to Phase 3 / Skip / Agent failure

When Phase 1 produced a `Context` line, the orchestrator synthesises a targeted briefing per
Phase 2 agent — distilling the signal relevant to that agent, not passing the context verbatim.

### Auditor guide map

Each auditor reads exactly one guide and checks the concerns that guide governs:

| Auditor                 | Reads                                                                                                          | Checks                                                                                    |
| ----------------------- | -------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `doc-audit`             | `managing-project-information.md`, `writing-reference-docs.md`, `writing-agents-md.md`, `writing-layout-md.md` | Existence rationale, purpose clarity, placement, filename, outline, framework compliance  |
| `structure-audit`       | `writing-reference-docs.md`                                                                                    | Scoped opening, when-before-how ordering, task orientation, example coverage              |
| `prose-audit`           | `writing-prose-style.md`                                                                                       | Voice, contractions, table intros, list parallelism, sentence structure, terminology      |
| `convention-audit`      | `writing-conventions.md`                                                                                       | Phrasing pattern (what+where+NOT), linter-enforceable rules, aspirational conventions     |
| `content-audit`         | `managing-project-information.md`                                                                              | Verbatim duplication >3 lines, semantic duplication, misplaced passages, convention drift |
| `discoverability-audit` | `writing-agents-md.md`                                                                                         | Routing table coverage, 2-hop reachability, broken internal references                    |
| `staleness-audit`       | `plugin/framework/guides/staleness.md`                                                                         | Broken paths, missing scripts, aspirational conventions, diagram accuracy, ADR status     |
| `health-audit`          | `writing-reference-docs.md`                                                                                    | File sizing (thin \<15 lines, bloated >200 lines), README quality                         |

---

## Constraints

Rules the pipeline must uphold that tooling can't enforce:

**Only orchestrators may spawn subagents.** Auditors, fixers, and `doc-editor` must not
include `Agent` in their `tools:` list. This keeps the dispatch graph flat and prevents
runaway agent chains. See ADR 001 for the phasing rationale and `docs/specs/pipeline-dispatch.md`
for the allowlist syntax.

**Only `doc-editor` may edit project files.** Auditors and fixers produce reports and
classifications; they never write to the project. This ensures every edit is approved,
claimed, and reversible. See ADR 003.

**The claim protocol is not optional.** Before editing any document, `doc-editor` must
claim it. A conflict on `confirm` is an orchestrator bug and must fail loudly — not be
retried or silently skipped. See ADR 005 and ADR 007.

**Orchestrators never read project files directly.** They read only the registry and
report files under `.vyasa/<run-id>/`. This keeps orchestrator context clean and enables
parallelism. See ADR 002.

---

## Fix Pipeline

### Structure

Fix phases mirror audit phases. Each doc enters at the phase with its earliest findings — no
Phase 1 findings means `doc-fixer` is skipped entirely. Phase 1 fixes complete before Phase 2
fixers run on the same doc, because Phase 1 problems (wrong location, wrong purpose) change
what Phase 2 checks are relevant.

### Fix data flow

```
fix-orchestrator
  │  auto-discovers run, builds findings index
  │
  ├── Phase 1 fixers (parallel):
  │   └── doc-fixer × N       → .vyasa/<run-id>/reports/phase-1/doc-fixer/<doc-id>.md
  │
  ├── [Gate 1 — route autonomous fixes to doc-editor, escalate rest to user]
  │   └── update registry current_path for approved renames/moves
  │
  ├── Phase 2 fixers (parallel):
  │   ├── structure-fixer     → .vyasa/<run-id>/reports/phase-2/structure-fixer/<doc-id>.md
  │   ├── prose-fixer         → .vyasa/<run-id>/reports/phase-2/prose-fixer/<doc-id>.md
  │   ├── convention-fixer    → .vyasa/<run-id>/reports/phase-2/convention-fixer/<doc-id>.md
  │   └── content-fixer       → .vyasa/<run-id>/reports/phase-2/content-fixer/<doc-id>.md
  │
  ├── [Gate 2 — same routing]
  │
  ├── Phase 3 fixers (parallel):
  │   ├── discoverability-fixer → .vyasa/<run-id>/reports/phase-3/discoverability-fixer/<doc-id>.md
  │   ├── staleness-fixer       → .vyasa/<run-id>/reports/phase-3/staleness-fixer/<doc-id>.md
  │   └── health-fixer          → .vyasa/<run-id>/reports/phase-3/health-fixer/<doc-id>.md
  │
  └── [Gate 3 — dispatch doc-editor instances in parallel for all autonomous tasks]
```

### Fixer classification contract

Each fixer classifies every finding:

| Field        | Values                               | Meaning                                    |
| ------------ | ------------------------------------ | ------------------------------------------ |
| `fixable`    | `yes` / `no`                         | Can this be resolved without user input?   |
| `scope`      | `file` / `multi-file` / `structural` | How many files the fix touches             |
| `reversible` | `yes` / `no`                         | Can it be undone with a single git revert? |

**Routing rule:** `fixable: yes` + `scope: file or multi-file` + `reversible: yes` → autonomous,
queued for `doc-editor`. Anything else → escalated to user.

### Fixer report format

All fixers use the same block structure:

```
FINDING: <check number and name from audit report>
Doc-ID: <doc-id>
Audit severity: Error | Warning | Info
Summary: One sentence restating the finding.

Classification:
  fixable: yes | no
  scope: file | multi-file | structural
  reversible: yes | no

Recommendation:
  If fixable: yes — concrete instructions for doc-editor (exact text, target path).
  If fixable: no — user-facing escalation (what the problem is, options, reversibility).

Next-phase wait: yes | no
  If yes: what the next phase must wait for and why.
```

Phase 3 fixers always write `Next-phase wait: no`.

After all findings, a **fixer summary**:

```
FIXER SUMMARY
Doc-ID: <doc-id>
Autonomous fixes: <N>
  <One line per fix>
Escalations: <N>
  <One line per escalation>
Next-phase blocked until: <fix names or "nothing blocking">
```

### Phase 2 classification baselines

These are defaults — fixer agents override with judgment when the specific case changes the
classification.

**`prose-fixer`:** All findings are autonomous — prose edits are file-scoped and reversible.

| Finding                      | fixable | scope | reversible |
| ---------------------------- | ------- | ----- | ---------- |
| Missing table intro sentence | yes     | file  | yes        |
| Sentence fragment            | yes     | file  | yes        |
| Passive voice                | yes     | file  | yes        |
| Missing contraction          | yes     | file  | yes        |
| Non-parallel list items      | yes     | file  | yes        |

**`structure-fixer`:**

| Finding                                   | fixable | scope | reversible |
| ----------------------------------------- | ------- | ----- | ---------- |
| Missing or malformed scoped opening       | yes     | file  | yes        |
| When-before-how ordering violated         | yes     | file  | yes        |
| Missing example section                   | yes     | file  | yes        |
| Missing prerequisite/consequences section | yes     | file  | yes        |
| Major task-oriented restructure           | no      | —     | —          |

**`convention-fixer`:**

| Finding                                        | fixable | scope | reversible |
| ---------------------------------------------- | ------- | ----- | ---------- |
| Convention missing negative constraint         | yes     | file  | yes        |
| Tool-generic rule                              | yes     | file  | yes        |
| Linter-enforceable — linter already configured | yes     | file  | yes        |
| Linter-enforceable — linter not yet configured | no      | —     | —          |
| Aspirational convention                        | no      | —     | —          |

**`content-fixer`:**

| Finding                                       | fixable | scope      | reversible |
| --------------------------------------------- | ------- | ---------- | ---------- |
| Verbatim duplication >3 lines                 | yes     | multi-file | yes        |
| Semantic duplication                          | no      | —          | —          |
| Misplaced passage — target file exists        | yes     | multi-file | yes        |
| Misplaced passage — target file doesn't exist | no      | —          | —          |
| Convention drift                              | no      | —          | —          |

---

## Infrastructure

### Run ID and registry

Each audit run generates a unique 8-character hex run ID via
`plugin/scripts/generate-run-id.sh`, which uses `openssl` if available and falls back to
`/dev/urandom`:

```bash
run_id=$(bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-run-id.sh)
```

The registry maps stable `doc-id` values to file paths:

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

`current_path` is updated by the orchestrator at each fix gate when a fixer recommends a rename
or move. Agents always read `current_path`. The registry is orchestrator-owned and only written
between phases.

**Registry integrity check:** After writing, the orchestrator re-reads and parses. If the parse
fails (truncated write, empty file), it aborts, deletes the run directory, and reports the error.

The registry is built by `plugin/scripts/build-registry.sh`. Phase summaries are extracted by
`plugin/scripts/parse-phase-summary.sh`.

### Filesystem layout

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

### Claim protocol

Before editing any document, `doc-editor` must claim it via `plugin/scripts/vyasa-claim.sh`.
The claim log (`.vyasa/<run-id>/changes.log`) is append-only JSONL.

```bash
vyasa-claim.sh claim   <run-id> <agent> <doc-id> [<doc-id> ...]  # register intent
vyasa-claim.sh confirm <run-id> <agent> <doc-id> [<doc-id> ...]  # verify uncontested (exit 1 = conflict)
vyasa-claim.sh commit  <run-id> <agent> <doc-id> [<doc-id> ...]  # record completion
vyasa-claim.sh release <run-id> <agent> <doc-id> [<doc-id> ...]  # release on abort
```

For multi-file tasks, `doc-editor` claims all files in one step before editing any.

The `confirm` step scans the log for a second `claim` on the same `doc-id` from a different
agent. A conflict indicates an orchestrator bug and fails loudly — not retried.

Auditors and fixers never claim. Only `doc-editor` claims.

### Task structure

The orchestrator writes each task file before dispatching `doc-editor`:

```json
{
  "id": "task-003",
  "doc-ids": ["doc-002"],
  "finding": "phase-1 / doc-audit / Warning — wrong filename",
  "change": "Rename docs/ErrorHandling_v2.md to docs/error-handling.md. Update the routing table entry in AGENTS.md.",
  "depends_on": []
}
```

`doc-editor` receives only `task-id` and `run-id` and reads the task file itself.

---

## Agent Inventory

All agents ship in `plugin/agents/`:

| Agent                    | Category       | Trigger / Phase              | Role                                                                             |
| ------------------------ | -------------- | ---------------------------- | -------------------------------------------------------------------------------- |
| `full-audit`             | Orchestrator   | User invoked                 | Generates run-id, builds registry, dispatches audit phases, gates, consolidates  |
| `fix-orchestrator`       | Orchestrator   | User invoked                 | Reads audit report, dispatches fix phases, gates, routes autonomous/escalations  |
| `doc-editor`             | Scribe         | Dispatched by orchestrator   | Receives task-id and run-id, claims files, applies one approved change           |
| `doc-maintenance`        | Maintenance    | Dispatched by hook           | Checks docs for staleness after a commit changes source files                    |
| `doc-audit`              | Auditor        | Phase 1 — validity           | Existence rationale, purpose clarity, placement, filename, outline               |
| `structure-audit`        | Auditor        | Phase 2 — conceptual         | Scoped opening, when-before-how ordering, task orientation, example coverage     |
| `prose-audit`            | Auditor        | Phase 2 — conceptual         | Voice, contractions, table intros, list parallelism, sentence structure          |
| `convention-audit`       | Auditor        | Phase 2 — conceptual         | Convention phrasing, negative constraints, linter-enforceable rules              |
| `content-audit`          | Auditor        | Phase 2 — conceptual         | Verbatim duplication, semantic duplication, misplaced passages, convention drift |
| `discoverability-audit`  | Auditor        | Phase 3 — mechanical         | Routing table coverage, 2-hop reachability, broken internal references           |
| `staleness-audit`        | Auditor        | Phase 3 — mechanical         | Broken paths, missing scripts, aspirational conventions, diagram accuracy        |
| `health-audit`           | Auditor        | Phase 3 — mechanical         | File sizing (thin <15 lines, bloated >200 lines), README quality                 |
| `doc-fixer`              | Fixer          | Phase 1 — validity           | Classifies and recommends fixes for `doc-audit` findings                         |
| `structure-fixer`        | Fixer          | Phase 2 — conceptual         | Classifies and recommends fixes for `structure-audit` findings                   |
| `prose-fixer`            | Fixer          | Phase 2 — conceptual         | Classifies and recommends fixes for `prose-audit` findings                       |
| `convention-fixer`       | Fixer          | Phase 2 — conceptual         | Classifies and recommends fixes for `convention-audit` findings                  |
| `content-fixer`          | Fixer          | Phase 2 — conceptual         | Classifies and recommends fixes for `content-audit` findings                     |
| `discoverability-fixer`  | Fixer          | Phase 3 — mechanical         | Classifies and recommends fixes for `discoverability-audit` findings             |
| `staleness-fixer`        | Fixer          | Phase 3 — mechanical         | Classifies and recommends fixes for `staleness-audit` findings                   |
| `health-fixer`           | Fixer          | Phase 3 — mechanical         | Classifies and recommends fixes for `health-audit` findings                      |
| `agents-md-lint`         | Hook-triggered | PostToolUse on AGENTS.md     | Validates AGENTS.md structure and conventions on every write                     |
| `diagram-lint`           | Hook-triggered | PostToolUse on diagram files | Validates diagram syntax and structure on every write                            |
| `author-agents-md`       | Authoring      | User invoked                 | Generates or rewrites a complete AGENTS.md from codebase analysis                |
| `author-decision-record` | Authoring      | User invoked                 | Creates ADRs and design docs following the vyasa decision record format          |
| `author-reference-doc`   | Authoring      | User invoked                 | Creates well-structured reference docs and updates the routing table             |
| `author-diagram`         | Authoring      | User invoked or dispatched   | Creates or updates diagrams; validates Mermaid syntax                            |
