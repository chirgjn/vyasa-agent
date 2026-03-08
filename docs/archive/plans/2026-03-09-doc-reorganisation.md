# Doc Reorganisation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Move `python-type-annotations.md` to `docs/guides/`, split `docs/audit-pipeline.md` into an architecture doc plus two new Live specs, and update all references.

**Architecture:** Three parallel streams of work — the Python guide move (trivial), the spec extractions from `audit-pipeline.md` (content surgery), and the reference updates (AGENTS.md, layout.md, specs index, decisions index, maintenance.md). Each stream produces a commit. The architecture doc (`audit-pipeline.md`) is rewritten in place: spec-level detail is removed and replaced with links to the new specs.

**Tech Stack:** Markdown only. No code changes. Formatting via `scripts/tools/prettier-fix.sh`.

---

### Task 1: Move `python-type-annotations.md` to `docs/guides/`

**Files:**

- Move (copy + delete): `docs/python-type-annotations.md` → `docs/guides/python-type-annotations.md`

`docs/guides/` doesn't exist yet — create it by writing the file there. The content is unchanged.

**Step 1: Read the file**

Read `docs/python-type-annotations.md` to confirm current content before moving.

**Step 2: Write to new location**

Write the file verbatim to `docs/guides/python-type-annotations.md`.

**Step 3: Delete the old file**

```bash
git rm docs/python-type-annotations.md
```

**Step 4: Run prettier**

```bash
scripts/tools/prettier-fix.sh docs/guides/python-type-annotations.md
```

Expected: no changes (file was already formatted).

**Step 5: Stage and verify**

```bash
git status
```

Expected: `docs/guides/python-type-annotations.md` new file, `docs/python-type-annotations.md` deleted.

**Step 6: Commit**

```bash
git add docs/guides/python-type-annotations.md docs/python-type-annotations.md
git commit -m "docs: move python-type-annotations to docs/guides/"
```

---

### Task 2: Create `docs/specs/live/audit-report-format.md`

Extract the auditor/fixer report format and fixer classification contract from `docs/audit-pipeline.md` into a new Live spec.

**Files:**

- Create: `docs/specs/live/audit-report-format.md`

**Step 1: Write the spec**

Create `docs/specs/live/audit-report-format.md` with this content:

```markdown
# Audit Report Format Spec

**Status:** Live
**Date:** 2026-03-09

Exhaustive description of the report formats all auditors and fixers must produce. Read this
before implementing or modifying any auditor, fixer, or orchestrator that reads their output.
For pipeline architecture — phases, agents, gates, data flow — see `docs/audit-pipeline.md`.
For the decisions behind the classification contract, see ADR 003 (`docs/decisions/`).

---

## Auditor Report Format

All auditors produce a report consisting of one finding block per finding, followed by a
single phase summary.

### Finding block
```

[CHECK N — CHECK NAME]
Severity: Error | Warning | Info
Doc-ID: <doc-id>
Found: One or two sentences — quote the relevant content or heading where useful.
Impact: One sentence on why this matters.
Recommendation: Concrete — name the target location, correct filename, missing section.

```

### Phase summary

One per report, at the end:

```

PHASE SUMMARY
Doc-ID: <doc-id>
Phase: <1 | 2 | 3> — <auditor name>
Findings: <N errors, N warnings, N info>
Context: <One sentence for the next phase. Omit if no findings.>

```

A report missing its `PHASE SUMMARY` block is treated as an agent failure — the document is
excluded from further phases and surfaced in the consolidation report under `Agent failure`.

---

## Fixer Report Format

All fixers produce one finding block per finding, followed by a fixer summary.

### Finding block

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

### Fixer summary

After all finding blocks:

```

FIXER SUMMARY
Doc-ID: <doc-id>
Autonomous fixes: <N>
<One line per fix>
Escalations: <N>
<One line per escalation>
Next-phase blocked until: <fix names or "nothing blocking">

```

---

## Fixer Classification Contract

Each fixer classifies every finding across three fields. See ADR 003 for why fixers classify
rather than apply changes directly.

| Field        | Values                               | Meaning                                    |
| ------------ | ------------------------------------ | ------------------------------------------ |
| `fixable`    | `yes` / `no`                         | Can this be resolved without user input?   |
| `scope`      | `file` / `multi-file` / `structural` | How many files the fix touches             |
| `reversible` | `yes` / `no`                         | Can it be undone with a single git revert? |

**Routing rule:** `fixable: yes` + `scope: file or multi-file` + `reversible: yes` →
autonomous, queued for `doc-editor`. Anything else → escalated to user.

---

## Phase 2 Classification Baselines

Defaults — fixer agents override with judgment when the specific case changes the
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
```

**Step 2: Run prettier**

```bash
scripts/tools/prettier-fix.sh docs/specs/live/audit-report-format.md
```

**Step 3: Commit**

```bash
git add docs/specs/live/audit-report-format.md
git commit -m "docs: extract audit-report-format spec from audit-pipeline.md"
```

---

### Task 3: Create `docs/specs/live/run-infrastructure.md`

Extract the run infrastructure detail (run ID, registry, filesystem layout, claim protocol, task structure) from `docs/audit-pipeline.md` into a new Live spec.

**Files:**

- Create: `docs/specs/live/run-infrastructure.md`

**Step 1: Write the spec**

Create `docs/specs/live/run-infrastructure.md` with this content:

````markdown
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
````

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

````

**Step 2: Run prettier**

```bash
scripts/tools/prettier-fix.sh docs/specs/live/run-infrastructure.md
````

**Step 3: Commit**

```bash
git add docs/specs/live/run-infrastructure.md
git commit -m "docs: extract run-infrastructure spec from audit-pipeline.md"
```

---

### Task 4: Rewrite `docs/audit-pipeline.md` as an architecture doc

Remove all spec-level detail (report formats, fixer classification contract, classification baselines, claim protocol, run ID, registry, filesystem layout, task structure) and replace with links to the new specs. Keep: design principles, phase table, audit data flow, gate logic, auditor guide map, constraints, fix pipeline structure + data flow, agent inventory.

**Files:**

- Modify: `docs/audit-pipeline.md`

**Step 1: Read the current file**

Read `docs/audit-pipeline.md` in full to confirm you have the latest content.

**Step 2: Rewrite the file**

Overwrite `docs/audit-pipeline.md` with the architecture doc version below. Key structural changes:

- Opening line updated: "architecture doc" → reads "architecture and pipeline reference"
- "Auditor report format" section: replace block with one-line link to spec
- "Gate logic" section: keep (it's architecture-level orchestrator behaviour)
- "Fix pipeline" → keep "Structure" and "Fix data flow"; remove "Fixer classification contract", "Fixer report format", "Phase 2 classification baselines" — replace with link
- "Infrastructure" section: remove entirely, replace with link to run-infrastructure spec

The rewritten file:

```markdown
# Audit and Fix Pipeline

Architecture reference for the three-phase audit pipeline and the matching fix pipeline. Read
this when working on audit or fix agents, adding a new auditor or fixer, or understanding how
the orchestrators gate between phases. For exact report formats and fixer classification
contracts, see `docs/specs/live/audit-report-format.md`. For run infrastructure — registry,
claim protocol, filesystem layout — see `docs/specs/live/run-infrastructure.md`. For dispatch
mechanics, see `docs/specs/pipeline-dispatch.md`. For the framework's placement rules
auditors derive their checks from, see
`plugin/framework/managing-project-information.md`.

---

## Design Principles

**Specialisation over breadth.** Each auditor checks one concern type and reads only the
guide governing its domain. This produces actionable findings instead of noise from a
monolithic linter.

**Three-phase gating.** Document validity gates conceptual quality, which gates mechanical
checks. A document in the wrong place shouldn't have its prose audited. The orchestrator
applies judgment at each gate — errors inform but don't mechanically determine decisions.

**File-based handoff.** Agents communicate through structured reports written to
`.vyasa/<run-id>/reports/`. The orchestrator reads these; it never reads project files
directly. This enables parallelism and keeps orchestrator context clean.

**Fixers classify, doc-editor executes.** No agent applies changes autonomously except
through the claim protocol. Fixers produce classifications (`fixable`, `scope`,
`reversible`) and concrete recommendations. The orchestrator routes autonomous fixes to
`doc-editor` and escalates the rest to the user. Nothing runs until it's approved.

**The two-lens principle.** Auditors read the guides (prescriptive — what good looks like),
not `auditing-anti-patterns.md`. That guide is broad but not exhaustive, and complements
this pipeline rather than feeding into it. If a quality criterion exists in a guide but not
in `auditing-anti-patterns.md`, the auditor catches it anyway.

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
│ generates run-id, builds registry, passes both to all agents
│
├── Phase 1 — document validity (parallel, one instance per doc):
│ └── doc-audit × N → .vyasa/<run-id>/reports/phase-1/doc-audit/<doc-id>.md
│
├── [Gate 1 — orchestrator judgment per doc]
│
├── Phase 2 — conceptual depth (parallel, informed by Phase 1 context):
│ ├── structure-audit → .vyasa/<run-id>/reports/phase-2/structure-audit/<doc-id>.md
│ ├── prose-audit → .vyasa/<run-id>/reports/phase-2/prose-audit/<doc-id>.md
│ ├── convention-audit → .vyasa/<run-id>/reports/phase-2/convention-audit/<doc-id>.md
│ └── content-audit → .vyasa/<run-id>/reports/phase-2/content-audit/<doc-id>.md
│
├── [Gate 2 — orchestrator judgment per doc]
│
├── Phase 3 — mechanical checks (parallel, deterministic):
│ ├── discoverability-audit → .vyasa/<run-id>/reports/phase-3/discoverability-audit/<doc-id>.md
│ ├── staleness-audit → .vyasa/<run-id>/reports/phase-3/staleness-audit/<doc-id>.md
│ └── health-audit → .vyasa/<run-id>/reports/phase-3/health-audit/<doc-id>.md
│
└── Consolidation: orchestrator reads all reports → severity-ranked report → user

```

### Auditor report format

For the exact finding block and phase summary format all auditors must produce, see
`docs/specs/live/audit-report-format.md`.

### Gate logic

The orchestrator reads phase summaries and decides per document. Errors inform but don't
mechanically determine the decision. The orchestrator may proceed through a gate with errors
present if doing so provides useful additional context.

- **After Phase 1:** Proceed / Proceed with context / Skip Phase 2+3 / Agent failure
- **After Phase 2:** Proceed to Phase 3 / Skip / Agent failure

When Phase 1 produced a `Context` line, the orchestrator synthesises a targeted briefing per
Phase 2 agent — distilling the signal relevant to that agent, not passing the context
verbatim.

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
runaway agent chains. See ADR 001 for the phasing rationale and
`docs/specs/pipeline-dispatch.md` for the allowlist syntax.

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

Fix phases mirror audit phases. Each doc enters at the phase with its earliest findings —
no Phase 1 findings means `doc-fixer` is skipped entirely. Phase 1 fixes complete before
Phase 2 fixers run on the same doc, because Phase 1 problems (wrong location, wrong
purpose) change what Phase 2 checks are relevant.

### Fix data flow

```

fix-orchestrator
│ auto-discovers run, builds findings index
│
├── Phase 1 fixers (parallel):
│ └── doc-fixer × N → .vyasa/<run-id>/reports/phase-1/doc-fixer/<doc-id>.md
│
├── [Gate 1 — route autonomous fixes to doc-editor, escalate rest to user]
│ └── update registry current_path for approved renames/moves
│
├── Phase 2 fixers (parallel):
│ ├── structure-fixer → .vyasa/<run-id>/reports/phase-2/structure-fixer/<doc-id>.md
│ ├── prose-fixer → .vyasa/<run-id>/reports/phase-2/prose-fixer/<doc-id>.md
│ ├── convention-fixer → .vyasa/<run-id>/reports/phase-2/convention-fixer/<doc-id>.md
│ └── content-fixer → .vyasa/<run-id>/reports/phase-2/content-fixer/<doc-id>.md
│
├── [Gate 2 — same routing]
│
├── Phase 3 fixers (parallel):
│ ├── discoverability-fixer → .vyasa/<run-id>/reports/phase-3/discoverability-fixer/<doc-id>.md
│ ├── staleness-fixer → .vyasa/<run-id>/reports/phase-3/staleness-fixer/<doc-id>.md
│ └── health-fixer → .vyasa/<run-id>/reports/phase-3/health-fixer/<doc-id>.md
│
└── [Gate 3 — dispatch doc-editor instances in parallel for all autonomous tasks]

```

### Fixer report format and classification

For the exact finding block, fixer summary format, classification contract, routing rule,
and phase 2 classification baselines, see `docs/specs/live/audit-report-format.md`.

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
```

**Step 3: Run prettier**

```bash
scripts/tools/prettier-fix.sh docs/audit-pipeline.md
```

**Step 4: Commit**

```bash
git add docs/audit-pipeline.md
git commit -m "docs: trim audit-pipeline.md to architecture doc, link to new specs"
```

---

### Task 5: Update `docs/specs/index.md`

Add the two new Live specs.

**Files:**

- Modify: `docs/specs/index.md`

**Step 1: Read the file**

Read `docs/specs/index.md`.

**Step 2: Add two rows to the specs table**

Add after the existing `pipeline-dispatch.md` row:

```markdown
| [audit-report-format.md](live/audit-report-format.md) | Live | Auditor finding blocks, phase summaries, fixer classification contract, and phase 2 baselines |
| [run-infrastructure.md](live/run-infrastructure.md) | Live | Run ID, document registry, filesystem layout, claim protocol, and task structure |
```

Also update the "Locations by status" table to confirm `Live` → `docs/specs/live/` is listed (it already should be).

**Step 3: Run prettier**

```bash
scripts/tools/prettier-fix.sh docs/specs/index.md
```

**Step 4: Commit**

```bash
git add docs/specs/index.md
git commit -m "docs: add audit-report-format and run-infrastructure to specs index"
```

---

### Task 6: Update `AGENTS.md`, `layout.md`, and `docs/maintenance.md`

Update all references to `python-type-annotations.md` and add routing entries for the new specs.

**Files:**

- Modify: `AGENTS.md`
- Modify: `layout.md`
- Modify: `docs/maintenance.md`

**Step 1: Read all three files**

Read `AGENTS.md`, `layout.md`, and `docs/maintenance.md` in full.

**Step 2: Update `AGENTS.md`**

Two changes:

1. Routing table entry for `python-type-annotations.md` — update path:
   - Old: `docs/python-type-annotations.md`
   - New: `docs/guides/python-type-annotations.md`

2. Add two new routing entries under "Understanding any pipeline spec":
   ```
   | Understanding report formats, fixer classification, or phase 2 baselines            | `docs/specs/live/audit-report-format.md`  |
   | Understanding run infrastructure — registry, claim protocol, filesystem layout      | `docs/specs/live/run-infrastructure.md`   |
   ```

**Step 3: Update `layout.md`**

Two changes:

1. In the `docs/` section, change:
   - Old: `python-type-annotations.md     — how to keep basedpyright warnings at zero in pytest test files`
   - New: Add a `guides/` subsection entry: `guides/python-type-annotations.md  — how to keep basedpyright warnings at zero in pytest test files`

2. In `docs/specs/` — note the `live/` subdirectory now has two new files. Update the description if needed to reflect that `live/` contains `audit-report-format.md` and `run-infrastructure.md`.

**Step 4: Update `docs/maintenance.md` staleness detection example**

Check whether `docs/maintenance.md` references `python-type-annotations.md` by path — if so, update to `docs/guides/python-type-annotations.md`.

**Step 5: Run prettier**

```bash
scripts/tools/prettier-fix.sh AGENTS.md layout.md docs/maintenance.md
```

**Step 6: Commit**

```bash
git add AGENTS.md layout.md docs/maintenance.md
git commit -m "docs: update references for python-type-annotations move and new specs"
```

---

### Task 7: Write ADR 013 — extracting specs from audit-pipeline.md

Record the decision to extract spec-level content from `audit-pipeline.md` into dedicated specs. This ADR captures why the split happened and what shape was rejected, so a future contributor doesn't re-inline the content.

**Files:**

- Create: `docs/decisions/013-audit-pipeline-spec-extraction.md`
- Modify: `docs/decisions/index.md`

**Step 1: Write the ADR**

Create `docs/decisions/013-audit-pipeline-spec-extraction.md`:

```markdown
# 013 — Extracting report format and infrastructure specs from audit-pipeline.md

**Status:** Accepted
**Date:** 2026-03-09

## Context

`docs/audit-pipeline.md` was written as a combined reference covering the pipeline
architecture (phases, agents, gates, data flow) alongside exhaustive implementation
contracts (exact report formats, fixer classification fields, claim protocol commands,
registry JSON schema, filesystem layout). ADR 008 noted this mixed-content problem at the
time but deferred the fix.

This produced a ~430-line file that violated the architecture doc / spec boundary: the
architecture doc answered both "how does the pipeline work?" and "what exact bytes must my
agent write?" Agents implementing report formats had to scan the whole file. Architecture
readers got bogged down in protocol detail irrelevant to their task.

## Decision

Extract spec-level content from `audit-pipeline.md` into two dedicated Live specs:

- `docs/specs/live/audit-report-format.md` — auditor finding block, phase summary, fixer
  finding block, fixer summary, fixer classification contract, routing rule, phase 2
  classification baselines
- `docs/specs/live/run-infrastructure.md` — run ID generation, document registry format,
  registry integrity check, filesystem layout, claim protocol commands and semantics, task
  JSON structure

`audit-pipeline.md` retains architecture-level content (design principles, phase table,
data flow diagrams, gate logic, auditor guide map, constraints, agent inventory) and links
to both specs for detail.

## Consequences

- Agents implementing report formats read one short spec, not a mixed 430-line doc
- Architecture readers are no longer interrupted by protocol tables
- Two new spec files to maintain; they must stay in sync with agent implementations
- `docs/specs/index.md` gains two rows; both specs start at Live (already implemented)

## Alternatives considered

**Keep everything in audit-pipeline.md.** Rejected — the mixed content violates the
architecture doc / spec distinction established in ADR 008 and ADR 010, and the file was
already large enough that readers routinely skipped sections irrelevant to their task.

**Single combined spec for all protocol details.** Rejected — report formats and run
infrastructure serve different readers at different times. A combined spec would be as long
as the original file without the architecture context.
```

**Step 2: Update `docs/decisions/index.md`**

Add a row for ADR 013:

```markdown
| [013](013-audit-pipeline-spec-extraction.md) | Extracting report format and infrastructure specs from audit-pipeline.md | Accepted |
```

**Step 3: Run prettier**

```bash
scripts/tools/prettier-fix.sh docs/decisions/013-audit-pipeline-spec-extraction.md docs/decisions/index.md
```

**Step 4: Commit**

```bash
git add docs/decisions/013-audit-pipeline-spec-extraction.md docs/decisions/index.md
git commit -m "docs: add ADR 013 — extracting specs from audit-pipeline.md"
```

---

### Task 8: Final verification

Check no stale references remain and all new files are reachable.

**Step 1: Check for stale references to old python-type-annotations path**

```bash
grep -rn "docs/python-type-annotations" . --include="*.md" --exclude-dir=".git"
```

Expected: zero results (all references now point to `docs/guides/python-type-annotations.md`).

**Step 2: Check for references to extracted spec content still in audit-pipeline.md**

```bash
grep -n "PHASE SUMMARY\|FIXER SUMMARY\|fixable:\|reversible:\|vyasa-claim.sh\|registry.json\|changes.log" docs/audit-pipeline.md
```

Expected: zero results (all that content now lives in the specs).

**Step 3: Verify all new files exist**

```bash
ls docs/guides/python-type-annotations.md \
   docs/specs/live/audit-report-format.md \
   docs/specs/live/run-infrastructure.md \
   docs/decisions/013-audit-pipeline-spec-extraction.md
```

Expected: all four files present.

**Step 4: Confirm old file is gone**

```bash
ls docs/python-type-annotations.md 2>&1
```

Expected: `No such file or directory`.

**Step 5: Run prettier on all touched files**

```bash
scripts/tools/prettier-fix.sh \
  docs/guides/python-type-annotations.md \
  docs/specs/live/audit-report-format.md \
  docs/specs/live/run-infrastructure.md \
  docs/audit-pipeline.md \
  docs/specs/index.md \
  AGENTS.md layout.md \
  docs/decisions/013-audit-pipeline-spec-extraction.md \
  docs/decisions/index.md
```

Expected: no changes (already formatted).

**Step 6: Final commit if any prettier changes**

```bash
git add -A
git status  # should be clean; if not, commit prettier fixes
```
