#!/usr/bin/env bash
# Install taplo (TOML formatter/linter) if not already present
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

echo "taplo"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCAL_BIN="${REPO_ROOT}/.local/bin"

# Add project-local bin to PATH so taplo installed here is found
export PATH="${LOCAL_BIN}:${PATH}"

if command -v taplo &>/dev/null; then
    ok "taplo $(taplo --version) (already installed)"
    exit 0
fi

TAPLO_VERSION="$(grep -m1 'taplo' "${REPO_ROOT}/.mise.toml" | grep -o '[0-9][0-9.]*')"

info "installing taplo ${TAPLO_VERSION}..."
if command -v mise &>/dev/null; then
    mise install taplo
elif command -v brew &>/dev/null; then
    brew install taplo
else
    case "$(uname -s)-$(uname -m)" in
        Darwin-arm64)  ARCH="darwin-aarch64" ;;
        Darwin-x86_64) ARCH="darwin-x86_64" ;;
        Linux-x86_64)  ARCH="linux-x86_64" ;;
        Linux-aarch64) ARCH="linux-aarch64" ;;
        *) fail "unsupported platform: $(uname -s)-$(uname -m). Install taplo manually." ;;
    esac
    info "falling back to direct binary download (${ARCH})..."
    mkdir -p "${LOCAL_BIN}"
    curl -fsSL "https://github.com/tamasfe/taplo/releases/download/${TAPLO_VERSION}/taplo-${ARCH}.gz" \
        | gunzip > "${LOCAL_BIN}/taplo"
    chmod +x "${LOCAL_BIN}/taplo"
fi

if ! command -v taplo &>/dev/null; then
    fail "taplo was not found on PATH after install.
       Then verify with: taplo --version"
fi

ok "taplo $(taplo --version)"
