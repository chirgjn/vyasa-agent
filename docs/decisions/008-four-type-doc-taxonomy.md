# 008 Four-type documentation taxonomy: architecture, spec, plan, decision

**Status:** Superseded by [ADR 010](010-design-doc-as-fifth-taxonomy-type.md)
**Date:** 2026-03-08

## Context

The project accumulated several kinds of documentation with no clear rules distinguishing them.
`docs/audit-pipeline.md` mixed high-level pipeline structure with exhaustive implementation
detail. `docs/pipeline-dispatch-design.md` mixed a detailed problem-and-solution spec with an
execution checklist. ADRs existed but had no counterpart for living design documentation.

Without a taxonomy, two failure modes recurred. First, a document would try to serve multiple
audiences — a reader wanting to understand the system had to wade through implementation minutiae,
while an implementer couldn't find the complete detail they needed in one place. Second, documents
had no lifecycle: there was no shared understanding of when a doc was done, when it should be
archived, or when it should be superseded.

The existing vocabulary — "design doc," "plan," "spec" — was used interchangeably. Different
contributors meant different things by each term, making routing table entries ambiguous.

## Decision

The project uses exactly four document types, each with a distinct purpose, tense, and lifecycle:

**Architecture.** High-level description of how a system is structured. Answers "what exists and
how does it fit together." Written in present tense. Stable — changes only when the system
fundamentally changes. Links to specs for detail rather than inlining it. Lives in
`docs/architecture/`.

**Spec.** Exhaustive, authoritative description of how something works. Answers every question
about its topic so an implementer never has to guess or look elsewhere. Written in present tense.
Living — updated when the thing it describes changes, deprecated when superseded. Architecture
docs reference specs to avoid going into detail irrelevant to the system view. Lives in
`docs/specs/` with status-based subdirectory organization (see ADR 009).

**Plan.** Step-by-step execution checklist for a bounded change. Ephemeral — written before
execution, archived after merge. References the spec for what to implement; does not duplicate
the spec's content. Named with a date prefix (`YYYY-MM-DD-<slug>.md`) so the date of execution
is preserved after archival. Lives in `docs/plans/` while active, `docs/archive/plans/` after.

**Decision (ADR).** The reasoning behind a non-obvious choice. Permanent — never updated, only
superseded. Answers "why this, not that." Lives in `docs/decisions/`.

## Consequences

- Each document has one job; readers know what to expect from a file's location
- Architecture stays readable at a system level because detail lives in specs, not inline
- Plans are thin by design — they reference specs, not restate them
- A spec and a plan for the same topic coexist: the spec states the facts, the plan tracks
  execution progress
- Adding a new concern requires placing it in exactly one type; ambiguous cases are resolved
  by asking which question the document answers (what exists / how it works / what to do / why)
- The taxonomy must be taught and enforced through routing table entries and doc audits —
  nothing prevents a contributor from writing a spec-shaped doc in `docs/` root

## Alternatives considered

**Two types: living docs and ephemeral docs.** Simpler, but collapses the architecture/spec
distinction and the plan/decision distinction. A living doc that's a high-level system overview
needs to behave differently from one that's an exhaustive implementation spec — they have
different audiences, different update triggers, and different relationships to other docs.

**Three types: design, plan, decision.** The previous implicit model. "Design" covered both
architecture and spec, leaving it unclear whether a design doc should be high-level or exhaustive.
The pipeline-dispatch doc was called a "design" but contained both spec content and a plan table.
Rejected because the ambiguity was the original problem.

**Separate architecture into its own ADR.** The architecture/spec distinction could be recorded
separately. Kept together here because the four types only make sense as a system — defining
spec without defining how it differs from architecture leaves the taxonomy incomplete.
