---
description: Check and install vyasa runtime dependencies (git, jq, prettier)
---

Run the vyasa runtime dependency check. This verifies that `git` and `jq`
are installed — both required by the plugin's lint scripts — and installs
`prettier` into the plugin directory for markdown formatting.

Missing `git`/`jq` dependencies will be installed automatically via the
first available package manager: `apt-get` (Linux), `dnf`/`yum` (Linux), or
`brew` (macOS). If none are available, you will be given a link to the
official install page for each missing tool. `prettier` is always installed into `${CLAUDE_PLUGIN_ROOT}/node_modules/`.
Install priority: pnpm → npm → brew (macOS, symlinked into plugin dir) or
pnpm installed via apt-get/dnf/yum/official installer (Linux).

Run:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-runtime-deps.sh
```

Report the output to the user. If all dependencies are present, confirm the
plugin is ready to use. If any are missing and could not be installed, show the
user the install links and ask them to re-run `/vyasa:setup` after installing.

## Reserved directory name: `archive/`

The routing-table linter silently excludes everything inside `archive/`. Users
who already have a directory by that name may not realise their files are being
skipped. Surface this at setup — before they run lint — so they can act before
it causes confusion.

If a `layout.md` is present in the project, resolve the docs directory and
check whether an `archive/` subdirectory already exists inside it:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/find-docs-dir.sh <project-root>
```

If `<docs-dir>/archive/` exists, tell the user:

- vyasa treats `archive/` as a sink for ephemeral post-merge content (completed
  plans, checklists, spike notes). The routing-table linter silently skips it.
- If their `archive/` already holds that kind of content — no action needed.
- If it holds content agents need to read during normal work — move those files
  to `docs/` and add routing-table entries. The test: *will anyone read this to
  do a current task, not just to understand history?* If yes, it belongs in
  `docs/`, not `archive/`.
