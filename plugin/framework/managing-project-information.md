# Managing Project Information in a Git Repo

The documentation framework for AI-assisted projects — how to decide where information lives, structure a `docs/` layout, and keep docs from going stale. Start here if you're setting up docs for a new project or unsure where something belongs. For finding and fixing problems in existing docs, see `auditing-anti-patterns.md`.

---

## How to Use This Doc

- **Setting up a new project?** Read the Information Taxonomy and Directory Structure sections, then follow the Guides table at the bottom.
- **Unsure where something belongs?** Jump to the placement decision tree in the Information Taxonomy.
- **Writing a specific doc type?** Skip straight to the Guides table — each entry names the right guide.
- **Reviewing existing docs?** See `auditing-anti-patterns.md` instead.

---

## Why This Matters

`AGENTS.md` is loaded into every session. Every line competes with the actual task. Context length degrades LLM reasoning — even when the answer is present — and content in the middle gets ignored. Too much documentation causes the same mistakes as too little.

**Guiding principle:** For every line in `AGENTS.md`, ask: "Would removing this cause mistakes in most sessions?" If no, it belongs somewhere else.

---

## Before You Write: Does This Need to Exist?

Before creating any new doc: will it be read more than once, or by someone other than you? Explained something twice — write it down. Already exists elsewhere — link, don't duplicate.

**Exception: ephemeral docs.** For medium+ changes, create a plan before coding — a disposable plan is cheap, a mid-implementation course correction is not. See Ephemeral bucket below.

---

## The Information Taxonomy

Seven buckets. Each has a home. When you're unsure where something goes, find the subcategory that matches.

### 1. Navigation (`AGENTS.md` and `layout.md` — every session)

Information the agent needs on every task to orient itself.

**Test:** If an agent can't do its job without this on every task, it's navigation.

| Subcategory          | What it contains                                        | Example                                                        |
| -------------------- | ------------------------------------------------------- | -------------------------------------------------------------- |
| **Project identity** | One-line purpose, tech stack                            | "REST API for order management. Django + PostgreSQL + Celery." |
| **Structure map**    | Top-level directories with roles                        | `src/orders/ — order domain (models, services, serializers)`   |
| **Commands**         | Build, test, lint, typecheck invocations                | `python manage.py test orders.tests.test_api`                  |
| **Routing table**    | Intent → file mapping for docs                          | "When adding an API endpoint → `docs/api.md`"                  |
| **Directory layout** | Deep structural map of a directory and its sub-projects | `layout.md` at the root of each documented directory           |

`AGENTS.md` carries the terse structure map needed on every task. `layout.md` is the overflow — a deeper structural map for agents that need to understand a directory's internals before making changes. See the Directory Layout section below.

### 2. Conventions (`AGENTS.md` for critical; `docs/guides/` for detailed)

Rules that prevent mistakes automation can't catch.

**Test:** Linter can enforce it? → tool config. Applies to most sessions? → `AGENTS.md`. Only some modules? → subdirectory `AGENTS.md` or `docs/guides/`.

| Subcategory                  | What it contains                                             | Example                                                        |
| ---------------------------- | ------------------------------------------------------------ | -------------------------------------------------------------- |
| **Architectural boundaries** | Module isolation rules, import restrictions                  | "Never import across domains — use events or common/"          |
| **API contracts**            | Response shapes, error formats, versioning rules             | "All endpoints return `{data: ...}` or `{error: ...}`"         |
| **Data patterns**            | Idempotency requirements, migration rules, query conventions | "Celery tasks must be idempotent — assume any task runs twice" |
| **State management**         | Feature flags, config sources, caching rules                 | "Feature flags via django-waffle — never settings.py booleans" |
| **Domain rules**             | Business logic placement, validation boundaries              | "Services, not fat models — logic in services.py"              |

**Critical** (5–10 rules in `AGENTS.md`): patterns the agent would violate without being told. **Detailed** (`docs/guides/`): too long for `AGENTS.md`.

### 3. Reference (`docs/` — on demand, per-task)

Guides an agent reads when working on a specific kind of task.

**Test:** Too long for `AGENTS.md` but needed for a specific task? It's reference.

| Subcategory             | What it contains                                                  | Example file                  |
| ----------------------- | ----------------------------------------------------------------- | ----------------------------- |
| **Setup & environment** | Dev environment, dependencies, toolchain                          | `docs/setup.md`               |
| **Architecture**        | Module map, boundaries, data flow, system diagrams                | `docs/architecture.md`        |
| **Testing**             | Test patterns, fixtures, coverage rules, mocking conventions      | `docs/testing.md`             |
| **API**                 | Endpoint conventions, auth, pagination, request/response examples | `docs/api.md`                 |
| **Deployment**          | Deploy process, env config, infrastructure                        | `docs/deployment.md`          |
| **Workflows**           | Multi-step processes (PR review, release, on-call)                | `docs/workflows/pr-review.md` |

**Sub-types — pick one per doc, don't mix:** _Tutorial_ — gets a newcomer to a working state (clarity first). _Conceptual_ — explains how a system works, sacrifices edge cases for clarity. _Task reference_ — how to do a specific job (completeness first).

**Customer vs. provider docs:** Keep external user docs (usage, contracts) separate from internal docs (internals, maintenance).

**Code comments** are reference docs closest to what they describe. API comments: _what_ and _how to use_, no internals. Implementation comments: _why_, not _what_. Test: would someone unfamiliar misuse this without a comment?

### 4. Specs (`docs/specs/` — when implementing or verifying detailed behaviour)

Exhaustive, authoritative descriptions of how something works. Thorough enough that an
implementer never has to guess or look elsewhere. Living — updated when the thing they
describe changes, deprecated when superseded.

**Test:** Is this the complete, present-tense answer to "how does X work?" It's a spec.

| Subcategory         | What it contains                                           | Example file                      |
| ------------------- | ---------------------------------------------------------- | --------------------------------- |
| **Protocol specs**  | Exact formats, field meanings, valid values                | `docs/specs/claim-protocol.md`    |
| **Behaviour specs** | How a system behaves end-to-end, all cases covered         | `docs/specs/pipeline-dispatch.md` |
| **Interface specs** | Contracts between components — inputs, outputs, invariants | `docs/specs/report-format.md`     |

**Spec lifecycle:** Proposed → Accepted → In Progress → Live. Deprecated and Rejected specs
move to `docs/archive/specs/`. Status is recorded in a header block and communicated by
directory location. See `framework/guides/writing-specs.md`.

**Architecture docs use specs.** An architecture doc gives the system view and links to specs
for detail. Specs are not inlined into architecture docs.

### 5. Decisions (`docs/decisions/` — rarely, when questioning or extending a design)

The "why" behind non-obvious choices with wider impact — decisions others might revisit,
reverse, or need to apply consistently across the codebase. Survives long after the PR is
forgotten.

**Test:** Does this explain _why_ rather than _how_, and would others benefit from knowing
the reasoning — either to avoid re-litigating it or to apply the same thinking elsewhere?
It's a decision record.

| Subcategory                | What it contains                                                    | Example file                                   |
| -------------------------- | ------------------------------------------------------------------- | ---------------------------------------------- |
| **Technology choices**     | Why X over Y, evaluated trade-offs                                  | `docs/decisions/001-use-postgres.md`           |
| **Architectural patterns** | Why event sourcing, why monorepo, why this boundary                 | `docs/decisions/002-event-sourcing.md`         |
| **Structural decisions**   | Why the doc taxonomy, lifecycle, or organisation is shaped as it is | `docs/decisions/008-four-type-doc-taxonomy.md` |

**ADR format:** Status → Context → Decision → Consequences. Keep a consistent structure so decisions are scannable. See `framework/guides/writing-decision-records.md`.

### 6. Designs (`docs/designs/` — when proposing a change that needs approval before implementation)

The pre-approval record of a problem, alternatives considered, and the recommendation.
Design docs start fat (full context for reviewers). Approval unlocks planning; extraction
of ADRs and specs happens during or after planning, not at approval. The design may be
updated during planning as details are confirmed. Once extracted and trimmed, it remains
live as long as the system it describes is active — archived only on deprecation or
rejection.

**Test:** Does this capture a problem, compare approaches, and justify a recommendation for
an overarching goal? It's a design doc. Not if the approach is obvious and the change is
small — just write a plan. Not if a relevant decision is already in an ADR — reference it.

| Subcategory          | What it contains                                                           | Example file                        |
| -------------------- | -------------------------------------------------------------------------- | ----------------------------------- |
| **Feature designs**  | Problem, alternatives, recommendation for a new capability                 | `docs/designs/pipeline-dispatch.md` |
| **Refactor designs** | Problem, alternatives, recommendation for restructuring existing behaviour | `docs/designs/agent-handoff.md`     |

**When a design is approved:** write a plan. Extraction of ADRs and specs happens during
or after planning — not as a precondition to it. The design may be updated during planning
as implementation details become clearer. See `framework/guides/writing-design-docs.md`.

**When deprecating or rejecting a design:** scan for decisions worth keeping as ADRs, then
archive to `docs/archive/designs/` — don't delete. Plans shipping is not a trigger for
archival. See `framework/guides/writing-design-docs.md` § "Archiving, deprecating, and
rejecting".

**When a spec is accepted:** write an ADR recording why this approach was chosen over
alternatives. The spec answers how; the ADR answers why.

### 7. Ephemeral (`docs/archive/`, PR comments, task trackers — almost never after merge)

Artifacts useful during execution, near-zero value after. Create freely — the value is in the writing process (clarifying thinking, surfacing edge cases), not long-term shelf life.

**Test:** Will anyone read this after merge? If not, archive or delete — but don't skip writing it.

| Subcategory        | What it contains                                                                 | Where it goes                                                  |
| ------------------ | -------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| **Plans**          | Execution checklists for bounded changes — reference the spec, track file status | `docs/plans/` while active, `docs/archive/plans/` after        |
| **Execution logs** | Status trackers, progress updates                                                | `docs/archive/` or delete                                      |
| **PR artifacts**   | Review comments, fix logs, round-by-round feedback                               | PR comments or `docs/archive/pr-reviews/`                      |
| **Spike results**  | Exploration notes, prototype findings                                            | `docs/archive/` or inline in the decision record they informed |

**When archiving a plan:** write or verify an ADR exists for any non-obvious decisions made
during implementation, then move the spec to `docs/specs/live/`. The plan is ephemeral; the
spec and the reasoning behind it are not.

### Placement decision tree

```
Needed on EVERY task?
├─ Yes → AGENTS.md
└─ No
   ├─ Linter/hook/CI can enforce it? → Tool config
   ├─ Describes directory structure or sub-project layout? → layout.md
   ├─ How-to for a specific task? → docs/
   ├─ Explains WHY, not how? → docs/decisions/
   ├─ Convention too detailed for AGENTS.md? → docs/guides/
   ├─ High-level system structure, links to specs for detail? → docs/architecture/
   ├─ Exhaustive authoritative description of how something works? → docs/specs/
   ├─ Pre-approval problem + alternatives + recommendation for an overarching goal? → docs/designs/
   ├─ Execution checklist for a bounded change? → docs/plans/ → docs/archive/plans/ after
   ├─ Irrelevant after merge? → docs/archive/
   └─ Module-specific? → src/<module>/AGENTS.md
```

For a full list of common misplacements and how to fix them, see `auditing-anti-patterns.md` § "Misplaced Content."

---

## When Guidelines Conflict

Consult when two principles in this doc pull in opposite directions. Priority order — higher beats lower:

1. **Correctness over completeness.** Wrong docs are worse than missing docs. Delete rather than let it mislead.
1. **Discoverability over organization.** If the "right" place makes it unfindable, put it where agents look.
1. **Context cost over self-containment.** A 90-line `AGENTS.md` that links out beats a 200-line one that repeats reference content.
1. **No doc over bad doc.** A stale doc causes mistakes _and_ erodes trust in all other docs.

Common tensions:

| Tension                                                                   | Resolution                                                                                                                                                        |
| ------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| "Split at ~200 lines" vs. "no thin wrappers under ~15 lines"              | A 250-line doc with cohesive sections beats five 50-line files that only make sense together.                                                                     |
| "Self-contained" vs. "one canonical home"                                 | Repeat facts under 3 lines (a command, a path). Link for anything longer. Test: would you reliably update both places? If not, link.                              |
| "`AGENTS.md` < 80 lines" vs. "critical conventions belong in `AGENTS.md`" | 80 is a target, not a wall. 90 with the right conventions beats 60 missing one. At 120+, something doesn't belong.                                                |
| "Tool enforcement" vs. "convention for partially-enforceable things"      | If a tool catches 80%, configure the tool and write a convention only for the 20% it misses.                                                                      |
| "When before how" vs. "`AGENTS.md` is terse"                              | "When" wins. Terse means no justification paragraphs, not that you skip routing.                                                                                  |
| "One canonical home" vs. "redundancy within a document"                   | Cross-file: same fact in 3 files will diverge — one canonical home. Within-file: intentional redundancy (introduce, elaborate, summarize) is a writing technique. |

---

## Directory Structure

Use when setting up a project's doc layout or deciding where a new file lives.

```
project-root/
├── layout.md                        # Structural map of this directory (deep directory tree, sub-project links)
├── AGENTS.md                        # Navigation, commands, conventions (< 80 lines)
├── CLAUDE.md -> AGENTS.md           # Symlink for agents that read CLAUDE.md
├── README.md                        # Human entry point — what the product is, how to install/use it
├── docs/
│   ├── setup.md                     # Dev environment setup
│   ├── architecture.md              # Module map, boundaries, data flow
│   ├── testing.md                   # Test patterns, fixtures, coverage
│   ├── api.md                       # API contracts, endpoint conventions
│   ├── deployment.md                # Deploy process, env config
│   ├── workflows/                   # Multi-step process docs
│   │   ├── pr-review.md
│   │   └── release.md
│   ├── guides/                      # Detailed conventions by topic
│   │   ├── naming.md
│   │   ├── error-handling.md
│   │   └── database.md
│   ├── decisions/                   # Architectural Decision Records
│   │   ├── 001-use-postgres.md
│   │   └── 002-event-sourcing.md
│   ├── designs/                     # Design docs — live until deprecated or rejected
│   │   └── pipeline-dispatch.md
│   ├── plans/                       # Active implementation plans (archive after completion)
│   ├── maintenance.md               # Living docs checklist — what to update when
│   └── archive/                     # Post-merge artifacts
│       ├── designs/                 # Deprecated or rejected designs
│       ├── plans/
│       └── pr-reviews/
└── src/
    └── orders/AGENTS.md             # (optional) Module-specific conventions
```

### Naming and sizing

| Principle               | Rule                                                  | Example                                                   |
| ----------------------- | ----------------------------------------------------- | --------------------------------------------------------- |
| **Flat where possible** | Subdirectory at 3+ files — don't nest prematurely     | Don't create `testing/` for one file                      |
| **Name by question**    | What question it answers, not the system it describes | `setup.md` not `environment-configuration-and-tooling.md` |
| **One file per topic**  | Split at ~200 lines, merge at ~15 lines               | A 300-line `testing.md` → `testing/` subdirectory         |
| **Consistent naming**   | Lowercase, hyphen-separated, no version numbers       | `error-handling.md` not `ErrorHandling_v2.md`             |

### Scaling: monorepos and large projects

Each sub-project can have its own `layout.md`, `AGENTS.md`, and `docs/`. The root covers cross-project concerns. Don't duplicate — if it applies everywhere, it lives at the root.

**Structural discovery:** Agents find sub-projects by reading `layout.md` files. The root `layout.md` lists all sub-directories that have their own `layout.md`. Each sub-project's `layout.md` does the same for its children. This chain works at any depth — a sub-project can contain other sub-projects.

```
Multi-project repo layout:

repo-root/
├── layout.md              # lists all sub-projects and where they live
├── AGENTS.md              # repo-wide: setup, shared commands, shared conventions
├── docs/                  # repo-wide reference docs
├── services/
│   ├── layout.md          # describes services/, lists payments/ and auth/
│   ├── payments/
│   │   ├── layout.md      # describes payments/ internals
│   │   ├── AGENTS.md      # payments-specific conventions
│   │   └── docs/          # payments-specific reference docs
│   └── auth/
│       ├── layout.md      # describes auth/ internals
│       ├── AGENTS.md
│       └── docs/
└── tools/
    └── codegen/
        ├── layout.md      # describes codegen/ internals
        └── ...
```

```
Where does this convention live?

Does it apply to ALL sub-projects?
├─ Yes → Root AGENTS.md
└─ No
   ├─ Does it apply to one sub-project? → <project>/AGENTS.md
   ├─ Is it detailed (> 30 lines)? → <project>/docs/guides/
   └─ Does it apply to 2+ but not all? → Root docs/guides/ with scope note
```

---

## Guides

Writing guides for each doc type and topic. Use the placement decision tree above to identify what you're writing, then follow the link.

| When you are...                                                                                    | Read                                            |
| -------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| Writing, approving, or maintaining a design doc — problem, alternatives, recommendation, lifecycle | `framework/guides/writing-design-docs.md`       |
| Writing or auditing `AGENTS.md` — what belongs, sizing, routing table, subdirectory files          | `framework/guides/writing-agents-md.md`         |
| Creating or reviewing a `layout.md` — format, Contents section, sub-project traversal              | `framework/guides/writing-layout-md.md`         |
| Writing or reviewing a convention — when to add one, phrasing, what to delete                      | `framework/guides/writing-conventions.md`       |
| Creating a new doc or tutorial — when to create vs. extend, structure, sizing                      | `framework/guides/writing-reference-docs.md`    |
| Writing an ADR or extracting decisions from a design or plan                                       | `framework/guides/writing-decision-records.md`  |
| Writing or updating an architecture doc — system view, components, constraints                     | `framework/guides/writing-architecture-docs.md` |
| Writing or updating a spec — exhaustive authoritative description of how something works           | `framework/guides/writing-specs.md`             |
| Creating, updating, or reviewing a diagram — type selection, placement, sizing, orientation        | `framework/guides/diagrams.md`                  |
| Styling a Mermaid diagram — syntax, node tiers, contrast, palettes, common mistakes                | `framework/guides/mermaid.md`                   |
| Writing prose — voice, table formatting, list structure, sentence quality                          | `framework/guides/writing-prose-style.md`       |
| Setting up or auditing documentation maintenance — update triggers, enforcement, checklists        | `framework/guides/maintenance.md`               |
| Checking docs for staleness — script paths, commands, conventions, diagrams                        | `framework/guides/staleness.md`                 |
| Finding and fixing documentation problems — misplacement, discoverability, duplication             | `auditing-anti-patterns.md`                     |
