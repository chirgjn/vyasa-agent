# ADR Index

Index of all architectural decision records. Read a specific ADR when you are questioning or
extending a design decision, or when `docs/audit-pipeline.md` or another reference doc points
you here for the reasoning behind a choice.

---

All decision records, in order of creation:

| #                                                   | Title                                                                | Status            |
| --------------------------------------------------- | -------------------------------------------------------------------- | ----------------- |
| [001](001-three-phase-audit-pipeline.md)            | Three-phase audit pipeline with judgment gates                       | Accepted          |
| [002](002-file-based-agent-handoff.md)              | File-based agent handoff via structured reports                      | Accepted          |
| [003](003-fixer-classify-editor-executes.md)        | Fixers classify findings; doc-editor executes changes                | Accepted          |
| [004](004-guides-as-audit-source-of-truth.md)       | Auditors derive checks from guides, not auditing-anti-patterns.md    | Accepted          |
| [005](005-posix-append-claim-log.md)                | POSIX O_APPEND for concurrent claim log writes                       | Accepted          |
| [006](006-author-prefix-for-creation-agents.md)     | `author-*` prefix for content-creation agents                        | Accepted          |
| [007](007-two-log-separation-commands-vs-claims.md) | Two-log separation: commands vs. claims                              | Accepted          |
| [008](008-four-type-doc-taxonomy.md)                | Four-type documentation taxonomy: architecture, spec, plan, decision | Superseded by 010 |
| [009](009-spec-lifecycle-and-organisation.md)       | Spec lifecycle: statuses, directory layout, and naming               | Accepted          |
| [010](010-design-doc-as-fifth-taxonomy-type.md)     | Design doc as a fifth documentation type                             | Accepted          |
| [011](011-setup-skill-not-command.md)               | Setup exposed as a skill, not a command                              | Accepted          |
