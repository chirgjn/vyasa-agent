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
