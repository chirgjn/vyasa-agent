#!/usr/bin/env bash
# Install required Claude Code plugins listed in .claude/settings.json
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

echo "Claude Code plugins"

if ! command -v claude &>/dev/null; then
    warn "claude CLI not found — skipping plugin installation."
    warn "Install Claude Code from https://claude.ai/download, then re-run:"
    warn "  scripts/setup/install-claude-plugins.sh"
    exit 0
fi

# Register the cj-cc-plugins marketplace from GitHub
if claude plugin marketplace list 2>/dev/null | grep -q "cj-cc-plugins"; then
    ok "cj-cc-plugins marketplace (already added)"
else
    info "adding cj-cc-plugins marketplace..."
    if claude plugin marketplace add chirgjn/claude-code-plugins --scope project 2>/dev/null; then
        ok "cj-cc-plugins marketplace"
    else
        warn "failed to add cj-cc-plugins marketplace"
    fi
fi

PLUGINS=(
    superpowers@claude-plugins-official
    commit-commands@claude-plugins-official
    feature-dev@claude-plugins-official
    pr-review-toolkit@claude-plugins-official
    code-review@claude-plugins-official
    code-simplifier@claude-plugins-official
    claude-code-setup@claude-plugins-official
    claude-md-management@claude-plugins-official
    plugin-dev@claude-plugins-official
)

INSTALLED=$(claude plugin list 2>/dev/null || true)
FAILED=()

for plugin in "${PLUGINS[@]}"; do
    name="${plugin%@*}"
    if echo "$INSTALLED" | grep -qw "$name"; then
        ok "$plugin (already installed)"
    else
        info "installing $plugin..."
        if claude plugin install "$plugin" --scope project; then
            ok "$plugin"
        else
            warn "failed to install $plugin — skipping"
            FAILED+=("$plugin")
        fi
    fi
done

if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo ""
    warn "The following plugins could not be installed:"
    for p in "${FAILED[@]}"; do
        warn "  - $p"
    done
    warn "You can install them manually with: claude plugin install <plugin> --scope project"
    warn "Or open this project in Claude Code and accept the plugin prompt."
    exit 1
fi
