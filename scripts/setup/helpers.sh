#!/usr/bin/env bash
# Shared helpers — source this file, do not run directly
ok()   { echo "  ✓ $*"; }
info() { echo "  → $*"; }
warn() { echo "  ⚠ $*"; }
fail() { echo "  ✗ $*" >&2; exit 1; }
