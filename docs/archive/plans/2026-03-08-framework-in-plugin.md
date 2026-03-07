# Plugin-as-Source Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `plugin/` the canonical source for all plugin content (agents, framework, commands, hooks, scripts, README, LICENSE), eliminating `sync-plugin.sh` and the `plugin-sync` CI check entirely.

**Architecture:** Everything consumers need moves into `plugin/` as source of truth. Dev infra (tests/, scripts/tools/, scripts/setup/, .github/, pyproject.toml) stays at repo root. AGENTS.md and layout.md stay at repo root (Claude Code picks them up there) but reference `plugin/...` paths. The marketplace entry in `claude-code-plugins` gains a `git-subdir` source pointing at `plugin/` so consumers only download that subtree.

**Tech Stack:** bash, git, markdown, JSON

---

## Pre-flight check

Verify `plugin/` is in sync before starting — everything must match before we delete the sync:

```bash
cd /Users/chiragjain/projects/current-project/documentation
scripts/sync-plugin.sh
git diff --quiet plugin/ || echo "DIRTY — run sync and commit first"
```

Expected: no output (clean).

---

### Task 1: Move agents/, commands/, hooks/ into plugin/

These directories exist at both repo root and `plugin/` as copies. Make `plugin/` canonical by deleting the root copies (they're already in `plugin/`).

**Files:**

- Delete: `agents/` (repo root)
- Delete: `commands/` (repo root)
- Delete: `hooks/` (repo root)

**Step 1: Verify plugin/ copies match repo root**

```bash
diff -rq agents/ plugin/agents/
diff -rq commands/ plugin/commands/
diff -rq hooks/ plugin/hooks/
```

Expected: no output (identical). If differences exist, investigate before proceeding.

**Step 2: Delete the repo-root copies**

```bash
git rm -r agents/ commands/ hooks/
```

**Step 3: Verify plugin/ still intact**

```bash
ls plugin/agents/ | head -5
ls plugin/commands/
ls plugin/hooks/
```

Expected: files are present in `plugin/`.

**Step 4: Commit**

```bash
git commit -m "feat: move agents/, commands/, hooks/ into plugin/ as canonical source"
```

---

### Task 2: Move scripts/runtime/, scripts/audit/, scripts/detect-doc-changes.sh into plugin/

These ship to consumers. The copies in `plugin/scripts/` become canonical.

**Files:**

- Delete: `scripts/runtime/` (repo root)
- Delete: `scripts/audit/` (repo root)
- Delete: `scripts/detect-doc-changes.sh` (repo root)

**Step 1: Verify plugin/ copies match**

```bash
diff -rq scripts/runtime/ plugin/scripts/runtime/
diff -rq scripts/audit/ plugin/scripts/audit/
diff scripts/detect-doc-changes.sh plugin/scripts/detect-doc-changes.sh
```

Expected: no output.

**Step 2: Delete repo-root copies**

```bash
git rm -r scripts/runtime/ scripts/audit/
git rm scripts/detect-doc-changes.sh
```

**Step 3: Verify plugin/scripts/ intact**

```bash
ls plugin/scripts/runtime/
ls plugin/scripts/audit/
ls plugin/scripts/detect-doc-changes.sh
```

**Step 4: Commit**

```bash
git commit -m "feat: move runtime scripts into plugin/ as canonical source"
```

---

### Task 3: Move framework/ into plugin/

`plugin/framework/` is already an up-to-date copy.

**Files:**

- Delete: `framework/` (repo root)

**Step 1: Verify match**

```bash
diff -rq framework/ plugin/framework/
```

Expected: no output.

**Step 2: Delete repo-root framework/**

```bash
git rm -r framework/
```

**Step 3: Verify plugin/framework/ intact**

```bash
ls plugin/framework/
ls plugin/framework/guides/
```

**Step 4: Commit**

```bash
git commit -m "feat: move framework/ into plugin/ as canonical source"
```

---

### Task 4: Move README.md and LICENSE into plugin/

**Files:**

- The copies at `plugin/README.md` and `plugin/LICENSE` become canonical.
- Repo root keeps its own `README.md` (it's the GitHub-facing repo readme — check if they're identical or different).

**Step 1: Check if they're the same file**

```bash
diff README.md plugin/README.md
diff LICENSE plugin/LICENSE
```

If identical: the repo-root copies are redundant — but keep `README.md` at repo root (GitHub shows it). Keep `LICENSE` at repo root too (standard expectation). The `plugin/` copies are what ships. No deletion needed here — the sync was copying these but now they live in plugin/ natively.

**Step 2: Verify plugin/ has both**

```bash
ls plugin/README.md plugin/LICENSE
```

Expected: both present.

**Step 3: Commit (no-op if nothing changed)**

If no changes, skip commit.

---

### Task 5: Move .claude-plugin/plugin.json into plugin/

The manifest at `.claude-plugin/plugin.json` (repo root) is copied to `plugin/.claude-plugin/plugin.json`. The one in `plugin/` becomes canonical.

**Files:**

- `.claude-plugin/plugin.json` stays at repo root (used by this dev repo's plugin identity and by `check-plugin-version.sh` which reads `.claude-plugin/plugin.json`)
- `plugin/.claude-plugin/plugin.json` is what consumers get

**Step 1: Verify they match**

```bash
diff .claude-plugin/plugin.json plugin/.claude-plugin/plugin.json
```

Expected: identical.

**Step 2: Decide on source of truth**

Since `check-plugin-version.sh` and the release workflow read `.claude-plugin/plugin.json` at repo root, keep that as the version authority. The sync used to copy it — instead, we'll update the plan: keep both in sync manually (they should always be identical). Document this in maintenance.md.

No deletion needed. Skip commit.

---

### Task 6: Delete sync-plugin.sh and check-plugin-sync.sh

With everything canonical in `plugin/`, the sync script is obsolete.

**Files:**

- Delete: `scripts/sync-plugin.sh`
- Delete: `scripts/tools/check-plugin-sync.sh`
- Delete: `scripts/bump-plugin-version.sh` — check if this still needs updating

**Step 1: Check bump-plugin-version.sh for sync references**

```bash
cat scripts/bump-plugin-version.sh
```

If it calls `sync-plugin.sh`, remove that call.

**Step 2: Delete the scripts**

```bash
git rm scripts/sync-plugin.sh scripts/tools/check-plugin-sync.sh
```

**Step 3: Commit**

```bash
git commit -m "feat: delete sync-plugin.sh and check-plugin-sync.sh — plugin/ is now source"
```

---

### Task 7: Remove plugin-sync from CI

**Files:**

- Modify: `.github/workflows/lint.yml`

**Step 1: Find the plugin-sync step**

```bash
grep -n 'plugin-sync\|sync-plugin\|check-plugin-sync' .github/workflows/lint.yml
```

**Step 2: Remove the plugin-sync step entirely**

Remove the `- name: plugin-sync` step block (~lines 114-119).

Also remove `plugin-sync` from the summary loops (two places where it appears in the `for check in ...` list at lines ~148 and ~159).

**Step 3: Verify the file is valid YAML**

```bash
scripts/tools/yamllint-fmt.sh
```

**Step 4: Verify actionlint passes**

```bash
scripts/tools/actionlint-lint.sh
```

**Step 5: Commit**

```bash
git add .github/workflows/lint.yml
git commit -m "ci: remove plugin-sync check — no sync script needed"
```

---

### Task 8: Update AGENTS.md

AGENTS.md has ~14 references to `framework/` and references to `agents/`, `commands/`, `hooks/`, `scripts/runtime/`, `scripts/audit/` that now live under `plugin/`.

**Files:**

- Modify: `AGENTS.md`

**Step 1: Find all paths that moved**

```bash
grep -n 'framework/\|^agents/\|^commands/\|^hooks/\|scripts/runtime\|scripts/audit\|detect-doc-changes' AGENTS.md
```

**Step 2: Update the structure map**

The structure map (top of AGENTS.md) should reflect the new layout:

```
plugin/                         — the plugin (all consumer-facing content)
plugin/.claude-plugin/          — plugin manifest
plugin/agents/                  — plugin agents
plugin/commands/                — plugin slash commands
plugin/framework/               — the documentation framework
plugin/framework/guides/        — writing guides
plugin/hooks/                   — hook configuration
plugin/scripts/runtime/         — runtime scripts (agents and hooks call these)
plugin/scripts/audit/           — audit helper scripts
scripts/tools/                  — dev-only linter/formatter wrappers
scripts/setup/                  — setup scripts
tests/                          — tests for Python scripts
.github/workflows/              — CI
```

**Step 3: Update routing table**

All `framework/guides/...` → `plugin/framework/guides/...`
All `framework/auditing-anti-patterns.md` → `plugin/framework/auditing-anti-patterns.md`
All `framework/managing-project-information.md` → `plugin/framework/managing-project-information.md`

Batch sed:

```bash
sed -i '' 's|`framework/|`plugin/framework/|g' AGENTS.md
sed -i '' 's| framework/| plugin/framework/|g' AGENTS.md
```

**Step 4: Update scripts/ references in Commands section**

Any references to `scripts/runtime/` or `scripts/audit/` → `plugin/scripts/runtime/` or `plugin/scripts/audit/`.

```bash
grep -n 'scripts/runtime\|scripts/audit\|detect-doc-changes' AGENTS.md
```

Update those manually.

**Step 5: Verify**

```bash
grep -n 'framework/' AGENTS.md | grep -v 'plugin/framework'
```

Expected: no output.

**Step 6: Commit**

```bash
git add AGENTS.md
git commit -m "docs: update AGENTS.md paths — all plugin content now under plugin/"
```

---

### Task 9: Update layout.md

**Files:**

- Modify: `layout.md`

**Step 1: Find all moved paths**

```bash
grep -n 'framework/\|^agents/\|^commands/\|^hooks/\|scripts/runtime\|scripts/audit' layout.md
```

**Step 2: Batch update framework/ references**

```bash
sed -i '' 's|framework/|plugin/framework/|g' layout.md
```

**Step 3: Update agents/, commands/, hooks/ references in Contents section**

These now live under `plugin/`. Update the Contents table entries accordingly. Read the section and update manually — the paths need to become `plugin/agents/`, `plugin/commands/`, `plugin/hooks/`.

**Step 4: Update scripts/runtime/, scripts/audit/ in Contents**

```bash
grep -n 'scripts/runtime\|scripts/audit' layout.md
```

Update to `plugin/scripts/runtime/`, `plugin/scripts/audit/`.

**Step 5: Verify**

```bash
grep -n 'framework/' layout.md | grep -v 'plugin/framework'
```

Expected: no output.

**Step 6: Commit**

```bash
git add layout.md
git commit -m "docs: update layout.md — all plugin content now under plugin/"
```

---

### Task 10: Update docs/maintenance.md

**Files:**

- Modify: `docs/maintenance.md`

**Step 1: Batch update framework/ references**

```bash
sed -i '' 's|framework/|plugin/framework/|g' docs/maintenance.md
```

**Step 2: Update the "What plugin/ is" section**

Find the paragraph describing `plugin/` as a build artifact (search for "build artifact"). Replace with:

> `plugin/` is the plugin project — everything consumers install. All plugin content lives here as canonical source: `plugin/agents/`, `plugin/commands/`, `plugin/hooks/`, `plugin/framework/`, `plugin/scripts/runtime/`, `plugin/scripts/audit/`. Edit files directly inside `plugin/`. There is no sync step. Dev infra (tests/, scripts/tools/, scripts/setup/, .github/) lives at the repo root and never ships to consumers.

**Step 3: Update the Update Triggers table**

Remove the row about running `sync-plugin.sh`. Replace:

| When you...                                             | Update                                                                        |
| ------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Change a guide, agent, hook, command, or runtime script | Edit directly in `plugin/` — no sync needed; include `plugin/` in your commit |

**Step 4: Remove sync from the staleness-detection commands**

```bash
grep -n 'sync-plugin\|check-plugin-sync' docs/maintenance.md
```

Remove or update any references.

**Step 5: Verify**

```bash
grep -n 'sync-plugin\|check-plugin-sync\|build artifact' docs/maintenance.md
```

Expected: no output.

**Step 6: Commit**

```bash
git add docs/maintenance.md
git commit -m "docs: update maintenance.md — plugin/ is source, no sync"
```

---

### Task 11: Update docs/audit-pipeline.md and remaining docs/

**Files:**

- Modify: `docs/audit-pipeline.md`

**Step 1: Batch update**

```bash
sed -i '' 's|framework/|plugin/framework/|g' docs/audit-pipeline.md
grep -n 'scripts/runtime\|scripts/audit\|agents/' docs/audit-pipeline.md
```

Update any remaining moved paths.

**Step 2: Catch-all for other docs/**

```bash
grep -rn 'framework/' docs/ --include='*.md' | grep -v 'plugin/framework'
grep -rn 'scripts/runtime\|scripts/audit' docs/ --include='*.md' | grep -v 'plugin/scripts'
```

Fix any that appear, then:

**Step 3: Commit**

```bash
git add docs/
git commit -m "docs: update docs/ — all moved paths now under plugin/"
```

---

### Task 12: Update tests/

**Files:**

- Modify: `tests/test_mock_audit_run.py`

**Step 1: Find all moved paths in tests**

```bash
grep -rn 'framework/\|scripts/runtime\|scripts/audit\|agents/' tests/ --include='*.py'
```

**Step 2: Update path strings**

```bash
sed -i '' 's|framework/|plugin/framework/|g' tests/test_mock_audit_run.py
sed -i '' 's|scripts/runtime/|plugin/scripts/runtime/|g' tests/test_mock_audit_run.py
sed -i '' 's|scripts/audit/|plugin/scripts/audit/|g' tests/test_mock_audit_run.py
```

Check other test files:

```bash
grep -rn 'framework/\|scripts/runtime' tests/ --include='*.py' | grep -v 'plugin/'
```

Fix any remaining.

**Step 3: Run all tests**

```bash
scripts/tools/pytest-run.sh
```

Expected: all pass.

**Step 4: Commit**

```bash
git add tests/
git commit -m "test: update test paths — all plugin content now under plugin/"
```

---

### Task 13: Update scripts/tools/ that reference moved paths

Check-plugin-sync is deleted. Check if any remaining tools reference moved paths.

**Step 1: Scan**

```bash
grep -rn 'framework/\|scripts/runtime\|scripts/audit\|sync-plugin' scripts/tools/ --include='*.sh'
grep -rn 'framework/\|scripts/runtime\|scripts/audit\|sync-plugin' scripts/setup/ --include='*.sh'
```

**Step 2: Fix any that appear**

Update paths and commit.

---

### Task 14: Run full CI check locally

**Step 1: Run all linters**

```bash
scripts/tools/mdformat-fix.sh
scripts/tools/shellcheck-lint.sh
scripts/tools/pytest-run.sh
scripts/tools/yamllint-fmt.sh
scripts/tools/actionlint-lint.sh
```

**Step 2: Run plugin version check**

```bash
scripts/tools/check-plugin-version.sh
```

**Step 3: Final catch-all — verify no bare moved paths remain outside plugin/**

```bash
grep -rn 'framework/' --exclude-dir=plugin --exclude-dir=.git . | grep -v 'plugin/framework'
grep -rn 'scripts/runtime' --exclude-dir=plugin --exclude-dir=.git . | grep -v 'plugin/scripts'
```

Expected: no output. Fix anything that appears and commit.

---

### Task 15: Update marketplace entry in claude-code-plugins repo

The marketplace currently installs vyasa from the repo root. Now consumers should get only `plugin/` via sparse checkout.

**Files:**

- Modify: `/Users/chiragjain/repos/claude-code-plugins/.claude-plugin/marketplace.json`

**Step 1: Read the current vyasa entry**

```bash
cat /Users/chiragjain/repos/claude-code-plugins/.claude-plugin/marketplace.json
```

**Step 2: Add git-subdir source**

Find the vyasa plugin entry and change its `source` from a simple path/string to:

```json
"source": {
  "source": "git-subdir",
  "url": "https://github.com/chirgjn/docpilot.git",
  "path": "plugin"
}
```

(Adjust the GitHub URL to match the actual repo URL — check with `git remote get-url origin` in the documentation repo.)

**Step 3: Verify JSON is valid**

```bash
python3 -m json.tool /Users/chiragjain/repos/claude-code-plugins/.claude-plugin/marketplace.json > /dev/null && echo "valid"
```

**Step 4: Commit in the claude-code-plugins repo**

```bash
cd /Users/chiragjain/repos/claude-code-plugins
git add .claude-plugin/marketplace.json
git commit -m "feat: vyasa now distributed from plugin/ subdirectory via git-subdir"
```
