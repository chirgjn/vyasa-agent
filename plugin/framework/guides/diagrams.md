# Diagram Guide

How to create effective Mermaid diagrams — choosing the right type, placing them correctly, and keeping them accurate. Mermaid diagrams are text: they diff, grep, and get updated by agents like any other content. For deciding *whether* to add a diagram, see `framework/managing-project-information.md` § "Diagrams in Documentation."

______________________________________________________________________

## Choosing a Diagram Type

Default to a flowchart. Only reach for specialized types when the concept demands it.

| You want to show... | Use | When to pick this over a flowchart |
|---|---|---|
| How a request flows through services | `flowchart` (`TD` or `LR`) | Default choice for most flows |
| How components interact over time | `sequenceDiagram` | When the order of messages between actors matters |
| Lifecycle of an entity (order, PR, deployment) | `stateDiagram-v2` | When an entity has distinct states with named transitions |
| Module dependencies or system boundaries | `flowchart` with subgraphs | When you need to show grouping and containment |
| Database schema or domain model | `erDiagram` | When cardinality and relationships are the point |
| CI/CD pipeline or release process | `flowchart` (LR direction) | When the process is sequential with branching |
| Class hierarchy or interface contracts | `classDiagram` | When inheritance and method signatures matter |
| Git branching strategy | `gitgraph` | When branch topology is the concept |

**Test:** If unsure, flowchart. Upgrade only if it can't express the key concept (time ordering, state transitions, cardinality).

______________________________________________________________________

## Placement

Placement matters when a diagram could live in 2+ docs or you're tempted to create a standalone file.

- **Embed inline** in the reference doc it supports — not in `docs/diagrams/`. Standalone files become orphans.
- **Position immediately after** the paragraph it illustrates.
- **One canonical home** — if useful to multiple docs, pick one and link from the others:

````markdown
<!-- In docs/api.md — the canonical home -->
## Auth Flow
```mermaid
sequenceDiagram
    ...
```

<!-- In docs/architecture.md — link, don't duplicate -->
## Auth Flow
For the detailed auth sequence, see the diagram in `docs/api.md#auth-flow`.
````

Duplicated diagrams diverge — even text-based ones, because authors update the copy they're looking at.

______________________________________________________________________

## Sizing and Complexity

**Under 15 nodes.** If you can't read it at a glance, split or simplify: collapse into subgraphs, split overview from subsystem, remove implementation detail.

**One idea per diagram.** Auth flow AND data model AND deployment topology in one diagram helps no one.

**Labels over legends.** Nodes should be self-describing. If you need a legend, the diagram is too abstract. `[API Gateway] --> [Order Service] --> [PostgreSQL]`, not `[A] --> [B] --> [C]`.

______________________________________________________________________

## Orientation

`TD` for hierarchies and decision trees. `LR` for pipelines and timelines. Pick whichever minimizes edge crossings.

______________________________________________________________________

## Mermaid Conventions

- **Node IDs:** Short but meaningful — `api --> svc --> db`, not `A --> B --> C`
- **Style every node** in `graph`/`flowchart` — don't rely on renderer defaults
- **Test on your render target** (GitHub light/dark, docs site, IDE preview)

For syntax rules, palettes, and contrast guidelines, see `framework/guides/mermaid.md`.

______________________________________________________________________

## Common Mistakes

| Mistake | What goes wrong | Fix |
|---|---|---|
| **Diagram without context** | Reader doesn't know what they're looking at | Add a 1-2 sentence intro before every diagram |
| **Standalone diagram file** | No one finds it | Embed inline in the doc it supports |
| **Duplicated across docs** | Copies diverge — authors update the one they see | One canonical home, others link |
| **15+ nodes, no subgraphs** | Unreadable wall of boxes | Split or collapse into subgraphs |
| **Generic node labels** | "Service A", "Component B" — meaningless | Use real names: "Order Service", "Redis Cache" |
| **Diagram for a linear list** | Adds complexity without clarity | Use a numbered list instead |
| **Legend-dependent styling** | Reader has to decode before understanding | Make nodes self-describing |

______________________________________________________________________

## Checklist

1. Embedded inline (not standalone file)?
1. Immediately after the text it illustrates?
1. Under 15 nodes?
1. One idea per diagram?
1. Self-describing labels (no legend)?
1. Renders on target background?
1. Exactly one copy?
