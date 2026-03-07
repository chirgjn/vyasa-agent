#!/usr/bin/env bash
# Install jq if not already present
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

echo "jq"

if command -v jq &>/dev/null; then
    ok "jq $(jq --version) (already installed)"
    exit 0
fi

info "installing jq..."
if command -v brew &>/dev/null; then
    brew install jq
else
    # Fallback: download binary from GitHub releases
    JQ_VERSION="1.7.1"
    OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
    ARCH="$(uname -m)"
    case "${ARCH}" in
        x86_64)  ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) fail "unsupported architecture: ${ARCH}" ;;
    esac
    DEST="$HOME/.local/bin/jq"
    mkdir -p "$(dirname "$DEST")"
    info "downloading jq ${JQ_VERSION} (${OS}/${ARCH})..."
    curl -fsSL "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-${OS}-${ARCH}" -o "$DEST"
    chmod +x "$DEST"
    export PATH="$HOME/.local/bin:$PATH"
fi

if ! command -v jq &>/dev/null; then
    fail "jq was not found on PATH after install.
       If installed via binary fallback, try: export PATH=\"\$HOME/.local/bin:\$PATH\"
       Then verify with: jq --version"
fi

ok "jq $(jq --version)"
