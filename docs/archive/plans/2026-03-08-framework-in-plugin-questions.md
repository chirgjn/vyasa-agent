# Open Questions: Specialised Audit + Fix Agents Design

---

## Design gaps and ambiguities

**1. The `doc-audit` `writing-layout-md.md` guide reference** ✓ RESOLVED

`writing-layout-md.md` exists at `plugin/framework/guides/writing-layout-md.md`. It was missing from the
guides routing table in `AGENTS.md` — added.

**2. Phase 2 auditor report format is unspecified** ✓ RESOLVED

All auditors across all phases use the same two-part format: finding blocks + a short phase
summary. The phase summary is purely factual — `Doc-ID`, `Phase`, `Findings` counts, and an
optional `Context` line. Auditors report what they found; the orchestrator applies its own gate
logic by reading the error count. `doc-audit` and `doc-fixer` updated to use `Doc-ID` throughout.
Design doc updated with a new "Auditor report format" section and revised gate logic.

**3. Gate 2 condition is ambiguous** ✓ RESOLVED

Both gates use the same model: the orchestrator reads phase summaries (findings counts + context)
and makes a judgment call. Errors inform the decision but do not mechanically determine it — the
orchestrator may proceed to the next phase even with errors if doing so adds useful context.
Design doc updated: orchestrator gates prose, gate decision diagram, and Steps 3 and 5 in the
`full-audit` workflow.

**4. Fix phase data flow is incomplete** ✓ RESOLVED

`fix-orchestrator` reads auditor reports (already written by `full-audit`) to build its findings
index at startup. Fixer reports don't exist yet at that point — they are written as
`fix-orchestrator` runs. Design doc Step 1 updated to make this explicit.

**5. `doc-editor` task source is unspecified** ✓ RESOLVED

Task files. The orchestrator writes each task to `.vyasa/<run-id>/tasks/<task-id>.json` before
dispatching `doc-editor`. `doc-editor` receives only `task-id` and `run-id` as arguments and
reads the task file itself — consistent with the file-based handoff principle. Design doc updated:
task structure section, `doc-editor` workflow step 1, filesystem layout, and agent inventory.

**6. Phase 2 "Proceed with context" mechanics** ✓ RESOLVED

The orchestrator synthesises a terse, targeted briefing per agent from the Phase 1 context line —
not passed verbatim. Each Phase 2 agent gets only the signal relevant to its domain. Design doc
Step 4 updated with instructions and a concrete example.

**7. `full-audit` rewrite timing**

`vyasa-claim.sh` is already in `scripts/tools/`. The current `full-audit.md` still has the old
monolithic workflow. Is the rewrite of `full-audit.md` blocked on other agents being built first,
or should it be done now alongside `doc-audit`/`doc-fixer`?

**8. Rename as multi-file fix vs. single `doc-editor` task** ✓ RESOLVED

One task. For small, tightly coupled changes (e.g. rename + routing table update), `doc-editor`
claims all files it will touch, applies all changes, then commits each claim in a single task.
Two tasks with `depends_on` only when changes are large or independent enough that sequencing
adds clarity. Design doc task structure section, `doc-editor` workflow, and `doc-fixer`
classification table updated.

**9. No fixer report format specified for Phase 2 and Phase 3 fixers** ✓ RESOLVED

All fixers use the same `FINDING` block + `FIXER SUMMARY` format as `doc-fixer`. The blocking
field is uniform across all phases: `Next-phase wait: yes | no`. Phase 3 fixers always write
`no`. Design doc, `doc-fixer.md` updated.

**10. `.vyasa/` gitignore** ✓ RESOLVED

`.vyasa/` added to `.gitignore`.

**11. `full-audit` rewrite timing (duplicate of #7, rephrased)**

`agents/full-audit.md` still runs the old monolithic 9-section workflow. The design requires a
complete rewrite. Should the rewrite happen now, or only after the Phase 2/3 agents exist to be
dispatched?

**12. `fix-orchestrator` invocation path** ✓ RESOLVED

`full-audit` offers a handoff at the end of its consolidation report: "Would you like me to run
the fix pipeline?" and dispatches `fix-orchestrator` only if the user confirms. `fix-orchestrator`
takes no required arguments — it auto-discovers the most recent completed run from `.vyasa/` by
mtime, prints a one-line confirmation (`Using audit run <run-id> (<N> docs, <N> findings).`), then
proceeds. This also handles fresh-session resume: the user invokes `fix-orchestrator` directly and
it picks up the last run from `.vyasa/` without needing a run-id. Design doc updated: `fix-orchestrator`
Step 1, `full-audit` Step 7.

**13. `doc-editor` agent file not yet created** ✓ RESOLVED

`agents/doc-editor.md` created. Implements the full workflow from the design: load task file,
check dependencies via claim log, resolve paths from registry, claim all files, confirm, apply
change, commit claims, report done. Uses `scripts/tools/vyasa-claim.sh` throughout. Does not
make git commits.

**14. `convention-audit` guide: `writing-conventions.md` may not exist** ✓ RESOLVED

`plugin/framework/guides/writing-conventions.md` exists, is substantive (phrasing rules, category
examples, what to move or delete), and is already in the `AGENTS.md` routing table. No action
needed — `convention-audit` can read it directly.

**15. `content-audit` vs `doc-audit` boundary on "misplaced content"** ✓ RESOLVED

The boundary is document-level vs. content-level. `doc-audit` flags the document as a whole
being in the wrong bucket ("this file belongs in `docs/decisions/`, not `docs/guides/`").
`content-audit` flags passages within a correctly-placed document that belong somewhere else
("this decision rationale section buried in a reference doc belongs in `docs/decisions/`"). The
unit of judgment differs: file for Phase 1, block of content for Phase 2. Auditor table scope
description for `content-audit` updated to make the distinction explicit.

**16. `staleness-audit` has no guide and unclear tooling** ✓ RESOLVED

`auditing-anti-patterns.md` is high-level vision, not a prescriptive spec. A new guide
`plugin/framework/guides/staleness.md` was created with five staleness types, each with a definition
of "what good looks like" and concrete detection methods: broken path references, command
existence, aspirational conventions, diagram accuracy, ADR status. `maintenance.md` now
references `staleness.md` rather than containing the content itself. `staleness-audit` reads
`plugin/framework/guides/staleness.md`. `Bash` is needed for existence checks only — the agent does
not execute commands from `AGENTS.md`. Auditor table and `AGENTS.md` routing table updated.

**17. Phase 2 fixer classification tables are unspecified** ✓ RESOLVED

Classification tables added to the design doc for all four Phase 2 fixers. Key decisions:

- `prose-fixer` — all findings autonomous (prose edits are always file-scoped and reversible)
- `structure-fixer` — most findings autonomous except whole-doc restructures (require judgment)
- `convention-fixer` — phrasing fixes and deletions autonomous; aspirational conventions and
  unconfigured linter rules escalate (user decides enforce/fix/delete)
- `content-fixer` — verbatim duplication and misplaced passages (when target exists) autonomous;
  semantic duplication, missing target file, and convention drift always escalate

**18. Scope exclusions: orchestrator-only or also agent-level?** ✓ RESOLVED

Orchestrator-only. Agents resolve paths exclusively from the registry, which the orchestrator
builds at startup with exclusions already applied. An excluded file is never registered, so an
agent cannot receive a path to one. Agent-level path validation would be defensive coding against
a bug that can't happen in normal operation — the design already says conflicts indicate
orchestrator bugs and fail loudly. No design change needed.

**19. `structure-fixer` name inconsistency in the design doc** ✓ RESOLVED

Typo in the Phase 2 fixer classification tables section — the header read `structure-audit`
instead of `structure-fixer`. Fixed to `structure-fixer` in the design doc.

**20. `multi-file` scope blocks autonomous dispatch — is that intentional?** ✓ RESOLVED

Expanded the autonomous routing rule: `fixable: yes` + `scope: file or multi-file` +
`reversible: yes` → autonomous. `scope: structural`, `fixable: no`, or `reversible: no` →
escalate. Multi-file fixes are fully reversible with `git revert`; the difference from
file-scoped is surface area, not recoverability. Design doc orchestrator gates section, Gate 1
bucket definitions, and `doc-fixer` classification table updated.

**21. `fix-orchestrator` explicit run-id path is undescribed** ✓ RESOLVED

`fix-orchestrator` accepts an optional positional argument: `fix-orchestrator [run-id]`. If
provided, use it directly; if omitted, auto-discover by mtime. In both cases print the one-line
confirmation before proceeding. Design doc Step 1 updated.

**22. Task file `doc-id` field — singular or array?** ✓ RESOLVED

Renamed to `doc-ids`, typed as a JSON array. Single-file tasks have a one-element array. Makes
the schema self-documenting and removes the case-split from `doc-editor`'s logic. Design doc task
structure table and `doc-editor.md` updated.
