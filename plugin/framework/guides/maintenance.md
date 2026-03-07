# Documentation Maintenance

How to keep docs accurate as the codebase evolves — generic guide for any project. For the overall strategy and where information belongs, see `framework/managing-project-information.md`. For vyasa's own repo-specific update triggers and enforcement layers, see `docs/maintenance.md`.

---

## Enforcement Hierarchy

Prefer mechanisms higher on this list — each level down drifts more:

```
1. Linter rules     — ruff, eslint, mypy (auto-enforced, zero drift)
2. Hooks            — pre-commit, agent hooks (auto-format on write/commit)
3. CI checks        — GitHub Actions, GitLab CI (catches what hooks miss)
4. Written rules    — `AGENTS.md`, docs/ (last resort — requires humans to read)
```

Before writing a rule, ask — "Can a tool enforce this instead?" Written rules are the last resort.

---

## Maintenance Principle

Update docs in the same PR as the code change they describe.

### Update triggers

| When you...                                                | Update                                                                                                                                                   |
| ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Add or rename a top-level directory                        | `AGENTS.md` structure map, `layout.md` Contents section                                                                                                  |
| Add or rename a sub-project, service, or bounded directory | Root `layout.md` Sub-Directories table, root `AGENTS.md` structure map                                                                                   |
| Add a new doc to `docs/`                                   | `AGENTS.md` routing table                                                                                                                                |
| Change build/test/lint commands                            | `AGENTS.md` commands section                                                                                                                             |
| Add a new domain or module                                 | `AGENTS.md` structure map, `docs/architecture.md`                                                                                                        |
| Change an API contract                                     | `docs/api.md`                                                                                                                                            |
| Add or change a convention                                 | `AGENTS.md` (if critical) or the relevant guide                                                                                                          |
| Remove a dependency or tool                                | Any doc that references it                                                                                                                               |
| Change a diagram's underlying system                       | The diagram, in the same PR                                                                                                                              |
| Accept a spec                                              | Write an ADR recording why this approach was chosen over alternatives                                                                                    |
| Approve a design doc                                       | Write a plan referencing the design; the design may be updated during planning                                                                           |
| Extract from an approved design (during or after planning) | Write ADRs for decisions with wider impact; write spec for solutions needing exhaustive detail; trim design and add links to Extracted artifacts section |
| Deprecate or reject a design doc                           | Scan for decisions worth keeping as ADRs; archive to `docs/archive/designs/` — don't delete                                                              |
| Complete a plan                                            | Write or verify ADRs for decisions with wider impact; move spec to `docs/specs/live/`; archive plan to `docs/archive/plans/`; update both indexes        |

---

## Reviewing Before Publishing

For high-stakes docs (architecture, API contracts, onboarding):

1. **Technical review** — expert checks accuracy
1. **Audience review** — someone unfamiliar checks clarity

One is better than none.

---

## Detecting Stale Docs

For the five staleness types, detection methods, and stale signals, see
`framework/guides/staleness.md`.

---

## Checklists

### New project setup

1. Write `README.md` — project purpose, install, usage, link to `AGENTS.md`
1. Write `AGENTS.md` — structure, commands, conventions, routing table (< 80 lines)
1. Create `docs/` with one file per major topic (setup, architecture, testing)
1. Each doc has a scoped opening (what it covers, when to read it)
1. Create `docs/decisions/` with `index.md` for architectural decision records
1. Create `docs/designs/` for active design docs
1. Create `docs/specs/` with `index.md`, `live/`, and `in-progress/` subdirectories
1. Create `docs/plans/` with `index.md` for active execution plans
1. Create `docs/archive/` with `designs/`, `plans/`, and `specs/` subdirectories
1. Create `docs/maintenance.md` with update triggers
1. Configure linters for style rules — don't write them in docs
1. Set up hooks for auto-formatting
1. Add CI checks as enforcement backstop
1. Run the 2-hop audit on 10 common queries — fix dead ends

### Auditing existing docs

1. Is `AGENTS.md` under 80 lines? If not, extract content to `docs/`
1. Does README explain the project and link to setup + `AGENTS.md`?
1. Does every file in `docs/` appear in `AGENTS.md`'s routing table?
1. Does every routing entry match an actual task (not just a filename)?
1. Are there duplicate explanations? Pick one canonical home
1. Do all `docs/` path references resolve? `grep -r 'docs/' AGENTS.md docs/`
1. Are historical artifacts in `docs/archive/`, not `docs/`?
1. Is anything in `AGENTS.md` enforceable by a linter or hook instead?
1. Are conventions actionable and specific (not "write clean code")?
1. Does every convention include what NOT to do?
1. Does every accepted spec have a corresponding ADR?
1. Does every Live spec still accurately describe the system?
1. Does every In Progress spec have an active plan? If plan is complete, move spec to `live/`
1. Does `docs/specs/index.md` reflect the current location and status of every spec?
1. Are any approved design docs archived that should still be live? (Archive only on deprecation or rejection)
1. Have approved design docs been extracted? (ADRs written, spec written, design trimmed)
1. Are deprecated or rejected designs in `docs/archive/designs/`, not deleted?
1. Run the 2-hop audit — fix dead ends
