# Auditing Documentation Anti-Patterns

A step-by-step guide for finding and fixing the documentation problems that cause agents (and humans) to make avoidable mistakes. Use this when docs exist but agents still struggle, when `AGENTS.md` has grown unwieldy, or as a periodic health check.

This guide is self-contained for conducting the audit. Links point to writing guides for fixing what you find, not for understanding how to detect it.

---

## How to Use This Guide

Work through each section in order. Each section targets one class of anti-pattern, gives you a detection method, and tells you how to fix what you find. Skip sections that don't apply to your project's current state.

**Time investment:** A full audit takes 30–60 minutes for a mid-sized project. Most value comes from the first four sections (README, `AGENTS.md` bloat, misplaced content, broken discoverability).

---

## 1. Dead-End README

**The problem:** README.md is the entry point for every human arriving via GitHub. A dead-end README — empty, a single title line, or missing links — means the project has no onboarding path outside of AI coding agents.

### Detection

Read README.md and check:

| Check                                     | Pass criteria                                                              |
| ----------------------------------------- | -------------------------------------------------------------------------- |
| Answers: what is this                     | At least one paragraph on purpose and value                                |
| Answers: why use it                       | Clear value proposition — what problem does it solve?                      |
| Answers: how to start                     | Reader can begin within one click                                          |
| Nothing else                              | No docs index, no internal architecture, no agent-facing content           |
| Links to `AGENTS.md`                      | Top-of-file redirect — agents read `AGENTS.md` first, before human content |
| Doesn't duplicate content from other docs | One-liner summaries with links, not repeated paragraphs                    |

**The audience test:** README serves one audience — a human arriving via GitHub who is deciding whether to use this project. For each section ask: "Does this help someone decide to use this, or get started after they have?" If the honest answer is "this is mainly for an existing user navigating the docs," it's a docs index entry. If "this is mainly for the AI agent," it belongs in `AGENTS.md`.

README should answer three questions and nothing more: what is this, why should I use it, how do I start. A flat list of every doc in the repo ("Writing guides," "Architecture," "Maintenance") answers none of those questions for a new arrival — it's a docs portal, and it belongs in `AGENTS.md`'s routing table, not README.

**The product test:** Many projects have both an external product (a plugin, a library, a CLI) and internal framework docs (the guidelines, architecture, and conventions that govern the project itself). README must lead with the external product — what a consumer installs and uses. Internal framework docs are secondary: mention them briefly if they're useful to a curious reader, but don't let them displace installation instructions or usage. A README that leads with internal theory and buries the install steps has the priority inverted.

Agent-facing content includes — but is not limited to:

- Conventions, structure maps, routing tables
- Agent inventory tables (what agents exist, when they trigger, how they're organized)
- Internal architecture details written for agent orientation (system internals, component design, dispatch flow)
- Sections explicitly labeled "For AI agents" — `AGENTS.md` already serves that audience; a README section addressing agents is redundant

The "For AI agents" section is a common false pass: it looks minimal (often just one line pointing to `AGENTS.md`), but it signals that the README is trying to serve two audiences. Replace it with a top-of-file redirect — see `framework/guides/writing-agents-md.md` § "README vs `AGENTS.md`" for the canonical pattern and phrasing.

### Common failures

| What you see                                                              | Fix                                                                                                                                 |
| ------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| 3-line README (just a title)                                              | Add a paragraph, link to setup and `AGENTS.md`                                                                                      |
| README is a docs index (flat list of every doc in the repo)               | Replace with: what the project is, why use it, how to start — routing belongs in `AGENTS.md`                                        |
| README leads with internal framework docs instead of the external product | Move installation and usage to the top; relegate internal guidelines to a brief "Framework" or "Contributing" section at the bottom |
| README duplicates setup instructions from `docs/setup.md`                 | Keep the canonical version in `docs/setup.md`, link from README                                                                     |
| README contains conventions or structure maps                             | Move to `AGENTS.md` — README is for humans, `AGENTS.md` is for agents                                                               |
| README contains a "For AI agents" section (any size)                      | Remove it — `AGENTS.md` already serves agents; a README that links to it doesn't need a dedicated section                           |
| README contains agent inventory tables or internal architecture details   | Reduce to a human-facing summary with a link to `AGENTS.md` for full detail                                                         |
| README doesn't link to `AGENTS.md`                                        | Add a top-of-file redirect: `> **AI agent?** Read [AGENTS.md](AGENTS.md) first.`                                                    |

---

## 2. AGENTS.md Bloat

**The problem:** Every line in `AGENTS.md` competes with the actual task. Research shows context length alone degrades reasoning — even when the answer is present. Content in the middle of long contexts gets ignored. Bloated files drown critical instructions in noise. The cost of too much documentation is the same as the cost of too little: the agent makes avoidable mistakes.

### Detection

Count the lines:

```bash
wc -l AGENTS.md
```

Then scan for these specific bloat patterns:

| Pattern                                           | How to spot it                                     | Example                                                    |
| ------------------------------------------------- | -------------------------------------------------- | ---------------------------------------------------------- |
| **Reference content masquerading as conventions** | Multi-paragraph explanations, tutorial-style prose | A 15-line explanation of how the auth system works         |
| **Tool-generic instructions**                     | Rules about tools, not about the project           | "Use `jq` for JSON", "Prefer `uv run` over `python`"       |
| **Process checklists**                            | Step-by-step lists for occasional workflows        | "When releasing: 1. Update version... 2. Tag..."           |
| **Linter-enforceable rules**                      | Style rules a tool already catches                 | "Use double quotes", "Sort imports"                        |
| **Module-specific conventions**                   | Rules that only apply in one directory             | "Order IDs must be ULIDs" (only relevant in `src/orders/`) |
| **Living docs update tables**                     | "Update X when Y changes" matrices                 | Useful but not needed on every session                     |

### Fixes

| What you found                               | Where it goes instead                                                       |
| -------------------------------------------- | --------------------------------------------------------------------------- |
| Reference content (> 3 lines of explanation) | `docs/` file with a routing table entry                                     |
| Tool-generic instructions                    | Agent-specific global config                                                |
| Process checklists                           | `docs/workflows/` or `docs/guides/maintenance.md`                           |
| Linter-enforceable rules                     | Tool config (`pyproject.toml`, `eslint.config.*`) — delete the written rule |
| Module-specific conventions                  | `src/<module>/AGENTS.md`                                                    |

**Target:** < 80 lines. 90 is acceptable if every line prevents a real mistake. 120+ means something doesn't belong.

For rewriting `AGENTS.md` after trimming, see `framework/guides/writing-agents-md.md`.

### Structure map and commands completeness

Beyond line count and bloat patterns, check that the two factual sections of `AGENTS.md` — structure map and commands — are accurate and complete:

**Structure map:**

```bash
# Compare structure map entries to actual top-level directories
ls -d */ | sort
# Then read the structure map section in AGENTS.md — do they match?
```

Any directory listed in the structure map that doesn't exist is stale. Any top-level directory that exists but isn't in the structure map is a gap (unless it's clearly generic like `node_modules/` or `.git/`).

**Commands:**

List the common operations for this project (test, lint, typecheck, build, format, deploy). Is each one in `AGENTS.md`'s commands section? Missing commands force agents to guess invocations — and they guess wrong (e.g., `pytest` instead of `python manage.py test`, `npm test` instead of `pnpm test`).

### Subdirectory AGENTS.md files

If `src/<module>/AGENTS.md` files exist, audit them too:

| Check                | Pass criteria                                                           |
| -------------------- | ----------------------------------------------------------------------- |
| Under 30 lines       | If longer, conventions probably belong in `docs/guides/`                |
| Module-specific only | No rules that apply project-wide (those belong in the root `AGENTS.md`) |
| Not stale            | Conventions still match the module's actual code patterns               |
| Not duplicating root | No repetition of root `AGENTS.md` conventions                           |

---

## 3. Misplaced Content

**The problem:** Information in the wrong bucket causes the same mistakes as missing information — but also erodes trust in docs that are correctly placed.

### Detection

All project information falls into six buckets. Each bucket has a home. For each file, determine which bucket its content belongs to:

| Bucket          | Test                                                                          | Home                                                                     |
| --------------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| **Navigation**  | Is it needed on EVERY task to orient the agent?                               | `AGENTS.md`                                                              |
| **Conventions** | Is it a rule that prevents mistakes automation can't catch?                   | `AGENTS.md` (critical, 5–10 rules) or `docs/guides/` (detailed)          |
| **Reference**   | Is it a how-to for a specific task type, too long for `AGENTS.md`?            | `docs/`                                                                  |
| **Specs**       | Is it the exhaustive authoritative description of how something works?        | `docs/specs/` (with status-based subdirectories)                         |
| **Decisions**   | Does it explain WHY rather than how, with wider impact or reuse potential?    | `docs/decisions/`                                                        |
| **Designs**     | Is it the pre-approval record of a problem, alternatives, and recommendation? | `docs/designs/` (live); `docs/archive/designs/` (deprecated or rejected) |
| **Ephemeral**   | Will anyone read this after the work is merged?                               | `docs/archive/` or delete                                                |

### The placement decision tree

For each piece of content you're unsure about:

```
Is it needed on EVERY task?
├─ Yes → `AGENTS.md` (Navigation or critical Convention)
└─ No
   ├─ Can a linter/hook/CI enforce it? → Tool config, not docs
   ├─ Is it a how-to for a specific task? → docs/ (Reference)
   ├─ Is it the exhaustive description of how something works? → docs/specs/ (Spec)
   ├─ Does it explain WHY, not how, with wider impact or reuse potential? → docs/decisions/ (Decision)
   ├─ Is it a pre-approval problem + alternatives + recommendation? → docs/designs/ (Design)
   ├─ Is it a convention too detailed for `AGENTS.md`? → docs/guides/ (Convention)
   ├─ Is it an execution checklist for a bounded change? → docs/plans/ (Ephemeral)
   ├─ Will it be irrelevant after merge? → docs/archive/ (Ephemeral)
   └─ Is it module-specific? → src/<module>/AGENTS.md
```

### Common misplacements to check

| Check                                                             | What's wrong                                                                         | Fix                                                                                                  |
| ----------------------------------------------------------------- | ------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| Critical convention buried in a 200-line guide                    | Agent never reads it, violates the rule                                              | Move to `AGENTS.md`                                                                                  |
| Ephemeral checklist sitting in `docs/`                            | Clutters navigation, goes stale                                                      | Move to `docs/archive/`                                                                              |
| Decision rationale mixed into reference docs                      | No one finds the "why" later                                                         | Extract to `docs/decisions/`                                                                         |
| Aspirational convention the codebase doesn't follow               | Agent gets confused by contradictions                                                | Enforce it (linter/CI) or delete it                                                                  |
| Completed plans still in `docs/plans/`                            | Dead weight after merge                                                              | Archive to `docs/archive/plans/`; move the spec they implemented to `docs/specs/live/`               |
| Design doc archived after plan ships                              | Design stays live — it's the lasting problem + reasoning record                      | Move back to `docs/designs/`; only archive on deprecation or rejection                               |
| Design doc still very long after plan is complete                 | Extraction hasn't happened yet                                                       | Extract ADRs for decisions with wider impact; write spec for exhaustive detail; trim design and link |
| Pre-approval exploration content inside a spec                    | Spec is polluted with options and alternatives that should be decided, not specified | Extract the comparison to a design doc; leave only the chosen approach in the spec                   |
| Spec-level detail inlined in an architecture doc                  | Architecture becomes unreadable; spec is incomplete                                  | Extract to `docs/specs/`, replace with a link                                                        |
| Spec in `docs/specs/` root with status `Live`                     | Wrong directory for its status                                                       | Move to `docs/specs/live/`; update `docs/specs/index.md`                                             |
| Setup instructions scattered across README, `AGENTS.md`, and docs | Three sources diverge, none is complete                                              | `docs/setup.md` as canonical; README links, `AGENTS.md` routes                                       |
| Module-specific rule in root `AGENTS.md`                          | Wastes context for every other module                                                | `src/<module>/AGENTS.md` or `docs/guides/`                                                           |
| Same concept explained in 3 files                                 | Wording diverges, agent gets conflicting info                                        | Pick one canonical home, others link                                                                 |

### Multi-project placement

For repos with multiple distinct projects, services, or packages, check an additional dimension. First read `layout.md` to understand the repo's project structure — it's the authoritative map of what lives where.

```
Does this convention apply to ALL projects in the repo?
├─ Yes → Root `AGENTS.md`
└─ No
   ├─ One project only? → <project>/AGENTS.md
   ├─ Detailed (> 30 lines)? → <project>/docs/guides/
   └─ 2+ projects but not all? → Root docs/guides/ with a scope note
```

Common multi-project misplacements: a project-specific convention in the root `AGENTS.md` (wastes context for every other project), the same convention duplicated across multiple project `AGENTS.md` files (should be in root), or structural information about sub-projects buried in `AGENTS.md` prose instead of described in `layout.md`.

**layout.md check:** Every project boundary should have a `layout.md`. If an agent had to discover sub-project structure by exploring the filesystem rather than reading `layout.md`, the file is missing or incomplete.

---

## 4. Broken Discoverability

**The problem:** A doc that exists but can't be found causes the same mistakes as a missing doc.

You have a discoverability problem when:

- An agent makes a mistake that a doc already covers — it didn't find the doc
- You answer the same question repeatedly that's documented somewhere — the path to it is broken
- An agent reads the wrong doc for a task — the routing is ambiguous
- A doc exists in `docs/` but has no routing table entry — it's an orphan

### Detection: The routing table audit

The docs directory can vary per project — check `layout.md` to find where docs live before running these. Replace `docs` with your project's actual docs directory.

```bash
# 1. Find orphan files — docs with no routing table entry
# Replace "docs" with your project's docs directory (check layout.md)
find docs -name "*.md" -not -path "docs/archive/*" | while read f; do
  grep -qF "$f" AGENTS.md || echo "ORPHAN: $f"
done

# 2. Find broken references — routing entries pointing to moved/deleted files
grep -oE '`[^`]+\.md`' AGENTS.md | tr -d '`' | while read f; do
  [ -f "$f" ] || echo "BROKEN: $f"
done

# 3. Find broken cross-references inside docs
# Replace "docs" with your project's docs directory
grep -rnoE '`[^`]+\.md`' docs/ | while IFS=: read file line match; do
  ref=$(echo "$match" | tr -d '`')
  [ -f "$ref" ] || echo "BROKEN in $file:$line → $ref"
done

# 4. In multi-project repos — check each sub-project's AGENTS.md too
# Find all AGENTS.md files and run checks against each
find . -name "AGENTS.md" -not -path "./.git/*" | while read agents; do
  dir=$(dirname "$agents")
  echo "--- Checking $agents ---"
  grep -oE '`[^`]+\.md`' "$agents" | tr -d '`' | while read f; do
    [ -f "$dir/$f" ] || [ -f "$f" ] || echo "BROKEN in $agents: $f"
  done
done
```

Or do it manually:

1. Read `layout.md` to identify where docs live for each project in the repo.
1. For each project: list every file in its docs directory. Does each one appear in that project's `AGENTS.md` routing table?
1. List every path in `AGENTS.md`'s routing table. Does each one resolve to an actual file?
1. List every cross-reference inside docs files. Do they all resolve?

### Detection: The 2-hop audit

Any question should be answerable in at most 2 hops from the entry point:

```
AGENTS.md  →  docs/testing.md  →  (specific pattern, if needed)
   hop 0          hop 1                    hop 2
```

Each hop is a context switch. At 3+ hops, agents lose track of the original question. Dead ends mean the routing table is missing an entry. 3-hop paths mean an intermediate doc is missing a cross-link.

Pick 10 common tasks someone does in this repo. For each, trace the path from `AGENTS.md` to the answer:

| Task                              | Path                                               | Hops     | Pass?  |
| --------------------------------- | -------------------------------------------------- | -------- | ------ |
| "How do I run tests?"             | `AGENTS.md` → commands section                     | 0        | Yes    |
| "Where do I put a new service?"   | `AGENTS.md` → `docs/architecture.md`               | 1        | Yes    |
| "Why do we use Postgres?"         | `AGENTS.md` → `docs/decisions/001-use-postgres.md` | 1        | Yes    |
| "How do I handle errors?"         | `AGENTS.md` → ???                                  | dead end | **No** |
| "How do I handle a Celery retry?" | `AGENTS.md` → ??? → ??? → guide                    | 3 hops   | **No** |

**Rules:**

- 0–2 hops: good
- Dead end: routing table is missing an entry
- 3+ hops: an intermediate doc needs a cross-link or `AGENTS.md` needs a direct entry

### Detection: Routing entry quality

Good routing entries describe tasks, not filenames:

| Entry                                                          | Problem                               | Better                                        |
| -------------------------------------------------------------- | ------------------------------------- | --------------------------------------------- |
| "API stuff"                                                    | Too vague — doesn't match a task      | "Adding an API endpoint"                      |
| "Read `docs/api.md`"                                           | No task context — same as a file list | "When adding an API endpoint → `docs/api.md`" |
| "Setting up, configuring, or troubleshooting your environment" | Overloaded — 3 different tasks        | Split into separate entries per task          |

### Fixes

| Problem                                 | Fix                                                                      |
| --------------------------------------- | ------------------------------------------------------------------------ |
| Orphan file (no routing entry)          | Add a "When you are..." entry to `AGENTS.md`                             |
| Broken reference (file moved/deleted)   | Update or remove the reference                                           |
| Dead end (task can't be traced)         | Add routing entry or cross-link                                          |
| 3+ hops                                 | Add a direct link from `AGENTS.md` or add cross-link in intermediate doc |
| Ambiguous routing (two entries overlap) | Make each entry's task scope distinct                                    |

### Detection: Missing cross-link disambiguation

When two docs cover related but distinct topics, each should acknowledge the other and explain when to use which. Without this, agents pick the wrong doc or read both unnecessarily.

Look for doc pairs that cover related ground — common candidates:

- `setup.md` / `deployment.md`
- `onboarding.md` / `quickstart.md`
- `api.md` / `error-handling.md`
- `architecture.md` / module-specific guides
- Any two docs that appear in adjacent routing table entries

For each pair, check: does each doc's opening explain when to read it vs. the other?

A doc pair without disambiguation looks like:

```markdown
<!-- onboarding.md — no mention of quickstart.md -->

# Onboarding

How to get started with the platform...
```

A doc pair with disambiguation looks like:

```markdown
<!-- onboarding.md -->

# Onboarding

How to connect your own data platform to the system.
For a quick local test with sample data, see `docs/quickstart.md` instead.
```

For writing good routing table entries, see `framework/guides/writing-agents-md.md` § "Writing the Routing Table."

---

## 5. Thin and Bloated Files

**The problem:** Files that are too small add indirection without value. Files that are too large bury information.

### Detection

Replace `docs/` with the actual docs directory for your project (check `layout.md`).

```bash
# Find thin files (under 15 lines)
find docs/ -name "*.md" -exec awk 'END{if(NR<15) print FILENAME, NR, "lines"}' {} \;

# Find bloated files (over 200 lines)
find docs/ -name "*.md" -exec awk 'END{if(NR>200) print FILENAME, NR, "lines"}' {} \;
```

### Sizing rules

| Length          | Action                                                            |
| --------------- | ----------------------------------------------------------------- |
| Under ~15 lines | Too thin — merge into a related doc or delete                     |
| 15–200 lines    | Ideal range for a single reference doc                            |
| 200–400 lines   | Consider splitting, but only if sections are independently useful |
| Over 400 lines  | Split into a subdirectory. Each file should stand alone           |

Don't split if it would create fragments. A 250-line doc with cohesive sections is better than five 50-line files that only make sense together. When splitting, make sure each resulting file has its own scoped opening and is independently useful — don't create files that only make sense read in sequence.

### Anti-patterns to check

| Pattern                        | Example                                                                   | Fix                                                                                 |
| ------------------------------ | ------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| **Index-only file**            | 13-line file that just lists links to other files                         | Delete — `AGENTS.md`'s routing table already does this                              |
| **"See other-doc.md" wrapper** | 12-line file whose only content is a redirect                             | Merge content into the target, delete the wrapper                                   |
| **Same concept in 3 files**    | Project explained differently in README, onboarding, and quickstart       | Pick one canonical home, others link with one-liner                                 |
| **Monolith doc**               | 400-line testing guide covering unit, integration, e2e, fixtures, mocking | Split into `docs/testing/` subdirectory — but only if each file stands alone        |
| **Premature subdirectory**     | A `docs/testing/` directory containing one file                           | Flatten back into `docs/testing.md`. A subdirectory earns its existence at 3+ files |

### File naming

Check every filename in `docs/` against these rules:

| Rule                          | Bad                                        | Good                                     |
| ----------------------------- | ------------------------------------------ | ---------------------------------------- |
| Lowercase, hyphen-separated   | `ErrorHandling_v2.md`                      | `error-handling.md`                      |
| Named by question, not system | `environment-configuration-and-tooling.md` | `setup.md`                               |
| No version numbers in name    | `api-v2.md`                                | `api.md` (use content versioning inside) |
| Consistent with neighbors     | `setup.md`, `Testing-Guide.md`, `api.md`   | All same format                          |

For structuring the files you create or restructure, see `framework/guides/writing-reference-docs.md`.

---

## 6. Stale Content

**The problem:** Stale docs are worse than missing ones — they actively mislead. A missing doc causes one kind of mistake; a stale doc causes that mistake _and_ erodes trust in all other docs.

### Detection

| Method                   | What it catches                             | How to check                                                                                               |
| ------------------------ | ------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Grep for file paths      | References to moved/deleted files           | `grep -rn 'docs/\|src/\|scripts/' docs/ AGENTS.md` — verify each path exists                               |
| Run every command        | Build/test/lint commands that error         | Execute each command listed in `AGENTS.md`'s commands section                                              |
| Convention-vs-code check | Aspirational rules the codebase violates    | For each convention, find 2–3 call sites in the code — do they follow the rule?                            |
| Diagram check            | Diagrams showing removed/renamed components | For each Mermaid/diagram, compare nodes and edges to current code structure                                |
| Artifact check           | Historical files sitting in active docs     | List files in `docs/plans/` and `docs/` — are any execution logs, status trackers, or PR review artifacts? |

### The enforcement hierarchy

Prefer mechanisms higher on this list — each level down drifts more:

```
1. Linter rules     — ruff, eslint, mypy (auto-enforced, zero drift)
2. Hooks            — pre-commit, agent hooks (auto-format on write/commit)
3. CI checks        — GitHub Actions, GitLab CI (catches what hooks miss)
4. Written rules    — AGENTS.md, docs/ (last resort — requires reading and following)
```

Before writing a documentation rule, ask — "Can a tool enforce this instead?" If yes, configure the tool. Written rules are the enforcement mechanism of last resort. If a tool catches 80% of violations, configure the tool and write a convention only for the 20% it misses.

### Decision records

If `docs/decisions/` exists, check each ADR:

| Check                                     | What's wrong                                              | Fix                                           |
| ----------------------------------------- | --------------------------------------------------------- | --------------------------------------------- |
| Decision was later reversed               | ADR says "use Redis" but the project switched to Postgres | Update status to "Superseded by [new ADR]"    |
| Decision contradicts current architecture | ADR describes a pattern the codebase no longer follows    | Update status or archive                      |
| No status field                           | Reader can't tell if this decision is still active        | Add status (Accepted, Superseded, Deprecated) |

Stale decision records are less damaging than stale conventions — agents rarely read `docs/decisions/` unprompted — but they mislead anyone investigating _why_ the architecture looks the way it does.

### Aspirational conventions

The convention-vs-code check above catches aspirational conventions — rules the project claims to follow but doesn't. These are the most damaging form of staleness because they make agents produce code that contradicts the existing codebase. For the decision tree on whether to enforce, fix, or delete an aspirational convention, see §7 "Convention Quality" below.

### Update triggers

Documentation should update in the same PR as the code change it describes. Check whether these triggers have been followed:

| When someone...                        | They should have updated                                               |
| -------------------------------------- | ---------------------------------------------------------------------- |
| Added or renamed a top-level directory | `AGENTS.md` structure map, `layout.md` Contents section                |
| Added a new sub-project or service     | Root `layout.md` Sub-Directories table, root `AGENTS.md` structure map |
| Added a new doc to a docs directory    | The nearest `AGENTS.md` routing table                                  |
| Changed build/test/lint commands       | `AGENTS.md` commands section                                           |
| Added a new domain or module           | `AGENTS.md` structure map, `layout.md`, `docs/architecture.md`         |
| Changed an API contract                | `docs/api.md`                                                          |
| Added or changed a convention          | `AGENTS.md` (if critical) or the relevant guide                        |
| Removed a dependency or tool           | Any doc that references it                                             |
| Changed a diagram's underlying system  | The diagram                                                            |

For setting up ongoing maintenance processes, see `framework/guides/maintenance.md`.

---

## 7. Convention Quality

**The problem:** Vague or incomplete conventions don't prevent the mistakes they're meant to prevent. An agent can't follow a rule it can't act on.

### When conventions should exist

Conventions should only exist when an agent (or human) has actually made the mistake. Preemptive conventions go stale because no one enforces what hasn't broken yet.

```
Should this convention exist?

Has an agent or contributor actually made this mistake?
├─ No → Delete it. Wait until the mistake happens.
└─ Yes
   ├─ Can a linter, hook, or CI rule catch it? → Configure the tool, delete the written rule.
   └─ No → Keep it, but make sure it's well-phrased (see below).
```

### Detection

For each convention in `AGENTS.md`, check:

| Check                                 | Failure mode                                   | Example of failure                                                              |
| ------------------------------------- | ---------------------------------------------- | ------------------------------------------------------------------------------- |
| Does it say what NOT to do?           | Doesn't prevent the actual mistake             | "Use services for business logic" (doesn't say: not in models, not in views)    |
| Is it specific and actionable?        | Too vague to follow                            | "Write clean code", "Keep functions small", "Follow best practices"             |
| Does it say where it applies?         | Gets applied in the wrong context              | "Use events for communication" (between domains? between services? everywhere?) |
| Can a linter enforce it?              | Written rule will drift                        | "Sort imports" → configure `isort` instead                                      |
| Does the codebase actually follow it? | Aspirational, contradicts reality              | "All functions must have docstrings" but most don't                             |
| Is it tool-generic?                   | Not project-specific, belongs in global config | "Use pnpm, not npm"                                                             |

### The aspiration test

For each convention where the codebase doesn't follow it:

```
Does the codebase actually follow this convention?
├─ Yes → Keep it
└─ No
   ├─ Can you enforce it with a linter/CI now? → Configure the tool, delete the written rule
   ├─ Is the convention still the right target? → Fix the code, keep the convention
   └─ Has the codebase moved on? → Delete the convention
```

Aspirational conventions are the most damaging anti-pattern because they make agents produce code that contradicts the existing codebase. The agent follows the rule, the code review rejects it because nothing else in the project works that way, and everyone wastes time.

### Fixes

Rewrite each failing convention to follow the pattern: **what to do + where it applies + what NOT to do**.

| Before                                 | After                                                                                                            |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| "Use services for business logic"      | "Services, not fat models — business logic lives in `services.py`, models only define fields and DB constraints" |
| "Be careful with cross-domain imports" | "Never import across domains — use events or the common module"                                                  |
| "Tests should be fast"                 | "Integration tests must complete in under 5s — mock external services, use in-memory SQLite"                     |
| "Use django-waffle for feature flags"  | "Feature flags via django-waffle — check with `flag_is_active()`, never `settings.py` booleans"                  |

Things that should never be conventions — delete if found:

```
# Too vague to be actionable:
- Write clean code
- Follow best practices
- Keep functions small

# Belongs in linter config:
- Use double quotes for strings          → ruff rule Q000
- Max line length 88 characters          → ruff rule E501
- Sort imports with isort                → ruff rule I001

# Tool-generic (belongs in agent-specific global config):
- Use pnpm, not npm
- Use uv run, not python directly
```

For convention categories and more phrasing examples, see `framework/guides/writing-conventions.md`.

---

## 8. Duplication

**The problem:** Duplicated content diverges. Two sources for the same fact will eventually contradict each other, and agents won't know which to trust.

### Detection

Look for these duplication patterns:

1. **Same setup instructions** in README, `AGENTS.md`, and `docs/setup.md`
1. **Same commands** listed in `AGENTS.md` and a separate `docs/commands.md`
1. **Same "what is this project"** explanation in README, onboarding doc, and quickstart
1. **Same convention** phrased differently in `AGENTS.md` and a guide
1. **`AGENTS.md` duplicating global config** — tool-generic rules that also live in agent-specific global config

A quick grep can surface candidates — substitute your project's module paths and tool commands:

```bash
# Find repeated module paths (suggests content about the same topic in multiple places)
grep -rn 'src/orders\|src/inventory' docs/ AGENTS.md | sort

# Find repeated command strings
grep -rn 'pytest\|ruff check\|mypy' docs/ AGENTS.md | sort
```

### The repetition test

For each piece of duplicated content:

```
Is it under 3 lines (a command, a path, a one-liner)?
├─ Yes → Repeating is fine — it saves a hop and rarely drifts
└─ No
   ├─ If this content changes, would you reliably update ALL copies?
   │   ├─ Yes → Acceptable duplication (rare)
   │   └─ No → Pick one canonical home, others link
   └─ Delete all but the canonical version
```

**Examples of acceptable repetition:** A one-line test command in both `AGENTS.md` and `docs/testing.md`. A file path repeated in a routing table and the doc it routes to.

**Examples of harmful duplication:** A 10-line explanation of the project purpose in three different files. The same convention written in slightly different words in `AGENTS.md` and a guide. Setup instructions split across README and `docs/setup.md` with each having pieces the other lacks.

**Note:** Grepping catches path and command duplication, but content duplication — the same concept explained in different words — requires reading docs side by side. Focus on doc pairs that cover related topics (setup/deployment, onboarding/quickstart, conventions in `AGENTS.md` vs. the guide they link to).

---

## 9. Missing "When" Framing

Check this after fixing structural problems (§1–§8) — framing issues matter most once the right content is in the right files.

Sections that don't open with "when" force the reader to read the whole section to decide if it applies. Agents waste context and make wrong decisions about relevance.

### Detection

For each section in each doc, read the first 2–3 lines. Can you answer "does this apply to me right now?" If not, the "when" is missing or buried.

Common failures:

| What you see                                       | What's wrong                                            | Fix                                                                 |
| -------------------------------------------------- | ------------------------------------------------------- | ------------------------------------------------------------------- |
| Section opens with background/history              | "When" is buried after a paragraph of context           | Move "when" to the first line, background after                     |
| Section opens with instructions immediately        | Reader can't tell if this section applies to their task | Add a one-line "You need this when..." opener                       |
| Section opens with "Why" (justification paragraph) | "Why" is useful but doesn't route — "when" routes       | Lead with "when", follow with one-clause "why"                      |
| No scoped opening on the doc itself                | Reader doesn't know if they're in the right doc         | First 1–2 lines should say what this doc covers and when to read it |

### The framing pattern

Every section should open with **when** (routing signal), then optionally a succinct **why** (one clause for stakes):

```markdown
# Good

"You need this when writing integration tests that hit the database —
mocking hides real query bugs."

# Bad

"Database testing is important because production bugs are expensive.
There are several approaches to testing database interactions..."
```

**"When" and "why" serve different purposes:**

- **When** tells the reader "does this apply to me right now?" in 1–2 lines. Every section needs it.
- **Why** (one clause) conveys stakes — "should I care now or later?" The full "why" (trade-offs, alternatives) belongs in the body.

---

## Audit Checklist

A condensed version for quick reference. Check each item; fix before moving to the next section.

### README (§1)

- [ ] Answers: what is this, why use it, how to start — and nothing more
- [ ] Not a docs index (no flat lists of every guide, writing doc, or internal reference)
- [ ] Leads with the external product (plugin, library, CLI), not internal framework docs
- [ ] Links to `AGENTS.md` via a top-of-file redirect, not a dedicated section at the bottom
- [ ] Doesn't duplicate content from other docs
- [ ] No agent-facing content — every section passes the test: "Would a human arriving via GitHub need this?"
- [ ] No "For AI agents" section (redundant with `AGENTS.md`)

### layout.md health

- [ ] Root `layout.md` exists — if not, create it
- [ ] Contents section covers meaningful structure to sufficient depth (not just immediate children)
- [ ] Every sub-directory with its own `layout.md` appears in the Sub-Directories table
- [ ] "What Lives Here" and "What Doesn't Live Here" sections present where boundaries are non-obvious
- [ ] All directory paths in Contents section exist on disk (no stale entries)
- [ ] Sub-project `layout.md` files back-reference their parent
- [ ] No structural information about sub-projects buried in `AGENTS.md` prose that belongs in `layout.md`

### AGENTS.md health (§2)

- [ ] Under 80 lines (90 acceptable, 120+ needs trimming)
- [ ] No reference content (multi-paragraph explanations, tutorial prose)
- [ ] No tool-generic instructions (belongs in global config)
- [ ] No linter-enforceable rules (belongs in tool config)
- [ ] No module-specific conventions (belongs in subdirectory `AGENTS.md`)
- [ ] No process checklists or living docs update tables (belongs in `docs/workflows/` or `docs/guides/maintenance.md`)
- [ ] Structure map matches actual top-level directories
- [ ] Commands section covers all common operations (test, lint, typecheck, build)
- [ ] Subdirectory `AGENTS.md` files under 30 lines, module-specific only, not stale

### Content placement (§3)

- [ ] No critical conventions buried in long guides (move to `AGENTS.md`)
- [ ] No ephemeral checklists in `docs/` (move to `docs/archive/`)
- [ ] No decision rationale mixed into reference docs (extract to `docs/decisions/`)
- [ ] No aspirational conventions the codebase doesn't follow (enforce or delete)
- [ ] Historical artifacts in `docs/archive/`, not `docs/`
- [ ] No duplicated setup instructions across README, `AGENTS.md`, and docs
- [ ] No spec-level detail inlined in architecture docs (extract to `docs/specs/`, replace with link)
- [ ] Every spec is in the correct directory for its status (`docs/specs/`, `docs/specs/in-progress/`, `docs/specs/live/`, or `docs/archive/specs/`)
- [ ] Every accepted spec has a corresponding ADR in `docs/decisions/`
- [ ] `docs/specs/index.md` status and location matches every spec's actual status and location
- [ ] No approved design docs archived after the plan shipped (designs stay live; archive only on deprecation or rejection)
- [ ] Approved design docs whose plans are complete have been extracted (ADRs written, spec written, design trimmed)
- [ ] Deprecated or rejected designs are in `docs/archive/designs/`, not deleted
- [ ] Pre-approval exploration (options, alternatives) is not inside a spec or architecture doc

### Routing and discoverability (§4)

- [ ] Every file in `docs/` has a routing table entry in `AGENTS.md`
- [ ] Every routing table entry resolves to an existing file
- [ ] Every routing entry describes a task ("When you are..."), not a filename
- [ ] 10 common tasks traced from `AGENTS.md` in ≤ 2 hops
- [ ] No dead ends in cross-references between docs
- [ ] No ambiguous entries (two entries that could match the same task)
- [ ] Related doc pairs cross-link with disambiguation ("this is for X, that is for Y")

### File health (§5)

- [ ] No files under 15 lines (merge into related doc or delete)
- [ ] No files over 200 lines without clear, independently useful sections
- [ ] No index-only files that just list links (`AGENTS.md` already routes)
- [ ] No redirect wrappers ("see other-doc.md")
- [ ] No premature subdirectories (< 3 files)
- [ ] All filenames lowercase, hyphen-separated, no version numbers
- [ ] Filenames describe the question they answer, not the system they describe

### Content accuracy (§6)

- [ ] All file path references resolve (`grep -r 'docs/' AGENTS.md docs/`)
- [ ] All commands in `AGENTS.md` actually run without errors
- [ ] No stale diagrams showing removed/renamed components
- [ ] Recent code changes reflected in corresponding docs (check update triggers)
- [ ] Decision records in `docs/decisions/` have accurate status (not superseded or reversed without noting it)

### Convention quality (§7)

- [ ] Every convention includes what NOT to do
- [ ] Every convention is specific and actionable (not "write clean code")
- [ ] Every convention specifies where it applies
- [ ] No conventions a linter could enforce instead
- [ ] No aspirational conventions the codebase violates (enforce, fix code, or delete)
- [ ] No tool-generic conventions (belongs in agent-specific global config, e.g., `~/.claude/CLAUDE.md` for Claude Code)

### Duplication (§8)

- [ ] No duplicate explanations of the same concept across files
- [ ] No content over 3 lines repeated in multiple files without a canonical home
- [ ] `AGENTS.md` doesn't duplicate global config rules

### Section quality (§9)

- [ ] Every doc opens with a scoped "what this covers, when to read it"
- [ ] Every section's first 2–3 lines answer "does this apply to me?"
- [ ] Each doc is self-contained — minimum context repeated (commands, paths) so readers don't bounce
