# Writing Architecture Docs

How to create and maintain architecture docs — living docs that describe how a system is
structured, how it behaves, and why the pieces are arranged the way they are. For
one-time decisions and their rationale, see `framework/guides/writing-decision-records.md`.
For reference docs that describe how to do a task, see `framework/guides/writing-reference-docs.md`.

---

## What an architecture doc is

Read this section when you're unsure whether architecture doc, ADR, or reference doc is the
right format for what you're writing.

An architecture doc describes **how a system works** — its components, their
responsibilities, how they interact, and the constraints that shape them. It is a living
doc: updated as the system changes, not archived when a feature ships.

The audience is someone who needs to understand the system before making changes to it —
not someone following a step-by-step procedure.

**Architecture doc, not design doc.** A design doc is a pre-approval artifact: it frames
the problem, compares alternatives, and justifies the chosen approach. An architecture doc
describes how the chosen approach is actually structured — it is a post-approval, post-
implementation living record. If you're still deciding what to build, you're in design doc
territory. See `framework/guides/writing-design-docs.md`.

**Architecture doc, not spec.** An architecture doc gives the system view — components,
responsibilities, how they fit together. A spec gives exhaustive detail — exact formats,
specific values, every case covered. When a component has non-trivial behaviour, the
architecture doc names it and links to the spec; it does not inline the detail. If content
is too detailed for the system view, it belongs in a spec.

**Architecture doc, not ADR:** If the content is "here is what exists and how it
fits together," it's an architecture doc. If the content is "here is why we chose X over
Y," it's an ADR. A single architecture doc will often link to several ADRs for the
reasoning behind its constraints.

**Architecture doc, not reference doc:** A reference doc answers "how do I do X?" An
architecture doc answers "how does X work?" Organize by system structure, not by task.

---

## When to write one

Write an architecture doc when:

- A system has enough components that a newcomer can't safely make changes without first
  understanding how they fit together
- The constraints governing a system aren't visible from reading the code alone
- Multiple docs reference the same system and each repeats a partial description — one
  architecture doc eliminates the duplication

Don't write one when a diagram and a paragraph in a reference doc would cover it. The
threshold is roughly: 3+ components with non-obvious interactions.

---

## Structure template

Use when creating a new architecture doc — copy this skeleton and remove sections that
don't apply.

```markdown
# [System Name] Architecture

[1–2 sentences: what this system does and who should read this doc.]
[Cross-link to related ADRs, reference docs, or layout files.]

## Overview

High-level description of the system. What problem does it solve? What are its
major components? A diagram belongs here if the topology isn't obvious from prose.

## Components

One section per major component. For each:

- What it does (responsibility, not implementation)
- What it reads/writes/calls
- What it must NOT do (invariants and boundaries)

## Data flow

How information moves through the system — inputs, transformations, outputs.
Sequence diagrams or flow diagrams work well here for non-trivial flows.

## Constraints

Rules the system must obey that aren't enforced by tooling. Why they exist.
Link to ADRs for decisions that drove these constraints.

## What lives where

File/directory map for non-obvious placement decisions. Not a full tree — only
what a contributor would get wrong without being told.
```

---

## Section-by-section guidance

Use when drafting or reviewing any section — what belongs where and what to avoid.

### Overview

Lead with the problem the system solves, not its name or tech stack. A reader who doesn't
understand why the system exists won't understand why it's shaped the way it is.

Include a diagram here when the system has 4+ components or non-obvious flow. For diagram
guidance, see `framework/guides/diagrams.md`.

### Components

Describe responsibilities, not implementations. "The orchestrator reads phase summaries
and decides per-document whether to proceed" is a responsibility. "The orchestrator calls
`parse-phase-summary.py` and checks the `Findings` field" is an implementation — it
belongs in a reference doc, not an architecture doc.

Include the **NOT** constraints. What a component must not do is often more important
than what it does — these are the invariants that prevent coupling from creeping in.

### Constraints

Constraints without reasons go stale and get quietly ignored. For each constraint, one
sentence on why it exists. If the reason is long, link to an ADR.

Don't list constraints that are enforced by tooling — those are already covered by linter
config or CI. Only document constraints that require human judgment to uphold.

---

## Keeping architecture docs alive

Check when a system changes, or when a design doc for that system ships.

Architecture docs go stale when the system changes and the doc doesn't. The failure mode
is subtle: the doc is plausible, a contributor reads it, makes changes based on it, and
introduces a bug because the doc was wrong.

**Update triggers** — update the architecture doc when:

- A component is added, removed, or its responsibility changes
- A constraint is relaxed or tightened
- A data flow changes (new inputs, outputs, or transformation steps)
- A diagram in the doc no longer matches the system

**After a spec moves to Live:** compare the architecture doc against the implemented
system. Specs describe intent while In Progress; architecture docs must describe reality.

**Staleness check:** run through the components and constraints sections and verify each
claim against the codebase. For a full staleness checklist, see `framework/guides/staleness.md`.

---

## Common mistakes

| Mistake                                             | Fix                                                                                            |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Describing implementation instead of responsibility | "The orchestrator reads reports and gates" not "the orchestrator calls parse-phase-summary.py" |
| Listing constraints without reasons                 | Add one sentence per constraint explaining why it exists                                       |
| Architecture doc that duplicates a reference doc    | Merge: keep the how-it-works content here, move the how-to-use content to the reference doc    |
| Never updating after the system ships               | Add the architecture doc to the update triggers in `docs/maintenance.md`                       |
| Diagram that shows every detail                     | Diagrams should show topology and flow, not every field and method                             |
