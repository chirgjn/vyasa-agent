---
docs: docs/
---

# vyasa

Structural map of the vyasa repo — the opinionated documentation framework for AI-assisted
projects. Read this to orient before adding files, moving things, or understanding where
a concern belongs.

## Contents

```
layout.md                        — this file
AGENTS.md                        — navigation, commands, conventions, routing table (< 80 lines)
CLAUDE.md -> AGENTS.md           — symlink; never edit directly
README.md                        — human entry point: what vyasa is, how to install
pyproject.toml                   — Python tooling config (ruff, basedpyright, pytest)
pyrightconfig.json               — basedpyright settings
package.json                     — Node.js dev dependencies (prettier)
pnpm-lock.yaml                   — pnpm lockfile

plugin/                          — the plugin (all consumer-facing content; edit files here directly)
  .claude-plugin/
    plugin.json                  — plugin manifest (name, version, description)
  agents/                        — plugin agents; one file per agent role
    full-audit.md                — orchestrator: dispatches three-phase audit pipeline
    fix-orchestrator.md          — orchestrator: routes findings to fixers or user
    doc-editor.md                — scribe: claims files, applies one approved task
    *-audit.md                   — one auditor per check (doc, structure, prose, convention, content, discoverability, staleness, health)
    *-fixer.md                   — paired fixer for each auditor
    *-lint.md                    — hook-triggered single-file linters (AGENTS.md, diagrams)
    author-*.md, doc-maintenance.md — authoring and maintenance agents
  commands/                      — plugin slash commands
  skills/                        — plugin skills (invokable by users; e.g. vyasa:setup)
  framework/                     → plugin/framework/layout.md
  hooks/
    hooks.json                   — hook definitions (auto-triggering config)
  scripts/                       — scripts agents and hooks call in consumer projects → plugin/scripts/README.md
  README.md, LICENSE

scripts/
  bump-plugin-version.sh         — bumps version in plugin/.claude-plugin/plugin.json; adds -dev suffix
  setup/                         — full project dev setup: orchestrator + individual install scripts
    setup.sh                     — entry point: runs all install steps in order
    README.md                    — script table and dependency tree
    install-*.sh, verify.sh      — individual install and verification scripts
  tools/                         — dev-only linter/formatter wrappers; used by hooks and CI in this repo only → scripts/tools/README.md

tests/                           — pytest suite for plugin scripts (test_*.py)

docs/
  audit-pipeline.md              — architecture: agents, phases, gates, claim protocol
  maintenance.md                 — this repo's update triggers, enforcement layers, release process
  python-type-annotations.md     — how to keep basedpyright warnings at zero in pytest test files
  decisions/                     — ADRs: reasoning behind non-obvious pipeline design choices
  designs/                       — design docs: pre-approval problem + alternatives + recommendation (live until deprecated or rejected)
  specs/                         — pipeline specs (index.md + per-spec files by lifecycle status)
  plans/                         — active implementation plans (archive to docs/archive/plans/ after merge)
  archive/
    designs/                     — deprecated or rejected design docs
    plans/                       — completed implementation plans (ephemeral after merge)
```

## What Lives Here

- `pyproject.toml` — shared Python tooling config covering all scripts and tests (not per-directory)
- `package.json` — Node.js dev dependencies (prettier)
- `scripts/bump-plugin-version.sh` — release tooling; bumps version in `plugin/.claude-plugin/plugin.json`
- `plugin/.claude-plugin/plugin.json` — single version authority; plugin is self-contained

## What Doesn't Live Here

- Consumer-project docs → this repo contains the framework and plugin, not the docs of projects that use vyasa
- Audit run artifacts → `.vyasa/` is ephemeral, not committed
- Per-file edits → agents claim files via registry; never hand-edit outside a claimed task

## Sub-Directories

| Directory           | What it owns                                                                               |
| ------------------- | ------------------------------------------------------------------------------------------ |
| `plugin/framework/` | Documentation framework: guides, core docs, placement rules → `plugin/framework/layout.md` |

## Guides

| When you are...                                                                 | Read                      |
| ------------------------------------------------------------------------------- | ------------------------- |
| Understanding the audit or fix pipeline — agents, phases, gates, claim protocol | `docs/audit-pipeline.md`  |
| Reading why a pipeline design decision was made                                 | `docs/decisions/`         |
| Checking update triggers, enforcement layers, or the release process            | `docs/maintenance.md`     |
| Understanding project dev setup scripts or install dependencies                 | `scripts/setup/README.md` |
