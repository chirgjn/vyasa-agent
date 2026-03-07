# 006 `author-*` prefix for content-creation agents

**Status:** Accepted
**Date:** 2026-03-08

## Context

The plugin had two categories of agents serving opposite purposes: pipeline agents
(`*-audit`, `*-fixer`, `doc-editor`) that inspect and repair existing documentation, and
agents that create new content from scratch. The creation agents had no shared naming
pattern — `diagram-author`, `write-reference-doc`, `write-decision-record` were all valid
names with no common prefix.

This made creation agents hard to discover: a user could not enumerate or predict them by
name, and could not distinguish them from pipeline agents by looking at an agent list.
Finding a creation agent required reading every agent description individually.

## Decision

All content-creation agents use the `author-*` prefix. Existing agents were renamed:
`diagram-author` → `author-diagram`, `write-*` → `author-*`. No new creation agent may be
added under any other prefix.

## Consequences

- Creation agents are enumerable — the `author-` prefix surfaces the full set at a glance
- `author-*` vs pipeline names (`*-audit`, `*-fixer`) create clear visual separation
  between creation and maintenance work
- Existing references to old agent names break and must be updated when the convention is
  adopted
- The convention is not currently enforced by tooling — nothing prevents a future
  `create-*` or `generate-*` agent from being added; the ADR is the only guard

## Alternatives considered

**`create-*` prefix.** Considered as an alternative prefix. Rejected because `author`
better captures the role — these agents produce structured documents following framework
guides, not generic output.

**No prefix, description-only discovery.** The status quo before this decision. Rejected
because agent names do not communicate role, and discovery requires reading every
description individually. The inconsistency between `diagram-author` and `write-*` also
made the inventory feel arbitrary.
