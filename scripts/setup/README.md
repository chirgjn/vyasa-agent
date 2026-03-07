# Project Dev Setup Scripts

Project dev setup for this repo — not relevant to consumers of the vyasa plugin. Run individual scripts as needed, or run `scripts/setup/setup.sh` to install the full project dev environment.

## Scripts

| Script | What it does | Requires |
|---|---|---|
| `install-uv.sh` | Install [uv](https://docs.astral.sh/uv/) via Homebrew or official script | — |
| `install-deps.sh` | `uv sync` — install all project dependencies into `.venv` (uv auto-fetches Python >=3.14) | `install-uv.sh` |
| `install-jq.sh` | Install [jq](https://jqlang.org) via Homebrew or binary download | — |
| `install-taplo.sh` | Install [taplo](https://taplo.tamasfe.dev) via mise, Homebrew, or binary download | — |
| `install-yamllint.sh` | Verify [yamllint](https://yamllint.readthedocs.io) + [yamlfix](https://lyz-code.github.io/yamlfix/) + [actionlint](https://github.com/rhysd/actionlint) are available via `uv run` (installed by `install-deps.sh`) | `install-deps.sh` |
| `install-gh.sh` | Install [gh](https://cli.github.com) via Homebrew or binary download; prompts for `gh auth login` | — |
| `install-pnpm.sh` | Install [pnpm](https://pnpm.io) via official script | — |
| `install-prettier.sh` | `pnpm install` at repo root — installs prettier as a project dev dependency | `install-pnpm.sh` |
| `install-playwright-cli.sh` | Install `playwright-cli` globally via pnpm | `install-pnpm.sh` |
| `install-claude-plugins.sh` | Add the `cj-cc-plugins` marketplace and install all Claude Code plugins | Claude Code CLI |
| `install-skills.sh` | Install required Claude Code skills at project level via `pnpm dlx skills` | — |
| `verify.sh` | Run prettier, shellcheck, and yamllint to confirm the setup works | `install-deps.sh` |

## Dependencies

```
install-uv.sh
└── install-deps.sh
    └── verify.sh
install-jq.sh               (standalone)
install-taplo.sh            (standalone)
install-yamllint.sh         (requires install-deps.sh)
install-gh.sh               (standalone)
install-pnpm.sh
├── install-prettier.sh
└── install-playwright-cli.sh
install-claude-plugins.sh   (standalone — needs claude CLI)
install-skills.sh           (standalone)
```

## Common agent tasks

**Python environment only (no tooling):**

```bash
scripts/setup/install-uv.sh
scripts/setup/install-deps.sh
```

**Mermaid diagram verification only:**

```bash
scripts/setup/install-pnpm.sh
scripts/setup/install-playwright-cli.sh
```

**Claude Code plugins only:**

```bash
scripts/setup/install-claude-plugins.sh
```

**Verify existing setup:**

```bash
scripts/setup/verify.sh
```
