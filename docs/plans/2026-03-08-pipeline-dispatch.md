# Plan: Pipeline Dispatch

Execution plan for implementing subagent dispatch in `full-audit` and `fix-orchestrator`. Archive
to `docs/archive/plans/` once all pending changes are merged.

For what to implement and how, see `docs/specs/pipeline-dispatch.md`.

---

## Files to Change

| File                                   | Change                                                            | Status  |
| -------------------------------------- | ----------------------------------------------------------------- | ------- |
| `plugin/agents/full-audit.md`          | Add dispatch instructions + batch loop per phase; allowlist tools | Pending |
| `plugin/agents/fix-orchestrator.md`    | Add dispatch instructions + batch loop per phase; allowlist tools | Pending |
| `plugin/scripts/generate-run-id.sh`    | New script                                                        | Done    |
| `plugin/scripts/check-runtime-deps.sh` | openssl soft check                                                | Done    |
| `plugin/scripts/README.md`             | New script row                                                    | Done    |
| `docs/audit-pipeline.md`               | Updated run-id snippet to use script                              | Done    |
