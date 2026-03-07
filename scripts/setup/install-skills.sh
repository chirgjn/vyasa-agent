#!/usr/bin/env bash
# Install required Claude Code skills at project level via the skills CLI
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

echo "Claude Code skills"

# playwright-cli skill — used for mermaid diagram verification
SKILL="eidam/playwright-cli"
SKILL_NAME="playwright-cli"

if pnpm dlx skills list 2>/dev/null | grep -qw "$SKILL_NAME"; then
    ok "$SKILL_NAME skill (already installed)"
else
    info "installing $SKILL_NAME skill..."
    if ! pnpm dlx skills add "$SKILL" --agent claude-code -y; then
        warn "Failed to install $SKILL_NAME skill."
        warn "Install manually: pnpm dlx skills add $SKILL --agent claude-code -y"
        warn "Or browse skills at https://skills.sh/"
        exit 1
    fi
    ok "$SKILL_NAME skill installed"
fi
