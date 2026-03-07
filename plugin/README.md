# vyasa

> **AI agent?** Read [AGENTS.md](AGENTS.md) first.

Claude Code plugin that keeps your project documentation accurate and discoverable. Agents auto-trigger when you edit docs — or invoke orchestrators manually for larger tasks.

## Installation

**1. Add the marketplace** (one-time):

```
/plugin marketplace add chirgjn/claude-code-plugins
```

**2. Install vyasa:**

```
/plugin install vyasa@cj-cc-plugins
```

**3. Verify dependencies:**

```
/vyasa:setup
```

## What it does

**Audit your docs.** A three-phase pipeline checks every document for validity, structural quality, prose, conventions, discoverability, staleness, and sizing — then ranks all findings by severity and offers to fix them.

**Bootstrap a new project.** Analyzes your codebase and generates a complete `AGENTS.md` with identity, structure map, commands, conventions, and a routing table. Creates `layout.md` so all other agents know where your docs live.

**Write docs that AI agents can actually use.** Produces reference docs, ADRs, and diagrams that follow the framework — correctly placed, correctly structured, linked into the routing table.

**Keep docs in sync with code.** Detects structural changes (renamed directories, new modules, changed commands) and updates the affected docs automatically. Also auto-triggers on doc edits via hooks.

## Framework

Vyasa is built on an opinionated documentation framework — a taxonomy for where information lives, guides for writing each doc type, and an audit process for finding problems. See [Managing project information](framework/managing-project-information.md) if you want to understand or contribute to the underlying guidelines.

## License

[MIT](LICENSE)
