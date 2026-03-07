# Plugin Scripts

Scripts that ship inside the plugin and are called by agents and hooks in consumer projects.

## Scripts

| Script | What it does |
|---|---|
| `vyasa-run.sh` | Run a command and log it to `.vyasa/<run-id>/commands.log`; wraps scripts and shell one-liners |
| `vyasa-claim.sh` | Claim protocol used by `doc-editor`: claim / confirm / commit / release before editing any document |
| `find-docs-dir.sh` | Reads `layout.md` YAML frontmatter to locate the `docs/` directory for a given project root |
| `post-write-lint.sh` | Consumer PostToolUse hook: flags `.md` files in `$CLAUDE_PROJECT_DIR/.claude/vyasa-md-changed` for deferred formatting |
| `stop-prettier.sh` | Consumer Stop hook: runs prettier once on all flagged `.md` files at turn end, skipping deleted files |
| `lint-commands.sh` | Checks `AGENTS.md` commands section — flags scripts listed there that don't exist on disk |
| `lint-filehealth.sh` | Checks file sizing — flags files under 15 lines (too thin) or over 200 lines (bloated) |
| `lint-refs.sh` | Checks for broken file references in docs — flags backtick paths that don't resolve |
| `lint-routing.sh` | Checks routing table entries — flags entries whose target files don't exist |
| `lint-structure.sh` | Checks doc structure conventions — scoped openings, when-before-how ordering |
| `check-runtime-deps.sh` | Validates that required tools are available in the consumer environment; installs prettier if missing |
| `install-prettier.sh` | Installs prettier into `<plugin-root>/node_modules/` via pnpm; called by `check-runtime-deps.sh` |
| `generate-run-id.sh` | Generates a unique 8-character hex run ID; uses openssl if available, falls back to `/dev/urandom` |
| `build-registry.sh` | Enumerates project markdown files, assigns stable doc-ids, writes `registry.json` |
| `parse-phase-summary.sh` | Extracts the PHASE SUMMARY block from an audit report file; outputs JSON |
| `detect-doc-changes.sh` | Detects which docs changed in the last git commit; used by `doc-maintenance` agent |

## Output contract

Lint scripts (`lint-*.sh`, `check-runtime-deps.sh`) follow the shared output format:

```
FIXED: <short description of what was changed>
REMAINING: <severity> — <short description of what needs judgment>
```

Always exit 0. Never mix diagnostic prose into stdout.
