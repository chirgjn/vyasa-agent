# Writing Conventions

How to phrase, categorize, and maintain conventions. For deciding *when to add a convention and where it lives*, see "Writing Good Conventions" in `framework/managing-project-information.md`. For writing the `AGENTS.md` that conventions live in, see `framework/guides/writing-agents-md.md`.

______________________________________________________________________

## Phrasing

Each convention should follow the pattern: **what to do + where it applies + what NOT to do**. The negative constraint is what prevents the mistake.

| Phrasing | Problem | Better |
|---|---|---|
| "Use services for business logic" | Doesn't say where NOT to put it | "Services, not fat models — business logic lives in `services.py`, models only define fields and DB constraints" |
| "Use django-waffle for feature flags" | Doesn't prevent the alternative | "Feature flags via django-waffle — check with `flag_is_active()`, never `settings.py` booleans" |
| "Be careful with cross-domain imports" | Vague — what counts as "careful"? | "Never import across domains — use events or the common module" |
| "Tests should be fast" | Not actionable — what's fast? | "Integration tests must complete in under 5s — mock external services, use in-memory SQLite" |

______________________________________________________________________

## Categories with Examples

Conventions cluster into natural categories. Use these as a starting point — not every project needs all of them.

```markdown
# Architectural boundaries
- Never import across packages — shared code goes in packages/shared/
- All inter-service communication goes through the event bus, never direct calls

# Code organization
- Reducers are pure functions — side effects belong in middleware only
- Route handlers call services; never put business logic in route files

# API contracts
- All WebSocket messages use {type: "...", payload: ...} — never ad-hoc shapes
- Pagination uses cursor-based tokens, never page numbers

# Infrastructure constraints
- Lambda handlers must complete in under 10s — offload long work to SQS
- All scheduled jobs must be idempotent — the scheduler guarantees at-least-once

# Tooling patterns
- Translations use next-intl's useTranslations() — never hardcode user-facing strings
- Feature flags via LaunchDarkly SDK — never environment variables

# Data and config
- Schema changes require a migration — never alter tables manually
- Secrets come from Vault at runtime — never commit .env files
```

______________________________________________________________________

## What to Move or Delete

Audit your conventions when:

- `AGENTS.md` is over 80 lines — some conventions probably belong in guides or tool config
- A linter or CI check now covers something you wrote as a convention — delete the written rule
- A convention keeps getting violated despite being documented — it may be too vague, or it may be aspirational (the codebase never followed it)
- You're onboarding and half the conventions feel irrelevant — they may be module-specific or tool-generic

If a convention falls into one of these buckets, it doesn't belong in `AGENTS.md` or docs:

```markdown
# Belongs in linter config:
- Use double quotes for strings          → ruff rule Q000
- Max line length 88 characters          → ruff rule E501
- Sort imports with isort                → ruff rule I001

# Too vague to be actionable:
- Write clean code
- Follow best practices
- Keep functions small

# Tool-generic (belongs in agent-specific global config):
- Use pnpm, not npm
- Use uv run, not python directly

# Aspirational (codebase doesn't follow it):
- All functions must have docstrings     → either enforce via linter or remove
- Every module has 90% coverage          → either enforce via CI or remove
```
