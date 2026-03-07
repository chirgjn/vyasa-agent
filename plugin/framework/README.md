# Vyasa Framework

The documentation framework that ships inside the vyasa plugin. It defines how to structure, write, and maintain project docs so AI coding agents find the right information fast.

## What it contains

| Path | What it is |
|---|---|
| `managing-project-information.md` | The five content buckets — where every piece of information belongs and why |
| `auditing-anti-patterns.md` | What broken docs look like — wrong placement, missing framing, duplication, broken discoverability |
| `guides/` | Writing guides and maintenance checklists for each doc type |

## How it's used

Agents reference the guides during audits and fixes. `auditing-anti-patterns.md` is a pragmatic, self-contained audit guide — broad but not exhaustive, complements the full audit pipeline. `managing-project-information.md` is the placement authority.

For a full list of guides and when to read each one, see the routing table in `AGENTS.md`.
