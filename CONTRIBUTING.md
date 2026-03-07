# Contributing to vyasa

## Prerequisites

- macOS or Linux
- [Claude Code](https://claude.ai/code) CLI installed and authenticated
- Git

## Getting started

Run the setup script to install the full dev environment:

```bash
scripts/setup/setup.sh
```

This installs: uv + Python >=3.14, jq, taplo, yamllint/yamlfix/actionlint, gh, pnpm, prettier, and Claude Code plugins and skills used in this repo.

To verify the setup worked:

```bash
scripts/setup/verify.sh
```

## Repo structure

```
plugin/           — The plugin (everything consumers install)
scripts/tools/    — Linter/formatter wrappers for CI and local hooks
scripts/setup/    — Dev environment setup scripts
tests/            — pytest suite for plugin scripts
docs/             — Dev-facing reference docs (pipeline, decisions, specs)
.github/          — CI workflows
```

`plugin/` is the canonical source for all plugin content. Dev infra (`scripts/`, `tests/`, `.github/`) lives at the repo root and never ships to consumers.

For the full directory map, see `layout.md`.

## Running checks

All checks use wrapper scripts in `scripts/tools/`:

```bash
scripts/tools/prettier-fix.sh       # format markdown
scripts/tools/ruff-fix.sh           # lint + fix Python
scripts/tools/basedpyright-lint.sh  # typecheck Python
scripts/tools/pytest-run.sh         # run tests
scripts/tools/shellcheck-lint.sh    # lint shell scripts
scripts/tools/yamllint-fmt.sh       # fix + lint YAML
scripts/tools/taplo-fmt.sh          # format TOML
scripts/tools/actionlint-lint.sh    # lint GitHub Actions
```

These run automatically on every commit (pre-commit hooks) and in CI. Locally they auto-fix; CI is check-only.

## Making changes

**Plugin content** (`plugin/agents/`, `plugin/scripts/`, `plugin/framework/`, etc.) — edit directly in `plugin/`. These files ship to consumers.

**Dev tooling** (`scripts/tools/`, `.github/`, `tests/`) — edit at the repo root. These never ship.

When adding or changing things, update the relevant docs in the same PR. See `docs/maintenance.md` for the full update triggers table.

## Versioning

`main` always carries a `-dev` version suffix (e.g. `0.2.1-dev`). CI fails without it.

After a release, bump the version before your next push:

```bash
scripts/bump-plugin-version.sh patch   # or minor / major
git add .claude-plugin/plugin.json plugin/.claude-plugin/plugin.json
git commit -m "chore: begin $(jq -r .version .claude-plugin/plugin.json)"
```

Releases are triggered manually via **Actions → Plugin Release → Run workflow**.
