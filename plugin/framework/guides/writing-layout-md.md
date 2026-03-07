# Writing layout.md Files

How to write `layout.md` — the structural map for a directory. Read this when creating a `layout.md` from scratch, reviewing an existing one, or deciding whether a directory needs one. For the broader information taxonomy and where `layout.md` fits relative to `AGENTS.md` and `docs/`, see `framework/managing-project-information.md`.

______________________________________________________________________

## What layout.md is

`layout.md` sits at the root of the directory it describes. It maps structure — what lives where, how deep meaningful structure goes, what belongs here vs. elsewhere, and which sub-directories have their own `layout.md`.

It's not a routing table (that's `AGENTS.md`). It's not a conventions guide (that's `AGENTS.md` or a guide in `docs/`). It's purely structural — agents read it to orient before touching anything.

A directory with a `layout.md` declares "I own my structure." Agents discover structure by finding `layout.md` files and following sub-directory references, the same way build tools use `BUILD` or `package.json` to mark package boundaries.

______________________________________________________________________

## When to create one

Create a `layout.md` when the directory has meaningful sub-structure that isn't obvious from filenames alone, or when it's a project, service, or bounded area with its own concerns.

Don't create one for:

- Leaf directories with a handful of files and no sub-structure
- Directories whose purpose is entirely obvious from their name and `AGENTS.md`'s structure map
- Auto-generated directories (`node_modules/`, `.venv/`, `dist/`)

______________________________________________________________________

## Frontmatter

Every `layout.md` must open with YAML frontmatter. Vyasa scripts read it via `find-docs-dir.sh` — without it, all scripts fail fast.

```yaml
---
docs: docs/
---
```

| Field | Required | Description |
|---|---|---|
| `docs` | Yes | Path to the docs directory, relative to this `layout.md`. |

Never omit `docs:` — a missing field is treated the same as a missing `layout.md`. If the directory has no docs yet, create `docs/` and set `docs: docs/`.

______________________________________________________________________

## Structure

Sections marked optional may be omitted when not applicable.

```markdown
---
docs: docs/
---

# <Directory Name>

[1–2 sentences: what this directory contains and when to read this file.]
[If not the repo root: "For broader context, see `../layout.md`."]

## Contents

[Directory tree — meaningful structure, not just immediate children.
 Describe directories by purpose. List individual files only when notable.]

## What Lives Here

[Things that belong at this level: shared config, entry points, cross-cutting
 concerns. Prevents agents from looking in sub-directories for things owned here.]

## What Doesn't Live Here        ← omit if the boundary is obvious

[What belongs elsewhere. The negative constraint prevents misplacement.]

## Sub-Directories               ← omit if none have layout.md

[Table of sub-directories with their own layout.md — the traversal map.]

| Directory | What it owns |
|---|---|
| `services/payments/` | Payments processing → `services/payments/layout.md` |

## Guides                        ← omit if no docs scoped to this level

[Routing table for concerns at this level only. Same "When you are..." format
 as AGENTS.md. Don't duplicate entries from the parent layout.md.]

| When you are... | Read |
|---|---|
| ... | `docs/...` |
```

______________________________________________________________________

## The Contents section

Describe directories by purpose. List individual files only when they're notable — entry points, shared config, files whose purpose isn't obvious from their name or directory. Never enumerate files inside a directory whose description already makes the contents clear; don't list individual ADRs, guides, or scripts unless one is exceptional.

Go deeper than a flat listing — cover the levels an agent would need to know about. Stop at implementation detail.

**Format:** Indented tree, `—` separator aligned, traversal points marked with `→`.

```
src/
  orders/           — order domain (models, services, serializers)
    services.py     — business logic entry point
  inventory/        — inventory domain
  common/           — shared utilities and base classes
  generated/        — auto-generated protobuf stubs; never hand-edit

services/           → services/layout.md
  payments/         → services/payments/layout.md
  auth/             → services/auth/layout.md

docs/
  guides/           — detailed convention docs
  decisions/        — ADRs
  plans/            — active implementation plans (archive after completion)
```

______________________________________________________________________

## Back-reference to parent

If this `layout.md` isn't at the repo root, include one line in the opening paragraph:

```markdown
For broader context, see `../layout.md`.
```

Adjust the relative path to match actual depth.

______________________________________________________________________

## Sizing

| Length | Action |
|---|---|
| Under ~15 lines | Too thin — the directory probably doesn't need a `layout.md` |
| 15–150 lines | Ideal range |
| Over 150 lines | Contents is too granular — trim to meaningful structure |

______________________________________________________________________

## Common mistakes

| Mistake | Fix |
|---|---|
| Listing every file in Contents | Describe directories by purpose; list files only when notable |
| Only listing immediate children | Go deeper — cover 2–3 levels where structure matters |
| Listing all files in a well-described directory | Trust the directory description; don't enumerate its contents |
| No "What Doesn't Live Here" | Add the negative constraint when the boundary isn't obvious |
| Sub-Directories table only lists direct children | List all sub-directories with `layout.md`, regardless of depth |
| Guides section duplicates AGENTS.md | Scope Guides to concerns at this level only |
| `layout.md` inside `docs/` | Put `layout.md` at the root of the directory it describes, not inside a sub-directory |
| Creating `layout.md` for every directory | Only create where structure isn't obvious or a sub-project boundary exists |
