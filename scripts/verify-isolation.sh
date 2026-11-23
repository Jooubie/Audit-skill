#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Isolated Engineering Audit Environment Verification
# Verifies that the audit workspace satisfies the Isolation Contract.
# ==============================================================================

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${BOLD}Running Isolated Engineering Audit Boundary Verification...${RESET}"
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
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
    ((WARNINGS++))
fi

# 2. Check Git branch isolation (if inside a git repo)
echo -n "Checking Git isolation: "
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
    if [[ "$CURRENT_BRANCH" =~ ^(main|master|production|staging)$ ]]; then
        echo -e "${RED}FAIL${RESET} (On protected branch: $CURRENT_BRANCH. Must use dedicated audit branch)"
        ((ERRORS++))
    else
        echo -e "${GREEN}PASS${RESET} (Isolated branch: $CURRENT_BRANCH)"
    fi
else
    echo -e "${GREEN}PASS${RESET} (Standalone non-git or initial workspace)"
fi

# 3. Check for inherited circular review or unverified automation hooks
echo -n "Checking for legacy automation hooks: "
HOOK_FOUND=0
for hook_path in ".git/hooks" ".husky" ".claude/hooks"; do
    if [[ -d "$hook_path" ]]; then
        HOOK_COUNT=$(find "$hook_path" -maxdepth 1 -type f 2>/dev/null | wc -l)
        if [[ $HOOK_COUNT -gt 0 ]]; then
            HOOK_FOUND=1
            echo -e "${YELLOW}WARN${RESET} (Found hooks in $hook_path)"
            ((WARNINGS++))
        fi
    fi
done
if [[ $HOOK_FOUND -eq 0 ]]; then
    echo -e "${GREEN}PASS${RESET} (No active legacy hook traps found)"
fi

# 4. Check for uncommitted dirty state
echo -n "Checking git clean state: "
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
        echo -e "${YELLOW}WARN${RESET} (Uncommitted changes present in workspace)"
        ((WARNINGS++))
    else
        echo -e "${GREEN}PASS${RESET} (Workspace is clean)"
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
    echo -e "${GREEN}Isolation boundary verified. Audit workspace is ready.${RESET}"
    exit 0
fi
