# Audit Report Format Spec

**Status:** Live
**Date:** 2026-03-09

Exhaustive description of the report formats all auditors and fixers must produce. Read this
before implementing or modifying any auditor, fixer, or orchestrator that reads their output.
For pipeline architecture — phases, agents, gates, data flow — see `docs/audit-pipeline.md`.
For the decisions behind the classification contract, see ADR 003 (`docs/decisions/`).

---

## Auditor Report Format

All auditors produce a report consisting of one finding block per finding, followed by a
single phase summary.

### Finding block

```
[CHECK N — CHECK NAME]
Severity: Error | Warning | Info
Doc-ID: <doc-id>
Found: One or two sentences — quote the relevant content or heading where useful.
Impact: One sentence on why this matters.
Recommendation: Concrete — name the target location, correct filename, missing section.
```

### Phase summary

One per report, at the end:

```
PHASE SUMMARY
Doc-ID: <doc-id>
Phase: <1 | 2 | 3> — <auditor name>
Findings: <N errors, N warnings, N info>
Context: <One sentence for the next phase. Omit if no findings.>
```

A report missing its `PHASE SUMMARY` block is treated as an agent failure — the document is
excluded from further phases and surfaced in the consolidation report under `Agent failure`.

---

## Fixer Report Format

All fixers produce one finding block per finding, followed by a fixer summary.

### Finding block

```
FINDING: <check number and name from audit report>
Doc-ID: <doc-id>
Audit severity: Error | Warning | Info
Summary: One sentence restating the finding.

Classification:
  fixable: yes | no
  scope: file | multi-file | structural
  reversible: yes | no

Recommendation:
  If fixable: yes — concrete instructions for doc-editor (exact text, target path).
  If fixable: no — user-facing escalation (what the problem is, options, reversibility).

Next-phase wait: yes | no
  If yes: what the next phase must wait for and why.
```

Phase 3 fixers always write `Next-phase wait: no`.

### Fixer summary

After all finding blocks:

```
FIXER SUMMARY
Doc-ID: <doc-id>
Autonomous fixes: <N>
  <One line per fix>
Escalations: <N>
  <One line per escalation>
Next-phase blocked until: <fix names or "nothing blocking">
```

---

## Fixer Classification Contract

Each fixer classifies every finding across three fields. See ADR 003 for why fixers classify
rather than apply changes directly.

| Field        | Values                               | Meaning                                    |
| ------------ | ------------------------------------ | ------------------------------------------ |
| `fixable`    | `yes` / `no`                         | Can this be resolved without user input?   |
| `scope`      | `file` / `multi-file` / `structural` | How many files the fix touches             |
| `reversible` | `yes` / `no`                         | Can it be undone with a single git revert? |

**Routing rule:** `fixable: yes` + `scope: file or multi-file` + `reversible: yes` →
autonomous, queued for `doc-editor`. Anything else → escalated to user.

---

## Phase 2 Classification Baselines

Defaults — fixer agents override with judgment when the specific case changes the
classification.

**`prose-fixer`:** All findings are autonomous — prose edits are file-scoped and reversible.

| Finding                      | fixable | scope | reversible |
| ---------------------------- | ------- | ----- | ---------- |
| Missing table intro sentence | yes     | file  | yes        |
| Sentence fragment            | yes     | file  | yes        |
| Passive voice                | yes     | file  | yes        |
| Missing contraction          | yes     | file  | yes        |
| Non-parallel list items      | yes     | file  | yes        |

**`structure-fixer`:**

| Finding                                   | fixable | scope | reversible |
| ----------------------------------------- | ------- | ----- | ---------- |
| Missing or malformed scoped opening       | yes     | file  | yes        |
| When-before-how ordering violated         | yes     | file  | yes        |
| Missing example section                   | yes     | file  | yes        |
| Missing prerequisite/consequences section | yes     | file  | yes        |
| Major task-oriented restructure           | no      | —     | —          |

**`convention-fixer`:**

| Finding                                        | fixable | scope | reversible |
| ---------------------------------------------- | ------- | ----- | ---------- |
| Convention missing negative constraint         | yes     | file  | yes        |
| Tool-generic rule                              | yes     | file  | yes        |
| Linter-enforceable — linter already configured | yes     | file  | yes        |
| Linter-enforceable — linter not yet configured | no      | —     | —          |
| Aspirational convention                        | no      | —     | —          |

**`content-fixer`:**

| Finding                                       | fixable | scope      | reversible |
| --------------------------------------------- | ------- | ---------- | ---------- |
| Verbatim duplication >3 lines                 | yes     | multi-file | yes        |
| Semantic duplication                          | no      | —          | —          |
| Misplaced passage — target file exists        | yes     | multi-file | yes        |
| Misplaced passage — target file doesn't exist | no      | —          | —          |
| Convention drift                              | no      | —          | —          |
