#!/usr/bin/env bash
# Install gh (GitHub CLI) if not already present
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

echo "gh (GitHub CLI)"

if command -v gh &>/dev/null; then
    ok "gh $(gh --version | head -1 | awk '{print $3}') (already installed)"
    exit 0
fi

info "installing gh..."
if command -v brew &>/dev/null; then
    brew install gh
else
    # Fallback: download binary from GitHub releases
    GH_VERSION="2.65.0"
    OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
    ARCH="$(uname -m)"
    case "${ARCH}" in
        x86_64)  ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) fail "unsupported architecture: ${ARCH}" ;;
    esac
    DEST_DIR="$HOME/.local/bin"
    mkdir -p "$DEST_DIR"
    TARBALL="gh_${GH_VERSION}_${OS}_${ARCH}.tar.gz"
    info "downloading gh ${GH_VERSION} (${OS}/${ARCH})..."
    curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/${TARBALL}" \
        | tar -xz -C "$DEST_DIR" --strip-components=2 "gh_${GH_VERSION}_${OS}_${ARCH}/bin/gh"
    export PATH="$DEST_DIR:$PATH"
fi

if ! command -v gh &>/dev/null; then
    fail "gh was not found on PATH after install.
       If installed via binary fallback, try: export PATH=\"\$HOME/.local/bin:\$PATH\"
       Then verify with: gh --version"
fi

ok "gh $(gh --version | head -1 | awk '{print $3}')"

# Guide the user through authentication if not already logged in
if ! gh auth status &>/dev/null; then
    echo ""
    warn "gh is not authenticated. Run the following to log in:"
    echo "       gh auth login"
    echo ""
    echo "       Recommended options:"
    echo "         - Account type: GitHub.com"
    echo "         - Protocol:     SSH"
    echo "         - SSH key:      Generate a new SSH key (or use an existing one)"
    echo "         - Auth method:  Login with a web browser"
    echo ""
    echo "       Then configure git to use gh as the credential helper:"
    echo "       gh auth setup-git"
fi
