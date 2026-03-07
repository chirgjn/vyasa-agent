# Detecting Stale Docs

How to identify documentation that no longer matches the codebase. For the maintenance process
(update triggers, enforcement hierarchy), see `framework/guides/maintenance.md`.

______________________________________________________________________

## 1. Broken path references

Every path in backticks in `AGENTS.md` and `docs/` must resolve to a file on disk.

```bash
grep -rnoE '`[^`]+\.(md|sh|py|ts|js|toml|yaml|yml)[^`]*`' AGENTS.md docs/ \
  | tr -d '`' \
  | while IFS=: read file line match; do
      [ -f "$match" ] || echo "BROKEN in $file:$line → $match"
    done
```

Flag every path that doesn't resolve with the file and line number where it appears.

______________________________________________________________________

## 2. Command references

Every script listed in `AGENTS.md`'s commands section must exist on disk. Do not execute — verify
existence only. Also check: does the command description still match what the script does? (Read
the script header.)

```bash
grep -oE 'scripts/[^ ]+\.(sh|py)' AGENTS.md | while read script; do
  [ -f "$script" ] || echo "MISSING: $script"
done
```

______________________________________________________________________

## 3. Aspirational conventions

A convention is aspirational when the codebase doesn't follow it. For each convention in
`AGENTS.md`, find 2–3 call sites that should follow it. If the codebase consistently does the
opposite, or the convention references a module, function, or tool that no longer exists — flag
it.

______________________________________________________________________

## 4. Diagram accuracy

For each Mermaid diagram, compare node labels to the actual directory structure and module names.
Flag any node that references a renamed or removed component, any edge that no longer reflects
how the system works, and any surrounding prose that contradicts the diagram.

______________________________________________________________________

## 5. Decision record status

Every ADR in `docs/decisions/` must have a status field (`Accepted`, `Superseded`, `Deprecated`).

Flag if:
- No status field
- Status is `Accepted` but the codebase no longer follows the decision
- A newer ADR covers the same decision without this one marked `Superseded`

______________________________________________________________________

## 6. Spec status

Every spec in `docs/specs/` must have a status header block and be in the correct directory
for that status. Cross-check against `docs/specs/index.md`.

Flag if:
- No status header block
- Status is `Live` but the spec describes behaviour the system no longer implements — the spec
  must be updated or deprecated
- Status is `In Progress` but no active plan exists in `docs/plans/` referencing it — either
  the plan was completed and the spec wasn't promoted to `live/`, or the work was abandoned
  and the spec should be `Deprecated`
- Status is `Accepted` but an ADR recording the decision to adopt this approach doesn't exist
  in `docs/decisions/`
- File is in the wrong directory for its status (e.g. a `Live` spec still in `docs/specs/`
  root instead of `docs/specs/live/`)
- `docs/specs/index.md` entry doesn't match the spec's current status or location
