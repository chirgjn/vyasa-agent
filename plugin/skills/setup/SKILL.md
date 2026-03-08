---
name: setup
description: Run vyasa runtime dependency check and setup. Use when the user asks to set up vyasa, install dependencies, or check whether the plugin is ready to use.
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
user the install links and ask them to say "run vyasa setup" again after installing.

## layout.md and docs directory

`layout.md` is a file at the project root that tells vyasa where the
documentation directory lives. All lint scripts depend on it.

After reporting dependency status, silently gather:

1. Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/find-docs-dir.sh <project-root>` —
   does a `layout.md` exist?
2. If not, does `<project-root>/docs/` exist?

Then present one consolidated plan and ask for confirmation. Only create files
after the user confirms.

---

### Case A — `layout.md` exists

Proceed to the **`archive/` check** below. Nothing to create.

---

### Case B — `layout.md` absent, `docs/` exists

Tell the user vyasa needs a `layout.md` to know where the docs live, and that a
`docs/` directory was found — is that the documentation directory?

- **Yes:** plan to create `layout.md` pointing to `docs: docs/`.
- **No:** ask which directory to use, then plan to create `layout.md` pointing
  to `docs: <their-answer>/`.

After confirmation, create `layout.md` per
`${CLAUDE_PLUGIN_ROOT}/framework/guides/writing-layout-md.md`.

---

### Case C — `layout.md` absent, no `docs/` exists

Tell the user vyasa needs a `layout.md` and no `docs/` directory was found.
Plan to create both `docs/` and `layout.md` pointing to `docs: docs/`.

After confirmation, create both per
`${CLAUDE_PLUGIN_ROOT}/framework/guides/writing-layout-md.md`.

---

## Reserved directory name: `archive/`

The routing-table linter silently excludes everything inside `archive/`. Users
who already have a directory by that name may not realise their files are being
skipped. Surface this at setup — before they run lint — so they can act before
it causes confusion.

Once the docs directory is known (either from an existing `layout.md` or after
creating one), check whether an `archive/` subdirectory already exists inside
it. Include this in the consolidated plan presented to the user.

If `<docs-dir>/archive/` exists, tell the user:

- vyasa treats `archive/` as a sink for ephemeral post-merge content (completed
  plans, checklists, spike notes). The routing-table linter silently skips it.
- If their `archive/` already holds that kind of content — no action needed.
- If it holds content agents need to read during normal work — move those files
  to `docs/` and add routing-table entries. The test: _will anyone read this to
  do a current task, not just to understand history?_ If yes, it belongs in
  `docs/`, not `archive/`.
