# Writing Specs

How to write, maintain, and retire specs — the exhaustive, authoritative descriptions of how
something works. For the taxonomy that defines specs and places them in `docs/specs/`, see
`framework/managing-project-information.md` § "Specs." For the decisions behind this lifecycle,
see ADR 009 and ADR 010 in `docs/decisions/`.

---

## What a spec is

A spec is the single complete answer to the question "how does this work?" It is thorough enough
that an implementer never has to guess or look elsewhere. Where an architecture doc gives the
system view and links out for detail, a spec provides the detail.

**Spec, not architecture doc.** If the content is high-level — components, responsibilities,
how they fit together — it belongs in an architecture doc that links to specs. If the content
is exhaustive — exact formats, specific values, every case covered — it's a spec.

**Spec, not design doc.** A design doc frames a problem, compares alternatives, and justifies
an approach — it is a pre-approval artifact. A spec is post-approval: it states the chosen
approach as exhaustive present-tense fact. A spec is typically written after a design doc is
approved. If you're still choosing between approaches, you're in design doc territory.

**Spec, not plan.** A spec states facts in present tense. A plan lists steps to execute. They
coexist for the same topic: the spec says how dispatch works; the plan says which files to
update and tracks their status. Never put execution checklists in a spec.

**Spec, not ADR.** A spec describes what and how. An ADR records why. A spec will often link
to ADRs for the reasoning behind its constraints — that reasoning does not belong in the spec
itself.

---

## Lifecycle and statuses

Specs move through statuses as they go from proposal to implementation to live fact.

| Status      | Meaning                                                | Location                  |
| ----------- | ------------------------------------------------------ | ------------------------- |
| Proposed    | Draft — not yet agreed on                              | `docs/specs/`             |
| Accepted    | Agreed on; a plan may or may not exist yet             | `docs/specs/`             |
| In Progress | A plan is actively executing against this spec         | `docs/specs/in-progress/` |
| Live        | Fully implemented; this spec describes current reality | `docs/specs/live/`        |
| Deprecated  | Superseded by another spec or approach                 | `docs/archive/specs/`     |
| Rejected    | Evaluated and not adopted                              | `docs/archive/specs/`     |

In Progress is expected to be brief — move a spec here only when a plan is actively executing,
and move it to Live as soon as the plan is complete.

**ADR at acceptance.** When a spec moves from Proposed to Accepted, write an ADR recording
the decision to adopt this approach — what problem it solves, what was rejected, and why.
The spec answers _how_; the ADR answers _why_. A spec without a corresponding ADR leaves the
reasoning implicit and reversible by the next contributor who questions it.

If the spec was written as part of planning an approved design, the design's Alternatives
and Recommendation sections are the source material — extract the reasoning, don't
duplicate it. The spec and its ADR are written during or after planning, not at design
approval.

Status transitions require two changes in the same commit: move the file to the correct
directory and update the spec's entry in `docs/specs/index.md`.

---

## Format

Use when writing a new spec — copy this skeleton and fill in each section.

```markdown
# [Topic] Spec

**Status:** Proposed | Accepted | In Progress | Live | Deprecated | Rejected
**Date:** YYYY-MM-DD

[1–2 sentences: what this spec covers and when to read it. Cross-link to the architecture
doc and relevant ADRs.]

---

## [Section]

Exhaustive coverage of one aspect. Every case. Every constraint. Every value that matters.
No "see the code" — if something is specified, it lives here.

...
```

The date is authorship date. Specs carry no date in the filename — the date in the header
is sufficient and does not make the spec look historical when it's still live.

---

## Writing a spec

**Cover everything.** A spec has failed if a reader must look somewhere else to answer a
question about the topic. If a detail lives only in code or in someone's head, it belongs
in the spec.

**Present tense throughout.** "Orchestrators process documents in fixed-size batches" — not
"orchestrators will process" or "orchestrators should process." A spec states facts, not
intentions.

**No execution steps.** Steps, checklists, and "do X then Y" sequences belong in plans.
A spec may describe a sequence of events in the system, but not a sequence of human actions.

**Link to ADRs for the why.** When a constraint exists for a non-obvious reason, state the
constraint and link to the ADR. Don't inline the rationale — that's what ADRs are for.

**Link from architecture docs.** After writing a spec, check whether any architecture doc
covers the same system at a higher level. If so, add a link from the architecture doc to
this spec. Architecture docs must not duplicate spec content — they reference it.

---

## Naming

Specs use slug-only filenames: `<topic>.md`. No date prefix, no numeric ID.

- No date prefix — specs are living docs; a date in the filename makes current content look
  historical. The authorship date belongs in the status header, not the filename.
- No numeric ID — unlike ADRs (which are permanent and benefit from stable numbering), specs
  move directories and can be deprecated. Slug-based references degrade gracefully when a
  spec moves; numeric references produce silent wrong references.

---

## Retiring a spec

**Deprecating.** When a spec is superseded by a new approach, update its status to
`Deprecated`, add a `Superseded by: docs/specs/<new-spec>.md` line to the header block,
move it to `docs/archive/specs/`, and update `docs/specs/index.md`. Do not delete it —
it may explain historical behaviour that other docs reference.

**Rejecting.** If a proposed spec is evaluated and not adopted, update its status to
`Rejected`, add a one-sentence note explaining why, move it to `docs/archive/specs/`, and
update `docs/specs/index.md`.

---

## Common mistakes

| Mistake                                               | Fix                                                                                                     |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Spec contains a "Files to change" table               | Move the execution checklist to a plan; the spec states facts only                                      |
| Spec says "should" or "will" instead of present tense | Rewrite as current fact; if it's not yet true, the spec status should be Proposed or Accepted, not Live |
| Architecture doc inlines spec-level detail            | Move the detail to a spec; replace with a link                                                          |
| Spec duplicates ADR rationale                         | Replace with a link to the ADR                                                                          |
| Status not updated after plan completes               | Move spec to `docs/specs/live/` and update index in the same commit as plan archival                    |
