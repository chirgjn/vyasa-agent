# 004 Auditors derive checks from guides, not auditing-anti-patterns.md

**Status:** Accepted
**Date:** 2026-03-08

## Context

The framework has two documents covering quality criteria from opposite directions: the
guides (prescriptive — what good looks like and how to achieve it) and
`auditing-anti-patterns.md` (diagnostic — what wrong looks like and how to detect it).

The original `doc-lint` agent read `auditing-anti-patterns.md` as its primary source.
This created a coverage gap: `auditing-anti-patterns.md` is a diagnostic lens on the same
content as the guides, not the canonical specification. A quality criterion that existed
in a guide but hadn't yet been added to `auditing-anti-patterns.md` would be missed
entirely. Keeping both documents in sync required ongoing maintenance.

## Decision

Auditing agents read the guides directly — not `auditing-anti-patterns.md` — to derive
their checks. Each auditor reads the specific guide governing its domain. If a quality
criterion exists in a guide but not in `auditing-anti-patterns.md`, the auditor catches
it anyway. `auditing-anti-patterns.md` serves the orchestrator's high-level understanding
of audit philosophy; it links to guides as reference depth.

## Consequences

- Coverage is complete: any criterion in a guide is checked, regardless of whether
  `auditing-anti-patterns.md` mentions it
- Each auditor has a single, scoped source of truth; it does not need to reconcile two
  documents
- `auditing-anti-patterns.md` no longer needs to be kept in sync with guides for audit
  coverage purposes — it can evolve as a diagnostic aid without being on the critical path
- New guides added to the framework automatically extend audit coverage when the
  corresponding auditor reads them — no update to `auditing-anti-patterns.md` needed
- The scope of `auditing-anti-patterns.md` narrows: it is a diagnostic lens and a
  discoverability document, not a specification

## Alternatives considered

**Auditors read `auditing-anti-patterns.md`.** This was the original approach. Rejected
because it created a coverage dependency: audit quality was bounded by the completeness
of `auditing-anti-patterns.md` rather than the guides themselves. Every guide improvement
required a parallel update to `auditing-anti-patterns.md` to become checkable.

**Auditors read both guides and `auditing-anti-patterns.md`.** More coverage, but
introduces reconciliation complexity when the two sources contradict or overlap. An
auditor that reads both must decide which takes precedence — this pushes judgment into
the agent definition rather than the document hierarchy.
