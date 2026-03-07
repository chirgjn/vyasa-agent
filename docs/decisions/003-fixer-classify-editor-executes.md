# 003 Fixers classify findings; doc-editor executes changes

**Status:** Accepted
**Date:** 2026-03-08

## Context

The original audit pipeline had no fix pipeline at all. The orchestrator applied fixes
inline, mixing audit and repair, with no plan presented to the user and no parallelism.
Fixes were applied immediately and irreversibly.

When designing the fix pipeline, two architectures were possible: fixers apply changes
directly (fixer = classifier + editor), or fixers produce structured recommendations that
a separate scribe agent executes.

Fixers applying changes directly has an obvious problem: when multiple fixers run in
parallel on the same document, they would step on each other. A prose-fixer and a
structure-fixer editing the same file concurrently would produce conflicting writes.
Serialising fixer execution would eliminate parallelism in the fix phase.

There is also a user-trust problem. If fixers apply changes immediately, the user has no
opportunity to review the plan before the repo is modified. An incorrect fix applied
autonomously is harder to spot and revert than a classification that the user or
orchestrator can reject before any change is made.

## Decision

Fixers classify each finding (`fixable`, `scope`, `reversible`) and produce concrete
recommendations. `doc-editor` executes approved changes — one task per instance. The
orchestrator routes classifications: `fixable: yes` + `scope: file or multi-file` +
`reversible: yes` proceeds autonomously to `doc-editor`; anything else is escalated to
the user. No changes are made until a task is dispatched to `doc-editor`.

## Consequences

- Multiple fixers can run in parallel — they only write recommendation reports, never
  touch project files
- The claim protocol (claim → confirm → edit → commit) enforces that no two `doc-editor`
  instances touch the same file simultaneously
- The user sees an escalation before any structural or irreversible change happens
- Task files written by the orchestrator are inspectable before `doc-editor` runs —
  the plan is visible
- Fixers must produce structured classifications in a defined format; an agent that
  outputs free-form text cannot be routed
- `doc-editor` instances depend on task files existing before they start; task file
  creation must be atomic from the orchestrator's perspective

## Alternatives considered

**Fixers apply changes directly.** Each fixer edits the documents it audited, protected
by a file lock. Simpler — no task files, no separate scribe agent. Rejected for two
reasons: parallel fixers on the same file require coordination that eliminates the
parallelism benefit, and there is no review point before repo modifications begin.

**Orchestrator applies fixes.** The orchestrator reads fixer recommendations and applies
changes itself, without a separate `doc-editor`. Rejected because the orchestrator's
context is already large (it reads all reports); having it also perform edits would
further grow its context and mix coordination with execution in one agent.
