#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Isolated Engineering Audit Environment Verification
# Verifies that the audit workspace satisfies the Isolation Contract.
# Usage: ./scripts/verify-isolation.sh [target-codebase-path]
# ==============================================================================

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

TARGET_DIR="${1:-.}"

echo -e "${BOLD}Running Isolated Engineering Audit Boundary Verification...${RESET}"
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "Target:    $(realpath "$TARGET_DIR")"
echo ""

ERRORS=0
WARNINGS=0

# 1. Check workspace location
CURRENT_DIR="$(pwd)"
echo -n "Checking workspace isolation: "
if [[ "$CURRENT_DIR" =~ /Audit-skill$ ]]; then
    echo -e "${GREEN}PASS${RESET} (Dedicated workspace: $CURRENT_DIR)"
else
    echo -e "${YELLOW}WARN${RESET} (Current directory is $CURRENT_DIR, expected dedicated audit directory)"
    WARNINGS=$((WARNINGS + 1))
fi

# 2. Check Git branch isolation on target
echo -n "Checking Git branch isolation: "
if git -C "$TARGET_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    CURRENT_BRANCH=$(git -C "$TARGET_DIR" branch --show-current 2>/dev/null || echo "detached")
    
    # If target is this tool repo itself, main is normal; if target is the application being audited, main is blocked
    IS_SKILL_REPO=0
    if [[ "$(realpath "$TARGET_DIR")" == "$(realpath "$CURRENT_DIR")" && -f "$CURRENT_DIR/SKILL.md" ]]; then
        IS_SKILL_REPO=1
    fi

    if [[ $IS_SKILL_REPO -eq 0 && "$CURRENT_BRANCH" =~ ^(main|master|production|staging)$ ]]; then
        echo -e "${RED}FAIL${RESET} (Target is on protected branch: '$CURRENT_BRANCH'. Audits must run on an isolated audit branch)"
        ERRORS=$((ERRORS + 1))
    elif [[ $IS_SKILL_REPO -eq 1 ]]; then
        echo -e "${GREEN}PASS${RESET} (Audit skill workspace on: $CURRENT_BRANCH)"
    else
        echo -e "${GREEN}PASS${RESET} (Target on isolated branch: $CURRENT_BRANCH)"
    fi
else
    echo -e "${GREEN}PASS${RESET} (Non-git directory)"
fi

# 3. Check for inherited circular review or unverified automation hooks (excluding git .sample files)
echo -n "Checking for legacy automation hooks: "
HOOK_FOUND=0
for hook_path in "$TARGET_DIR/.git/hooks" "$TARGET_DIR/.husky" "$TARGET_DIR/.claude/hooks"; do
    if [[ -d "$hook_path" ]]; then
        ACTIVE_HOOKS=$(find "$hook_path" -maxdepth 1 -type f ! -name "*.sample" 2>/dev/null | wc -l)
        if [[ $ACTIVE_HOOKS -gt 0 ]]; then
            HOOK_FOUND=1
            echo -e "${YELLOW}WARN${RESET} (Found $ACTIVE_HOOKS active hooks in $hook_path)"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
done
if [[ $HOOK_FOUND -eq 0 ]]; then
    echo -e "${GREEN}PASS${RESET} (No active legacy hook traps found)"
fi

# 4. Check for uncommitted dirty state
echo -n "Checking git clean state: "
if git -C "$TARGET_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if [[ -n "$(git -C "$TARGET_DIR" status --porcelain 2>/dev/null)" ]]; then
        echo -e "${YELLOW}WARN${RESET} (Uncommitted changes present in target)"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}PASS${RESET} (Target repository is clean)"
    fi
else
    echo -e "${GREEN}PASS${RESET} (N/A)"
fi

echo ""
echo -e "${BOLD}--- Isolation Check Summary ---${RESET}"
echo -e "Errors:   $ERRORS"
echo -e "Warnings: $WARNINGS"

if [[ $ERRORS -gt 0 ]]; then
    echo -e "${RED}Isolation check failed. Fix errors before proceeding with the audit.${RESET}"
    exit 1
else
    echo -e "${GREEN}Isolation boundary verified. Audit environment is ready.${RESET}"
    exit 0
fi
