# 001 Three-phase audit pipeline with judgment gates

**Status:** Accepted
**Date:** 2026-03-08

## Context

The original `full-audit` agent ran all checks in a single pass: existence checks, prose
quality, broken references, and file sizing all ran together on every document regardless
of whether the document belonged in the repo at all. A document in the wrong directory had
its prose audited, its routing table checked, and its file size measured — work that
produced noise rather than findings, because the prior question (should this document exist
here?) was never answered first.

There was also no mechanism to skip work. Every agent read every file. Checks that required
literary judgment (prose quality, section structure) ran alongside purely mechanical checks
(broken references, file sizing). Different expertise, different guides, different fix
strategies — combining them in one agent meant none was done well.

The audit had gaps: prose style and section structure were never checked. And there was no
gate: a document that should be deleted still had its comma placement audited.

## Decision

The audit pipeline runs in three sequential phases with orchestrator judgment gates between
them: Phase 1 (document validity), Phase 2 (conceptual depth), Phase 3 (mechanical checks).
Each phase runs its agents in parallel. The orchestrator reads phase summaries and decides
per document whether to proceed, proceed with context, or skip — errors inform but don't
mechanically determine the decision.

## Consequences

- Phase 1 findings focus later phases: a misplaced document can be excluded from prose
  audit entirely, eliminating irrelevant findings
- Specialist agents each read only the guide governing their domain, producing targeted
  findings instead of broad noise
- The pipeline is slower than a single-pass audit — three sequential phases with waits
  at each gate add latency
- The orchestrator must exercise genuine judgment at each gate; it cannot be mechanically
  correct by just passing everything through
- Adding a new concern type requires placing it in the right phase and updating the
  orchestrator — it cannot just be appended to a single agent

## Alternatives considered

**Single-pass monolithic audit.** Run all checks in one agent per document. This is faster
(no inter-phase waits) but produces findings without priority ordering and wastes work
auditing documents that shouldn't exist. The original `doc-lint` used this approach and was
retired because findings were too coarse to act on.

**Two phases (validity then all other checks).** Simpler gating — one gate instead of two.
Rejected because conceptual checks (prose, structure) and mechanical checks (broken refs,
file sizing) require different expertise and different fix strategies. Separating them into
phases 2 and 3 keeps each agent's scope clean and makes the fix pipeline's phase mirroring
natural.
