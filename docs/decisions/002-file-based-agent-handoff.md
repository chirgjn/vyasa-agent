# 002 File-based agent handoff via structured reports

**Status:** Accepted
**Date:** 2026-03-08

## Context

The audit pipeline dispatches many agents in parallel — up to N instances of each auditor
(one per document) running concurrently. These agents need to communicate findings to the
orchestrator, and the orchestrator needs to make gate decisions without reading project
files itself.

Two approaches were on the table: agents return findings inline (the orchestrator reads
their output directly from the subagent response), or agents write structured reports to
disk and the orchestrator reads those.

Inline output has a concrete problem: every agent's full findings would flow into the
orchestrator's context window. With N documents and multiple auditors per phase, the
orchestrator's context would grow proportionally with the number of documents. At scale
this degrades LLM reasoning — content in the middle of a long context gets ignored.

## Decision

All auditing and fixing agents write structured reports to well-known paths under
`.vyasa/<run-id>/reports/`. The orchestrator reads these reports for every gating decision;
it never reads project files directly. Each agent writes exactly one report to a path
encoding its name and the doc-id it processed.

## Consequences

- The orchestrator's context stays bounded regardless of document count — it reads only
  the structured phase summaries, not full finding blocks, when making gate decisions
- Parallelism is natural: each agent writes to a unique path, with no coordination needed
- Reports are inspectable on disk after a run; debugging is possible without re-running
- Agents can be re-run individually by path if a single report is missing or malformed
- A missing or malformed `PHASE SUMMARY` block is treated as agent failure, not a clean
  pass — the orchestrator has a detection mechanism for truncated writes without checksums
- The `.vyasa/` directory accumulates run artifacts and must be cleaned up separately;
  it is not committed to version control

## Alternatives considered

**Inline agent output.** The orchestrator reads findings from subagent responses directly.
Simpler — no disk writes, no file paths to coordinate. Rejected because the orchestrator's
context grows with every document, and LLM reasoning degrades as context grows. Findings
from 20 documents would fill context before consolidation begins.
