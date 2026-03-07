# Repo Maintenance

How this repo's tooling and docs stay accurate. Use this when adding a new tool, changing a lint script, investigating why a check isn't running, or auditing docs for staleness. For the generic documentation maintenance guide (enforcement hierarchy, update triggers, checklists for any project), see `plugin/framework/guides/maintenance.md`.

---

## Enforcement Layers

Three layers ensure code quality — each catches what the previous one missed:

| Layer                 | Scope         | Behavior                       | Config                               |
| --------------------- | ------------- | ------------------------------ | ------------------------------------ |
| **Claude Code hooks** | modified file | fix + lint on every Write/Edit | `.claude/settings.json`              |
| **Git hooks**         | staged files  | fix + lint on every commit     | `.pre-commit-config.yaml` (via prek) |
| **CI**                | all files     | lint-only (no fix)             | `.github/workflows/lint.yml`         |

All three layers use the same wrapper scripts in `scripts/tools/`. Most scripts auto-fix first, then check — so hooks fix issues automatically while CI only reports them. The plugin-version check (`check-plugin-version`) is check-only on both local and CI; it never modifies files.

---

## Update Triggers

| When you...                                                                                            | Update                                                                                                                                                                                                  |
| ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Add or rename a top-level directory                                                                    | `AGENTS.md` structure map, `layout.md` Contents section                                                                                                                                                 |
| Add or rename an agent, script, or tool                                                                | `layout.md` Contents section                                                                                                                                                                            |
| Add a script to `plugin/scripts/`                                                                      | `plugin/scripts/README.md` scripts table                                                                                                                                                                |
| Add a script to `scripts/tools/`                                                                       | `scripts/tools/README.md` scripts table                                                                                                                                                                 |
| Add a new doc to `docs/` or `plugin/framework/guides/`                                                 | `AGENTS.md` routing table                                                                                                                                                                               |
| Accept a spec                                                                                          | `docs/decisions/` — write an ADR recording why this approach was chosen                                                                                                                                 |
| Complete a plan (all files done)                                                                       | Write or verify an ADR for non-obvious decisions; move spec to `docs/specs/live/`; archive plan to `docs/archive/plans/`; update `docs/specs/index.md` and `docs/plans/index.md`                        |
| Make a non-obvious architectural decision about the pipeline                                           | `docs/decisions/` — write or supersede an ADR                                                                                                                                                           |
| Add a new writing guide                                                                                | `AGENTS.md` routing table                                                                                                                                                                               |
| Change taxonomy, placement rules, or conventions in `plugin/framework/managing-project-information.md` | `plugin/framework/auditing-anti-patterns.md` — the audit guide is self-contained by design (all detection info inline, no hops mid-audit), so it must stay in sync                                      |
| Change a guide, agent, hook, command, or script                                                        | Edit in `plugin/` and include `plugin/` in your commit                                                                                                                                                  |
| Change a lint/format script in `scripts/tools/`                                                        | `.pre-commit-config.yaml`, `.github/workflows/lint.yml`, `.claude/settings.json` (if affected)                                                                                                          |
| Add a new linter or formatter                                                                          | `pyproject.toml` (dep), new script in `scripts/tools/`, `scripts/tools/README.md`, hook in `.pre-commit-config.yaml`, step in `.github/workflows/lint.yml`, case in `plugin/scripts/post-write-lint.sh` |
| Change Python version requirement                                                                      | `pyproject.toml` requires-python, `.github/workflows/lint.yml`                                                                                                                                          |
| Add a new project dev setup script                                                                     | `scripts/setup/setup.sh` (step), `scripts/setup/README.md` (table + dependency tree)                                                                                                                    |

---

## Release Process

### Invariant: version always carries `-dev` on `main`

`plugin/` is the canonical source for all plugin content. Dev infra (`tests/`, `scripts/tools/`, `scripts/setup/`, `.github/`) lives at the repo root and never ships to consumers.

### Version scheme

`main` always carries a `-dev` suffix (e.g. `0.2.1-dev`) except on the release commit itself.
CI fails if a non-release commit has a version without `-dev`.

The lifecycle:

```
0.2.0-dev  →  publish  →  0.2.0 (release commit, tagged v0.2.0)
           →  local bump  →  0.2.1-dev  →  0.2.1-dev  →  publish  →  0.2.1
```

After publishing, bump the version and add `-dev` locally before your next push:

```bash
scripts/bump-plugin-version.sh patch   # or minor / major
git add .claude-plugin/plugin.json plugin/.claude-plugin/plugin.json
git commit -m "chore: begin $(jq -r .version .claude-plugin/plugin.json)"
```

### Publishing a new version — manual

Go to **Actions → Plugin Release → Run workflow** and run it. The workflow:

1. Strips `-dev` from the current version in `.claude-plugin/plugin.json`
1. Updates `plugin/.claude-plugin/plugin.json` to match
1. Commits as `release: vX.Y.Z` and tags `vX.Y.Z`

The version to release is whatever is in `plugin.json` on `main` at the time — set it before triggering.

### What `plugin/` is

`plugin/` is the plugin project — everything consumers install: `plugin/agents/`, `plugin/commands/`, `plugin/hooks/`, `plugin/framework/`, `plugin/scripts/`. Consumers install from `plugin/` via sparse checkout; they never download the full repo.

---

## Lint Script Conventions

All scripts in `plugin/scripts/` that are called by agents follow a shared output contract. When adding a new lint script, follow these rules.

### Output format

Emit one of two line forms to stdout:

```
FIXED: <short description of what was changed>
REMAINING: <severity> — <short description of what needs judgment>
```

Severity is one of `error`, `warning`, `info`. Always exit 0 — failures are REMAINING lines, not exit codes. Never mix diagnostic prose into stdout; use stderr for unexpected errors.

### Bash compatibility

All scripts must target **bash 3.2+** (macOS default). Forbidden constructs:

| Forbidden                         | Use instead                     |
| --------------------------------- | ------------------------------- |
| `mapfile` / `readarray`           | `while IFS= read -r line` loops |
| `declare -A` (associative arrays) | Positional arrays or temp files |

Allowed: herestrings (`<<<`), process substitution (`<()`).

### Agent integration

Agents call these scripts in **Phase 0** before any LLM reasoning. FIXED lines need verification in the final pass; REMAINING lines need judgment.

---

## Scripts Reference

Two directories contain helper scripts. Don't add a script to the wrong one — the directory determines whether it ships to consumers.

| Directory         | Audience                                                | Ships to consumers? |
| ----------------- | ------------------------------------------------------- | ------------------- |
| `plugin/scripts/` | Consumer projects — agents and hooks call these         | Yes                 |
| `scripts/tools/`  | This repo only — CI, pre-commit hooks, and dev workflow | No                  |

For what each script does, see `plugin/scripts/README.md` and `scripts/tools/README.md`.

---

## Keeping Docs Accurate

Update docs in the same PR as the code change they describe. A guide change without a corresponding AGENTS.md update (or vice versa) creates drift.

### What to check after any change

1. Does `AGENTS.md`'s structure map still match the actual directory layout?
1. Does every file in `docs/` and `plugin/framework/guides/` appear in the routing table?
1. Does every routing table entry match an actual file?
1. Do the conventions in `AGENTS.md` match what the guides teach? If a guide says "do X" but AGENTS.md doesn't mention it, either add it or the guide is wrong.
1. Does `plugin/framework/managing-project-information.md` still reflect how this repo actually organizes information?
1. When a pipeline design choice changes, is there an ADR in `docs/decisions/` superseding the old one?
1. Does every Live spec in `docs/specs/live/` still accurately describe the system? If a system changed, the spec must update or be deprecated.
1. Does every In Progress spec in `docs/specs/in-progress/` have an active plan? If the plan is complete, move the spec to `docs/specs/live/`.
1. Does `docs/specs/index.md` reflect the current location and status of every spec?

### Detecting staleness

| Check                                        | Command                                                                                                        |
| -------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| Broken file references in docs               | `grep -rn 'docs/' AGENTS.md docs/ \| grep -v node_modules`                                                     |
| Files missing from routing table             | Compare `ls docs/ plugin/framework/guides/` against AGENTS.md routing table                                    |
| AGENTS.md conventions not followed by guides | Read each convention, verify guides follow it                                                                  |
| Guides referencing removed tools or scripts  | `grep -rn 'scripts/' plugin/framework/guides/` and verify paths exist                                          |
| `layout.md` Contents out of date             | Compare `layout.md` Contents against actual `ls plugin/agents/ plugin/scripts/ scripts/tools/ docs/decisions/` |
