#!/usr/bin/env bash
# Generate a unique 8-character hex run ID for an audit run.
#
# Usage:
#   generate-run-id.sh
#
# Prints an 8-character hex string to stdout.
# Uses openssl if available, falls back to /dev/urandom + od.
#
# Exit codes:
#   0 - Success
#   1 - Could not generate random bytes

set -euo pipefail

if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 4
elif [[ -r /dev/urandom ]]; then
    od -An -tx1 -N4 /dev/urandom | tr -d ' \n'
    echo
else
    echo "Error: cannot generate run ID — openssl not found and /dev/urandom not readable" >&2
    exit 1
fi
