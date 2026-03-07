# Specs Index

Index of all specs regardless of status. A spec is the exhaustive, authoritative description of
how something works — thorough enough that an implementer never has to guess. For the reasoning
behind choices in a spec, see the linked ADRs in `docs/decisions/index.md`.

**Lifecycle:** Proposed → Accepted → In Progress → Live. Deprecated and Rejected specs move to
`docs/archive/specs/`.

**Locations by status:**

Specs live in different directories depending on their lifecycle stage:

| Status               | Location                  |
| -------------------- | ------------------------- |
| Proposed, Accepted   | `docs/specs/`             |
| In Progress          | `docs/specs/in-progress/` |
| Live                 | `docs/specs/live/`        |
| Deprecated, Rejected | `docs/archive/specs/`     |

---

All specs, regardless of status:

| Spec                                         | Status   | Summary                                                                                        |
| -------------------------------------------- | -------- | ---------------------------------------------------------------------------------------------- |
| [pipeline-dispatch.md](pipeline-dispatch.md) | Accepted | Subagent dispatch mechanism, allowlist syntax, and batch sizes for the audit and fix pipelines |
