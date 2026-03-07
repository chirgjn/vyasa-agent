# Writing Decision Records

How to write ADRs and when to extract them from design docs. For the taxonomy that places
decision records in `docs/decisions/`, see `framework/managing-project-information.md` §
"Decisions." For design docs (pre-approval problem + alternatives + recommendation), see
`framework/guides/writing-design-docs.md`. For architecture docs (living docs about how a
system works), see `framework/guides/writing-architecture-docs.md`.

---

## When to Write an ADR

Write an ADR when a decision has wider impact — when others might need to apply the same
reasoning elsewhere, when a future contributor might reverse it without knowing why it was
made, or when the decision shapes how related choices should be made. An ADR answers one
question with one answer; it is not a summary of a broader discussion.

The test: if you deleted this ADR, would a future contributor likely re-litigate the
question and reach the wrong conclusion — or apply the opposite pattern somewhere else?

**Write one when:**

- A technology, library, or pattern was chosen over a plausible alternative — and the
  reasoning applies to similar choices in the future
- An architectural boundary was drawn in a non-obvious way that constrains future work
- A constraint was accepted (performance, coupling, complexity) that others need to uphold
- A simpler approach was explicitly rejected — and someone will be tempted to revisit it
- A spec is accepted — the ADR records why this approach over alternatives (written during
  or after planning, not at design approval)
- A plan is completed — the ADR records any decisions with wider impact made during
  implementation
- A design is being planned or has been executed — extract ADRs for decisions that matter
  beyond this one design; minor or narrowly scoped decisions can stay in the design.
  Extraction happens during or after planning, not at approval

**Don't write one when:**

- The choice is obvious given the context ("we used the framework's built-in auth")
- The decision is already enforced by tooling with no judgment involved
- The reasoning is already captured in a living architecture doc
- The decision is narrowly scoped to one place and unlikely to recur or be reversed

**When archiving a plan:** scan it for decisions with wider impact before archiving. The plan
is ephemeral; well-reasoned decisions are not. The spec the plan implemented is not ephemeral
— move it to `docs/specs/live/`, don't archive it with the plan.

**When deprecating or rejecting a design:** scan it for decisions worth keeping before
archiving. Deciding not to do something is still a decision — rejected designs often yield
ADRs. See `framework/guides/writing-design-docs.md` § "Archiving, deprecating, and rejecting".

---

## Format

Use when writing a new ADR — copy this skeleton and fill in each section.

```markdown
# [NNN] Title — short phrase describing the decision, not the outcome

**Status:** Proposed | Accepted | Superseded by [NNN]
**Date:** YYYY-MM-DD

## Context

What situation or problem forced this decision? What constraints existed?
1–3 paragraphs. No solution yet.

## Decision

What was decided? State it directly: "We will use X" or "We decided not to Y."
One paragraph.

## Consequences

What becomes easier? What becomes harder? What new obligations does this create?
2–5 bullet points. Include both positive and negative.

## Alternatives considered

What else was on the table, and why was it not chosen?
One paragraph or short list per alternative. Omit if nothing plausible was rejected.
```

---

## Section-by-section guidance

Use when drafting or reviewing any section of an ADR — common traps and how to avoid them.

### Context

Write the situation as it existed _at the time of the decision_ — not with hindsight.
Include constraints that aren't visible from the codebase: team size, timeline,
operational complexity, prior commitments. A reader should understand _why this question
came up at all_.

Don't describe the solution here. Don't write "We needed to decide whether to use X."
Write the underlying problem: "Our audit agents were sharing context directly, which made
parallelism impossible and grew the orchestrator's context window with every doc."

### Decision

One crisp statement. Avoid justification here — justification belongs in Context or
Consequences. If you find yourself writing "because," move that clause.

**Bad:** "We decided to use file-based handoff because it enables parallelism and keeps
orchestrator context clean."

**Good:** "Agents communicate through structured reports written to `.vyasa/<run-id>/reports/`.
The orchestrator reads these reports; it never reads project files directly."

### Consequences

Be honest about the costs. An ADR that lists only benefits wasn't written by someone who
thought it through. Common consequence categories:

- What's now easier or faster
- What's now harder or slower
- What new invariants must be maintained
- What doors are now closed

### Alternatives considered

Include this section when a plausible alternative was explicitly evaluated and rejected.
Omit it when no real alternative existed or when the choice was obvious in context.

One paragraph per alternative is enough: what it was, why it was considered, why it was
rejected.

---

## Naming and numbering

Use when creating a new ADR file — follow these conventions so decisions stay sortable and stable.

```
docs/decisions/001-use-postgres.md
docs/decisions/002-event-sourcing.md
docs/decisions/003-file-based-agent-handoff.md
```

- Sequential three-digit prefix — sortable, stable, never reused
- Lowercase hyphen-separated slug after the number
- Slug describes the decision topic, not the outcome: `003-file-based-agent-handoff`, not
  `003-chose-files-over-inline`

---

## Keeping ADRs alive

Check when a referenced system changes, or when reviewing docs for staleness.

ADRs are not updated when the decision is revisited — they are superseded. Change the
status of the old ADR to `Superseded by [NNN]` and write a new one. This preserves the
reasoning trail.

**What does go stale:** path references, command names, and links to other docs. Check
these when the referenced system changes. For a full staleness checklist, see
`framework/guides/staleness.md`.

**What doesn't go stale:** the Context and Decision sections. Even if the decision was
wrong, the original reasoning is historical fact — don't rewrite it.
