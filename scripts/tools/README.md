# Dev Tools

Linter and formatter wrappers used by this repo's pre-commit hooks, Claude Code hooks, and CI.
These scripts are **not** shipped to consumers — they are dev infrastructure for vyasa itself.

Do not add consumer-facing scripts here. Scripts that agents call in consumer projects belong
in `plugin/scripts/`.

## Scripts

| Script                       | Tool               | What it does                                                                                                             |
| ---------------------------- | ------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| `prettier-fix.sh`            | prettier           | Format markdown — auto-fix then check locally; `--check` skips the fix (used in CI)                                      |
| `ruff-fix.sh`                | ruff               | Lint Python — auto-fix then check locally; `--check` skips the fix (used in CI)                                          |
| `basedpyright-lint.sh`       | basedpyright       | Typecheck Python                                                                                                         |
| `pytest-run.sh`              | pytest             | Run the test suite                                                                                                       |
| `shellcheck-lint.sh`         | shellcheck         | Lint shell scripts in `scripts/` and `plugin/scripts/`                                                                   |
| `yamllint-fmt.sh`            | yamllint + yamlfix | Fix + lint YAML (yamlfix skips `.github/`)                                                                               |
| `actionlint-lint.sh`         | actionlint         | Lint GitHub Actions workflows                                                                                            |
| `taplo-fmt.sh`               | taplo              | Format TOML — auto-fix locally; `--check` skips the fix (used in CI)                                                     |
| `check-plugin-version.sh`    | —                  | Fail if plugin version lacks `-dev` suffix                                                                               |
| `post-write-lint.sh`         | —                  | Dev PostToolUse hook: routes Write/Edit to the right linter by file extension; flags `.md` files for deferred formatting |
| `stop-prettier.sh`           | prettier           | Dev Stop hook: runs prettier once on all `.md` files touched during the turn, then clears the flag                       |
| `block-no-verify.sh`         | —                  | Hook that blocks `git commit --no-verify`                                                                                |
| `uv-sync-if-lock-changed.sh` | uv                 | Re-sync the venv when `uv.lock` changes                                                                                  |
| `find-word-contexts.sh`      | —                  | Find all occurrences of a word with surrounding context (used by agents in this repo)                                    |
