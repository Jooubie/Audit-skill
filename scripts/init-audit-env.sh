#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Helper to initialize an isolated audit worktree/branch for a target codebase
# Usage: ./scripts/init-audit-env.sh <path-to-target-repo> [audit-branch-name]
# ==============================================================================

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <path-to-target-repo> [audit-branch-name]"
    exit 1
fi

TARGET_REPO="$1"
AUDIT_DATE=$(date -u +"%Y%m%d")
AUDIT_BRANCH="${2:-audit/${AUDIT_DATE}-baseline}"

if [[ ! -d "$TARGET_REPO/.git" ]]; then
    echo "Error: $TARGET_REPO is not a git repository."
    exit 1
fi

echo "Initializing isolated audit branch in target repo: $TARGET_REPO"
cd "$TARGET_REPO"

echo "Creating dedicated branch: $AUDIT_BRANCH"
git checkout -b "$AUDIT_BRANCH"

echo "Branch $AUDIT_BRANCH successfully created."
echo "Remember: Phase 1 (Baseline Audit) is strictly read-only."
