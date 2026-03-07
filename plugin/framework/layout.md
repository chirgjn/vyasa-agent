# Framework Layout

Structural map of `plugin/framework/` — the documentation framework shipped inside the vyasa plugin.

## Contents

```
framework/
  README.md                          — what this framework is and how it's used
  layout.md                          — this file
  managing-project-information.md    — the seven content buckets: placement rules, taxonomy, discoverability
  auditing-anti-patterns.md          — pragmatic audit guide: broad but not exhaustive, self-contained, complements the full audit pipeline
  guides/
    writing-agents-md.md             — what belongs in AGENTS.md vs. docs; routing table conventions
    writing-conventions.md           — how to write conventions: phrasing, categories, negative constraints
    writing-reference-docs.md        — how to create or review reference docs and tutorials
    writing-decision-records.md      — how to write ADRs; when to write vs. supersede
    writing-architecture-docs.md     — how to write living architecture docs
    writing-specs.md                 — how to write exhaustive authoritative specs; lifecycle and status
    writing-design-docs.md           — how to write design docs; approval, extraction, archival
    writing-layout-md.md             — how to write layout.md files for directories
    writing-prose-style.md           — voice, table formatting, list structure, sentence quality
    diagrams.md                      — when to use diagrams, what type, how to keep them accurate
    mermaid.md                       — Mermaid syntax guide for this project
    maintenance.md                   — how to keep docs accurate as the codebase evolves
    staleness.md                     — the five staleness types, detection methods, stale signals
```

## What lives here

- **Core docs** (`managing-project-information.md`, `auditing-anti-patterns.md`) — placement rules and the pragmatic audit guide
- **Guides** (`guides/`) — one guide per doc type or concern; agents read these during audits and fixes

## What doesn't live here

- Per-project docs → live in the consumer project's `docs/` directory
- Audit run state → `.vyasa/` in the consumer project, ephemeral
- Agent definitions → `plugin/agents/`
