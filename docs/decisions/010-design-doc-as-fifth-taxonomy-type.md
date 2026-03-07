# 010 Design doc as a fifth documentation type

**Status:** Accepted
**Date:** 2026-03-08
**Supersedes:** ADR 008

## Context

ADR 008 established a four-type taxonomy: architecture, spec, plan, decision. The taxonomy
addressed the original problem — a single "design doc" concept was being used for both
high-level system overviews and exhaustive specs — by splitting them into distinct types.

However, the taxonomy had a gap: there was no home for the pre-approval artifact that
precedes a spec and a plan. This artifact covers a different question from any of the four
types: "What problem are we solving, what did we consider, what are we recommending, and
why?" It serves one overarching goal by addressing multiple questions together — which is
exactly what a spec or ADR must not do.

Without a designated type, this artifact either gets written informally (losing the
value of the alternatives-and-reasoning structure) or gets absorbed into a spec (mixing
pre-decision exploration with post-decision authoritative fact) or into a plan (mixing
reasoning with execution steps). Both absorptions create the same confusion ADR 008 was
written to prevent.

## Decision

A fifth documentation type — the design doc — is added to the taxonomy.

**Design doc.** The pre-approval record of a problem, alternatives considered, and a
recommendation for an overarching goal. Starts fat (full context for reviewers). Approval
unlocks planning; ADRs and specs are extracted during or after planning, then the design
is trimmed. Stays live as long as the system it describes is active — archived only on
deprecation or rejection.

The taxonomy is now five types:

| Type           | Question answered                                                            | Tense                                                                               | Lifecycle |
| -------------- | ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- | --------- |
| Architecture   | What exists and how does it fit together?                                    | Present                                                                             | Living    |
| Spec           | How does this work, exhaustively?                                            | Present                                                                             | Living    |
| Plan           | What steps execute this change?                                              | Imperative                                                                          | Ephemeral |
| Decision (ADR) | Why this, not that?                                                          | Past/present                                                                        | Permanent |
| Design         | What problem are we solving, what did we consider, what are we recommending? | Mixed (problem: present; alternatives: conditional; recommendation: future-of-past) | Living    |

**Naming.** Design docs use slug-only filenames (`docs/designs/<slug>.md`) — no date
prefix — for the same reason specs don't carry dates: a living document whose content
should feel current must not look like a historical artifact anchored to when it was
written.

**ADR extraction rule.** Extraction happens during or after planning — not at approval.
Not every decision in a design warrants an ADR. Extract ADRs for decisions with wider
impact: choices others might need to apply consistently, decisions a future contributor
might reverse without knowing why, or constraints that shape related choices elsewhere.
Minor or narrowly scoped decisions stay in the design.

## Consequences

- The taxonomy has a designated home for pre-approval exploration — designs are no longer
  ad hoc artifacts or misplaced inside specs
- A design stays live after approval (trimmed, with links to extracted ADRs and specs),
  providing a lasting narrative of the problem and reasoning
- Proposed designs are intentionally long — carrying full context for reviewers is correct
  at that stage; "the design is too long" after the plan ships is a housekeeping signal
  that extraction hasn't happened, not a quality failure in the document
- Rejected designs are archived, not deleted — deciding not to do something is a decision
  worth keeping, and may yield ADRs
- ADR 008's four-type taxonomy is superseded; routing tables and guides must be updated to
  reference five types

## Alternatives considered

**Keep four types; use a plan for pre-approval exploration.** Plans are ephemeral and
execution-focused. A pre-approval artifact that captures alternatives and reasoning is
neither — it needs to survive after the plan ships. This collapses the plan/design
distinction and recreates the confusion ADR 008 was written to resolve.

**Keep four types; absorb design content into specs.** A spec must be the authoritative
present-tense description of how something works — mixing pre-decision alternatives into a
spec contaminates it with content that should be discarded or extracted after approval.
Spec consumers (implementers) would have to wade through exploration to find facts.

**Keep four types; absorb design content into ADRs.** An ADR answers one question with
one answer. A design serves an overarching goal with multiple questions. Forcing a design
into ADR structure either produces one enormous ADR or fragments a coherent argument across
many small ones, losing the connective reasoning.
