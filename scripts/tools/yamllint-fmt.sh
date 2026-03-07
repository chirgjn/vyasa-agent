#!/usr/bin/env bash
set -euo pipefail
# Fix then lint YAML files: yamlfix auto-fixes, yamllint validates.
# Usage: yamllint-fmt.sh [file ...]  (defaults to all *.yaml/*.yml in the project)
# Note: yamlfix is skipped for .github/ files — it cannot safely reformat GHA workflows.
if [ $# -eq 0 ]; then
    # shellcheck disable=SC2046
    set -- $(find . \( -name '*.yaml' -o -name '*.yml' \) \
        -not -path './.venv/*' -not -path './.git/*' -not -path './node_modules/*' -not -path '*/node_modules/*' \
        -not -name 'pnpm-lock.yaml')
fi

# Filter out files that should never be linted (node_modules, lock files), regardless of how args were passed
FILTERED=()
for f in "$@"; do
    case "$f" in
        */node_modules/*|node_modules/*|*pnpm-lock.yaml) ;;
        *) FILTERED+=("$f") ;;
    esac
done
set -- "${FILTERED[@]+"${FILTERED[@]}"}"

[ $# -eq 0 ] && exit 0

# yamlfix pass: exclude .github/ (GHA workflows use block scalars that yamlfix mangles)
YAMLFIX_TARGETS=""
for f in "$@"; do
    case "$f" in
        ./.github/*|.github/*) ;;
        *) YAMLFIX_TARGETS="$YAMLFIX_TARGETS $f" ;;
    esac
done
if [ -n "$YAMLFIX_TARGETS" ]; then
    # shellcheck disable=SC2086
    uv run yamlfix $YAMLFIX_TARGETS
fi

uv run yamllint "$@"
