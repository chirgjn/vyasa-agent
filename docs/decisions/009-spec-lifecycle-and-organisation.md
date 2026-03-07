# 009 Spec lifecycle: statuses, directory layout, and naming

**Status:** Accepted
**Date:** 2026-03-08

## Context

Once specs were defined as a distinct document type (ADR 008), their lifecycle needed to be
specified. A spec that is proposed but not yet agreed on is different from one being actively
implemented, which is different from one that accurately describes a live system. Without
explicit statuses, there is no way to tell from a spec whether it represents current reality
or an aspiration.

Three structural questions arose: how to communicate status (header block, frontmatter, or
directory), whether specs should carry date prefixes like plans, and whether specs should have
numeric IDs like ADRs.

## Decision

**Statuses.** Specs use a markdown header block (`**Status:**`) with six states:

| Status      | Meaning                                                |
| ----------- | ------------------------------------------------------ |
| Proposed    | Draft, not yet agreed on                               |
| Accepted    | Agreed on; a plan may or may not exist yet             |
| In Progress | A plan is actively executing against this spec         |
| Live        | Fully implemented; this spec describes current reality |
| Deprecated  | Superseded by another spec or approach                 |
| Rejected    | Evaluated and not adopted                              |

In Progress is expected to be brief — a spec should not stay in this state longer than the plan
that implements it.

**Directory layout.** Status is communicated by both the header block and the file's location:

```
docs/specs/              — Proposed and Accepted specs
docs/specs/in-progress/  — In Progress specs
docs/specs/live/         — Live specs
docs/archive/specs/      — Deprecated and Rejected specs
```

The single specs index at `docs/specs/index.md` covers all specs regardless of location, with
a Status column. Readers use the index as the lookup point — they do not browse subdirectories.

**Naming.** Specs use slug-only filenames: `<topic>.md`. No date prefix, no numeric ID.

## Consequences

- A spec's status is visible without opening the file — its directory communicates it
- The index remains the single lookup point; subdirectory browsing is never required
- Moving a spec between directories (e.g. Accepted → In Progress → Live) is the mechanism
  for status transitions; the index entry's Status column must be updated in the same commit
- Deprecated and rejected specs leave `docs/specs/` entirely, keeping the active set clean
- No date prefix means the file is not anchored to when it was written — appropriate for
  living docs whose content should feel current, not historical
- No numeric IDs means specs are referenced by slug (`docs/specs/pipeline-dispatch.md`),
  not by number — cross-references in other docs must use the full path or slug

## Alternatives considered

**YAML frontmatter for status.** More structured and machine-readable. Rejected in favour of the
markdown header block used by ADRs — consistency within the project outweighs the marginal benefit
of parseable frontmatter for a field that changes rarely.

**Single flat directory with status only in the header block.** Simpler — no moves between
directories as status changes. Rejected because the active spec set (Proposed, Accepted, In
Progress) needs to be visually distinct from Live and archived specs. A flat directory mixes
aspirational specs with authoritative ones, making it unclear which describe current reality.

**Numeric IDs like ADRs.** ADR IDs provide stable references because ADRs are permanent —
`ADR 005` never moves or changes meaning. Specs move directories, get deprecated, and are
superseded. A numeric ID on a deprecated spec creates a dangling reference if anything cited
it by number. Slug-based references degrade more gracefully — a moved or renamed spec produces
a broken link that is detectable, while a deprecated ID produces a silent wrong reference.

**Date prefixes like plans.** Plans carry dates because they are ephemeral and the date anchors
them to the change they describe. Specs are living — a spec from 2026-03-08 that is still Live
in 2027 should not look like a 2026 document. The date belongs in the status header block as
authorship metadata, not in the filename.
