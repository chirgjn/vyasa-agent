#!/usr/bin/env bash
set -euo pipefail
# Run `uv sync` when uv.lock changed after a merge or checkout.
# Used as a prek post-merge and post-checkout hook.
#
# prek passes the git hook arguments through:
#   post-merge:    $1 = squash flag
#   post-checkout: $1 = prev HEAD, $2 = new HEAD, $3 = branch flag

changed_files() {
    local prev_head="${1:-}"
    local new_head="${2:-HEAD}"

    if [ -n "$prev_head" ]; then
        git diff-tree -r --name-only --no-commit-id "$prev_head" "$new_head"
    elif git rev-parse --verify ORIG_HEAD >/dev/null 2>&1; then
        git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD
    else
        # No reference point — can't determine what changed
        return 1
    fi
}

# post-checkout provides prev/new HEAD as $1/$2; post-merge only provides a squash flag.
if [ "${3+set}" = set ]; then
    # post-checkout: $1=prev HEAD, $2=new HEAD, $3=branch flag
    files=$(changed_files "$1" "$2") || exit 0
else
    # post-merge: fall back to ORIG_HEAD
    files=$(changed_files) || exit 0
fi

if echo "$files" | grep -q '^uv\.lock$'; then
    echo "uv.lock changed — running uv sync..."
    uv sync
fi
