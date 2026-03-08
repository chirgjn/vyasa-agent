# vyasa

Opinionated documentation framework — how to structure, write, and maintain project docs so AI coding agents find the right information fast.

## Structure

```
plugin/                         — The plugin (all consumer-facing content)
plugin/.claude-plugin/          — Plugin manifest (version authority; plugin is self-contained)
plugin/agents/                  — Plugin agents: auditors, fixers, orchestrators, and scribes
plugin/commands/                — Plugin slash commands
plugin/skills/                  — Plugin skills (e.g., vyasa:setup)
plugin/framework/               — The documentation framework
plugin/framework/managing-project-information.md — Central index: taxonomy, placement, directory structure, and routing table for all writing guides
plugin/framework/auditing-anti-patterns.md       — Pragmatic audit guide: broad but not exhaustive, self-contained, complements the full audit pipeline
plugin/framework/guides/        — Writing guides: prose style, conventions, diagrams, AGENTS.md, layout.md, ADRs, specs, designs, maintenance
plugin/hooks/                   — Plugin hooks: auto-triggering config (hooks.json)
plugin/scripts/                 — Scripts that ship inside the plugin (agents and hooks call these)
docs/maintenance.md             — This repo's maintenance: update triggers, enforcement layers
scripts/setup/                  — Project dev setup scripts (uv, Python, deps, taplo, gh, etc.)
scripts/tools/                  — Dev-only linter/formatter wrappers for hooks and CI
tests/                          — Tests for Python scripts
.github/workflows/              — CI (lint.yml runs all checks)
```

## Commands

```bash
scripts/tools/prettier-fix.sh         # format markdown (auto-fix + check)
scripts/tools/ruff-fix.sh             # lint + auto-fix Python
scripts/tools/basedpyright-lint.sh     # typecheck Python
scripts/tools/pytest-run.sh            # run tests
scripts/tools/shellcheck-lint.sh       # lint shell
scripts/tools/yamllint-fmt.sh          # fix + lint YAML
scripts/tools/actionlint-lint.sh       # lint GitHub Actions
scripts/tools/taplo-fmt.sh            # format TOML
scripts/setup/setup.sh                 # full project dev setup
```

## Conventions

- `AGENTS.md` is the canonical file; `CLAUDE.md` is a symlink (`ln -s AGENTS.md CLAUDE.md`) — never edit `CLAUDE.md` directly, never maintain two copies
- Every reference doc opens with a scoped "what this covers and when to read it" line — never jump straight into content
- Routing table entries use task phrasing ("When you are..."), not filenames — never "Read docs/foo.md"
- Each convention includes what NOT to do — a convention without a negative constraint doesn't prevent the mistake
- One canonical home per concept — never duplicate content over 3 lines across files, link instead
- Use Mermaid for diagrams, not ASCII art — never represent flows, lifecycles, or relationships as plain-text boxes and arrows

## Tooling

- **Python**: >=3.14, managed via uv
- **Formatting**: prettier (markdown), taplo (TOML), yamlfix (YAML), ruff (Python)
- **Linting**: ruff + basedpyright (Python), shellcheck (shell), yamllint (YAML), actionlint (GHA)
- **Project dev setup**: `scripts/setup/setup.sh` installs the full project dev environment; individual scripts in `scripts/setup/`

## Routing

**Any doc work — writing, editing, placing, or auditing:** start at `plugin/framework/managing-project-information.md`.
It answers: what type of doc is this, where does it live, and which guide covers how to write it well
(prose style, conventions, diagrams, ADRs, specs, designs, layout.md, AGENTS.md, maintenance).
Skipping it is the primary source of misplaced content, wrong doc types, and missing conventions.
For finding and fixing problems in docs that already exist, see `plugin/framework/auditing-anti-patterns.md`.

**This repo:**

| When you are...                                                                                      | Read                              |
| ---------------------------------------------------------------------------------------------------- | --------------------------------- |
| Getting a structural map of the repo — what lives where before making changes                        | `layout.md`                       |
| Understanding the audit or fix pipeline — agents, phases, gates, claim protocol, or agent inventory  | `docs/audit-pipeline.md`          |
| Understanding any pipeline spec — dispatch, report format, claim protocol                            | `docs/specs/index.md`             |
| Reviewing any pipeline architectural decision — phasing, file handoff, claim log, etc.               | `docs/decisions/index.md`         |
| Finding or tracking an active implementation plan                                                    | `docs/plans/index.md`             |
| Understanding what each runtime script does (claim, lint, find-docs-dir, etc.)                       | `plugin/scripts/README.md`        |
| Understanding what each dev tool script does (ruff, prettier, CI checks, etc.)                       | `scripts/tools/README.md`         |
| Understanding project dev setup scripts or install dependencies                                      | `scripts/setup/README.md`         |
| Checking this repo's update triggers, enforcement layers, release process, or how `plugin/` is built | `docs/maintenance.md`             |
| Keeping basedpyright warnings at zero in pytest test files — `tmp_path`, `cast()`, unused vars       | `docs/python-type-annotations.md` |
