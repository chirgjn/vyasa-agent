# Writing AGENTS.md Files

How to write effective agent instruction files — `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `COPILOT.md`, and other formats that AI coding agents read for project context. The content guidelines are the same regardless of filename. This guide uses `AGENTS.md` as the canonical example.

For deciding _what goes in `AGENTS.md` vs. elsewhere_, see the Information Taxonomy in `framework/managing-project-information.md`. For writing the conventions that go inside `AGENTS.md`, see `framework/guides/writing-conventions.md`.

---

## The Hub: Root AGENTS.md

Read this section when setting up a new project, trimming a bloated `AGENTS.md`, debugging an agent that ignores conventions, or auditing what belongs here vs. elsewhere.

### Example

```markdown
# Acme API

REST API for order management. Django + PostgreSQL + Celery.

## Structure

src/orders/ — order domain (models, services, serializers)
src/inventory/ — inventory domain
src/common/ — shared utilities, base classes
tests/ — mirrors src/ structure
migrations/ — Django migrations (auto-generated, never hand-edit)

## Commands

python manage.py test # run tests
python manage.py test orders.tests.test_api # single test module
ruff check src/ tests/ # lint
mypy src/ # type-check

## Conventions

- Services, not fat models — business logic lives in src/<domain>/services.py,
  models only define fields and DB constraints
- All API endpoints return {"data": ...} on success, {"error": ...} on failure —
  never mix shapes
- Feature flags via django-waffle — check with flag_is_active(), never
  settings.py booleans
- Celery tasks must be idempotent — assume any task can run twice
- Never import across domains (e.g., orders importing from inventory) —
  use events or the common module

## Routing

**Working on docs?** See `docs/managing-project-information.md` — taxonomy, placement, and the full guide routing table.

| When you are...                          | Read                            |
| ---------------------------------------- | ------------------------------- |
| Setting up your dev environment          | `docs/setup.md`                 |
| Adding or modifying a domain module      | `docs/architecture.md`          |
| Writing or fixing tests                  | `docs/testing.md`               |
| Adding an API endpoint                   | `docs/api.md`                   |
| Naming things (variables, files, routes) | `docs/guides/naming.md`         |
| Handling errors or exceptions            | `docs/guides/error-handling.md` |
| Writing database queries or migrations   | `docs/guides/database.md`       |
| Deploying or configuring environments    | `docs/deployment.md`            |
| Reviewing a PR                           | `docs/workflows/pr-review.md`   |
```

~45 lines. Five sections: identity, structure, commands, conventions, routing table. Resist the urge to add "just one more section." (The example above shows the content of an `AGENTS.md` file.)

### What does NOT belong

| Content                                                                      | Why not                                               | Where instead                                      |
| ---------------------------------------------------------------------------- | ----------------------------------------------------- | -------------------------------------------------- |
| Style rules (indentation, quotes, imports)                                   | Linters enforce these                                 | `pyproject.toml`, `eslint.config.*`, `biome.json`  |
| Tool-generic instructions ("use jq for JSON")                                | Not project-specific                                  | Agent-specific global config                       |
| Living docs update checklist                                                 | Only relevant during structural changes               | `docs/guides/maintenance.md`                       |
| Detailed testing patterns                                                    | Too long for `AGENTS.md`                              | `docs/testing.md`                                  |
| Historical context ("We used to use Flask")                                  | Irrelevant to current work                            | `docs/decisions/`                                  |
| Onboarding walkthrough                                                       | Narrative doesn't belong in a terse reference         | `docs/setup.md` or README                          |
| Multi-paragraph explanations                                                 | `AGENTS.md` is a lookup table, not a tutorial         | `docs/` reference file                             |
| Routing entries pointing to specific volatile files (a plan, a spec by name) | File moves or archives — entry goes stale immediately | Point to the index (`docs/plans/index.md`) instead |

---

## Subdirectory `AGENTS.md` Files

AI coding agents load `AGENTS.md` files from subdirectories when working in those paths. Use these for module-specific conventions that don't apply project-wide.

### When to use subdirectory vs. guide

| Put it in `src/<module>/AGENTS.md`               | Put it in `docs/guides/`                |
| ------------------------------------------------ | --------------------------------------- |
| Convention only applies to this module           | Convention applies to multiple modules  |
| Under 30 lines                                   | Over 30 lines                           |
| Agent needs it when touching any file here       | Agent needs it for a specific task type |
| Module-specific overrides to project conventions | General patterns with examples          |

### Example

```markdown
# Orders Module

## Conventions

- Order state changes must go through OrderStateMachine — never set
  status directly on the model
- All order events publish to the `orders` Kafka topic — see
  src/orders/events.py for the schema
- Order IDs are ULIDs, not UUIDs — use ulid.new() from the ulid package
```

Keep under 30 lines. If they grow, the conventions probably belong in a `docs/` guide.

---

## Multi-Project Repos and layout.md

For repos containing multiple distinct projects, services, or packages, the `AGENTS.md` structure map alone becomes too shallow. Use `layout.md` alongside `AGENTS.md` to handle structural depth.

**The pattern:**

- Root `AGENTS.md` — repo-wide conventions, shared commands, terse structure map
- Root `layout.md` — deep directory tree, explicit sub-project inventory, traversal links
- Each sub-project gets its own `layout.md` and optionally its own `AGENTS.md`

`layout.md` sits directly in the directory it describes (not inside `docs/`). Agents discover sub-projects by reading `layout.md` and following its sub-directory references. This works at any nesting depth.

**What goes where:**

| Content                                           | Where                 |
| ------------------------------------------------- | --------------------- |
| Repo-wide commands (test, lint, build)            | Root `AGENTS.md`      |
| Shared conventions that apply to all sub-projects | Root `AGENTS.md`      |
| Deep directory tree with sub-project locations    | Root `layout.md`      |
| Sub-project-specific conventions                  | `<project>/AGENTS.md` |
| Sub-project internal structure                    | `<project>/layout.md` |
| Sub-project reference docs                        | `<project>/docs/`     |

The root `AGENTS.md` routing table should include an entry pointing to `layout.md` when the repo is multi-project:

```markdown
| Understanding the repo's project structure and layout | `layout.md` |
```

For the full `layout.md` format and guidance, see `framework/guides/writing-layout-md.md`.

---

## README vs `AGENTS.md`

This matters when you're deciding what goes in each file, or when one is growing too long and content needs to move.

|              | README.md                                         | `AGENTS.md`                                         |
| ------------ | ------------------------------------------------- | --------------------------------------------------- |
| **Audience** | Humans arriving via GitHub                        | AI coding agents                                    |
| **Purpose**  | What this is, why it exists, how to start         | How to navigate and work in this repo               |
| **Content**  | Project description, install, usage, contributing | Structure map, conventions, commands, routing table |
| **Tone**     | Explanatory, welcoming                            | Terse, directive                                    |
| **Length**   | As long as needed                                 | Under 80 lines                                      |

Link them to each other. Don't duplicate content between them — README explains choices, `AGENTS.md` lists facts. A 3-line README is a dead end. A 300-line `AGENTS.md` buries instructions.

Add a top-of-file redirect to README so agents prioritise `AGENTS.md` without reading through human-facing content first:

```markdown
> **AI agent?** Read [AGENTS.md](AGENTS.md) first.
```

Place it immediately after the title, before any other content. The tone is directive — consistent with how `AGENTS.md` itself is written. Don't soften it to "start with" or "see also"; agents need a clear instruction, not a suggestion.

---

## Multi-Agent Support: Symlinks for Agent-Specific Filenames

You need this when your project is used by multiple AI coding agents. Different agents look for different filenames, but maintaining separate files with the same content is harmful duplication that will diverge.

### Known formats

| Filename                          | Agent                       | Notes                          |
| --------------------------------- | --------------------------- | ------------------------------ |
| `AGENTS.md`                       | Convention (agent-agnostic) | Recommended canonical file     |
| `CLAUDE.md`                       | Claude Code                 | Also reads from subdirectories |
| `COPILOT.md`                      | GitHub Copilot              |                                |
| `.cursorrules`                    | Cursor                      | Root-level only                |
| `.github/copilot-instructions.md` | GitHub Copilot              | Alternative location           |
| `GEMINI.md`                       | Gemini CLI / Jules          |                                |

This table will grow as agents adopt new conventions. The pattern below handles any filename — you don't need to update the table to add a new symlink.

### The pattern

Write your canonical file as `AGENTS.md` and symlink for each agent you use:

```bash
ln -s AGENTS.md CLAUDE.md
ln -s AGENTS.md .cursorrules
# add more as needed
```

```
project-root/
├── AGENTS.md                # Canonical file (navigation, commands, conventions, routing)
├── CLAUDE.md -> AGENTS.md   # Symlink
├── .cursorrules -> AGENTS.md # Symlink
└── README.md                # Human entry point
```

### Why AGENTS.md as canonical

`AGENTS.md` is agent-agnostic — it signals "this file is for AI agents" without coupling to a specific tool. Most agents follow symlinks, so adding a new agent means adding one symlink rather than duplicating content.

### When NOT to use this pattern

- **Single-agent projects** — just use that agent's expected filename directly. The symlink adds indirection without value.
- **Agents that don't follow symlinks** — verify first. Use a copy with a comment noting the canonical source, or a build step to generate it.
- **Platform constraints** — Windows without developer mode doesn't support symlinks. Same fix: copy with a canonical source comment.
- **Agent-specific content** — if one agent needs materially different instructions (not just the same content in a different file), maintain separate files for that agent. This is rare.

### Content rules

The same rules apply regardless of filename — under 80 lines, five sections (identity, structure, commands, conventions, routing table). The filename changes; the content guidelines don't. See the example and guidelines in "The Hub: Root AGENTS.md" above.

After creating the symlinks, add a convention to `AGENTS.md` that documents the relationship — which file is canonical, what the symlinks are, and that the symlinks should never be edited directly:

```
- `AGENTS.md` is the canonical file; `CLAUDE.md` is a symlink (`ln -s AGENTS.md CLAUDE.md`) — never edit `CLAUDE.md` directly, never maintain two copies
```

This prevents a future agent or contributor from editing the symlink target thinking it's a separate file.

---

## Writing the Routing Table

The routing table needs attention when:

- You've added a new doc but agents aren't finding it — it's probably missing an entry
- An agent reads the wrong doc for a task — the entry is too vague or overloaded
- You've reorganized `docs/` — entries may point to moved or deleted files

The routing table maps tasks to files. It's the single most effective technique for documentation discoverability. "When you are..." works better than a flat list of files because it matches how agents think — they have a task, not a filename.

### Good vs. bad entries

| Entry                                                                     | Problem                                                       | Better                                                            |
| ------------------------------------------------------------------------- | ------------------------------------------------------------- | ----------------------------------------------------------------- |
| "API stuff"                                                               | Too vague — doesn't match a task                              | "Adding an API endpoint"                                          |
| "Read `docs/api.md`"                                                      | No task context — same as a file list                         | "When adding an API endpoint → `docs/api.md`"                     |
| "Setting up, configuring, or troubleshooting your environment"            | Overloaded — 3 different tasks                                | Split: setup → `setup.md`, troubleshooting → `troubleshooting.md` |
| "Implementing the payment redesign → `docs/plans/2026-01-15-payments.md`" | Points to a volatile file — goes stale when the plan archives | "Finding or tracking an active plan → `docs/plans/index.md`"      |

### Index vs. specific file

Point to a **specific file** when the file is stable and the task maps directly to it — `docs/setup.md`, `docs/api.md`, `docs/architecture.md`. These files live at predictable paths and are updated in place.

Point to an **index** when the content is volatile or lives in a set of files that changes over time:

- Active plans → `docs/plans/index.md` (individual plans archive after completion)
- Specs by topic → `docs/specs/index.md` (specs move directories as their status changes)
- Decision records → `docs/decisions/index.md` (new ADRs are added; old ones superseded)

An index entry survives as long as the index exists. A specific file entry dies when the file moves, archives, or is renamed.

### Entry richness

A routing entry works only if the agent reads it at the right moment. The task phrase triggers reading — but the description after the arrow determines whether the agent understands enough to act on it.

For high-value entries, more context is worth it. A bare filename tells the agent where to go but not why. A short description of what the file answers — taxonomy, placement decisions, the full routing table — tells the agent whether this is the right file for the task at hand:

| Less useful                                                | More useful                                                                                                                |
| ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `Finding or tracking an active plan → docs/plans/index.md` | `Finding or tracking an active plan → docs/plans/index.md` (lists all active plans; individual plans are linked from here) |
| `Working on docs → docs/managing-project-information.md`   | `Working on docs → docs/managing-project-information.md` — taxonomy, placement, and the full guide routing table           |

The description doesn't need to be long — one clause is enough. It should answer: "what does this file tell me, and does that match what I'm trying to do?"

**When to use prose instead of a table entry:** When an entire category of docs lives behind a well-maintained index or central guide, a prose line above the table is cleaner than a table entry and carries more context naturally:

```markdown
**Working on docs?** See `docs/managing-project-information.md` — taxonomy, placement, and the full guide routing table.
```

Use this when the category has its own internal routing (the index routes further), and adding individual table entries would duplicate what the index already provides. Don't use it as a substitute for entries that agents need at a glance — if an agent regularly jumps straight to `docs/testing.md`, keep that as a table entry even if a testing index exists.

### Coverage test

List 10 common tasks someone does in this repo. Can each one be found in the routing table in ≤ 2 hops from `AGENTS.md`? Missing entries are dead ends. Entries pointing to volatile files will become dead ends after the next reorganization.
