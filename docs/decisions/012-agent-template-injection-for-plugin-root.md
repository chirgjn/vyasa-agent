# 012 — Agent template injection for plugin root path

**Status:** Accepted
**Date:** 2026-03-08

## Context

Vyasa agents reference framework guides and scripts using paths relative to the plugin
root — e.g. `@@VYASA_ROOT@@/framework/managing-project-information.md`. At runtime, the
plugin may be installed to any path under `~/.claude/plugins/cache/`, so these paths
cannot be hardcoded at authoring time.

`CLAUDE_PLUGIN_ROOT` — the environment variable that resolves this — is only injected
into hook command strings. It is not available inside agent system prompts. Agents that
tried to read it via a bash block received an empty string silently and produced broken
file references with no error.

The prior workaround — instructing the parent to forward `VYASA_ROOT=<path>` in every
dispatch message — was fragile: it added noise to the `SessionStart` context injection,
required every caller to remember the convention, and broke whenever an agent was invoked
without the parent having seen the hook output.

## Decision

Agent files use `@@VYASA_ROOT@@` as a placeholder. A `SessionStart` hook runs
`inject-vyasa-root.sh`, which resolves the plugin root from its own path
(`$(cd "$(dirname "$0")/.." && pwd)`), substitutes `@@VYASA_ROOT@@` with the real path
in every agent file, and records injected filenames in a marker file
(`agents/.vyasa-root-injected`, one filename per line). On each `SessionStart`, only
agents absent from the marker are processed — so new agents added after first install
are picked up automatically without any manual intervention.

## Consequences

- Agents resolve framework paths correctly regardless of installation location, with no
  caller cooperation required.
- New agent files are injected automatically on the next session; no marker reset needed.
- Each `SessionStart` does a fast per-file grep against the marker list; cost is
  proportional to the number of new agents since last session (typically zero).
- Agent files in the repository contain `@@VYASA_ROOT@@` placeholders, not real paths.
  The installed copies differ from source. Developers working directly from the repo
  with `--plugin-dir` will trigger injection on first session.

## Alternatives considered

**Caller forwarding via SessionStart context.** The `SessionStart` hook printed
`VYASA_ROOT=<path>` as context and instructed the parent to include it in every agent
dispatch. This worked when the parent had seen the hook output, but was invisible to
agents invoked outside that flow and added a permanent forwarding obligation to every
caller.

**Ask the user.** Fall back to asking the user for the path when `VYASA_ROOT` was not
provided. Correct as a last resort but poor UX and unnecessary given that the plugin
always knows its own location.

**`CLAUDE_SKILL_DIR` via skills.** The official `${CLAUDE_SKILL_DIR}` substitution
solves the same problem for skills. Rewriting agents as skills with `context: fork`
would have made the variable available, but would have changed the invocation model and
removed agent-specific features (color, tool restrictions, model selection per agent).
