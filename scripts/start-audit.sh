#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# AuditSkill: Interactive Setup & Audit Bootstrap Script
# Launches an isolated, canon-grounded engineering audit on any target project.
# ==============================================================================

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RED="\033[0;31m"
RESET="\033[0m"

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BOLD}${CYAN}================================================================${RESET}"
echo -e "${BOLD}${CYAN}          AuditSkill — Isolated Engineering Audit Harness        ${RESET}"
echo -e "${CYAN}      Grounded in 15 Software Engineering Proof Canons          ${RESET}"
echo -e "${BOLD}${CYAN}================================================================${RESET}"
echo ""

# 1. Target directory input
TARGET_PATH="${1:-}"

if [[ -z "$TARGET_PATH" ]]; then
    echo -e "${BOLD}Select target codebase to audit:${RESET}"
    read -rp "Enter local repository or folder path: " TARGET_PATH
fi

# Expand tilde and get absolute path
TARGET_PATH="${TARGET_PATH/#\~/$HOME}"
TARGET_PATH="$(realpath "$TARGET_PATH" 2>/dev/null || echo "")"

if [[ -z "$TARGET_PATH" || ! -d "$TARGET_PATH" ]]; then
    echo -e "${RED}Error: Target directory '$TARGET_PATH' does not exist.${RESET}"
    exit 1
fi

echo -e "Target Codebase: ${GREEN}$TARGET_PATH${RESET}"
echo ""

# 2. Check Git Isolation on target
echo -e "${BOLD}[1/4] Checking Git isolation boundary...${RESET}"
if git -C "$TARGET_PATH" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    CURRENT_BRANCH=$(git -C "$TARGET_PATH" branch --show-current 2>/dev/null || echo "detached")
    echo -e "Current branch on target: ${YELLOW}$CURRENT_BRANCH${RESET}"
    
    if [[ "$CURRENT_BRANCH" =~ ^(main|master|production|staging)$ ]]; then
        AUDIT_DATE=$(date -u +"%Y%m%d")
        DEFAULT_BRANCH="audit/${AUDIT_DATE}-baseline"
        echo -e "${YELLOW}Warning: Target is on protected branch '$CURRENT_BRANCH'.${RESET}"
        read -rp "Create and switch to isolated branch [$DEFAULT_BRANCH]? (Y/n): " CREATE_BRANCH
        CREATE_BRANCH="${CREATE_BRANCH:-y}"
        
        if [[ "$CREATE_BRANCH" =~ ^[Yy]$ ]]; then
            git -C "$TARGET_PATH" checkout -b "$DEFAULT_BRANCH"
            echo -e "${GREEN}✓ Switched to dedicated branch: $DEFAULT_BRANCH${RESET}"
        else
            echo -e "${RED}Cannot run audit directly on $CURRENT_BRANCH. Aborting.${RESET}"
            exit 1
        fi
    else
        echo -e "${GREEN}✓ Target is on an isolated branch: $CURRENT_BRANCH${RESET}"
    fi
else
    echo -e "${YELLOW}Target is a standalone non-git directory.${RESET}"
fi

# 3. Setup Obsidian-Friendly Audit Workspace inside or linked
echo ""
echo -e "${BOLD}[2/4] Initializing Obsidian-ready Audit Folder...${RESET}"

AUDIT_DIR="$TARGET_PATH/audit"
if [[ -d "$AUDIT_DIR" ]]; then
    echo -e "Existing audit directory found at: ${CYAN}$AUDIT_DIR${RESET}"
else
    mkdir -p "$AUDIT_DIR/findings" "$AUDIT_DIR/tickets" "$AUDIT_DIR/phases"
    echo -e "${GREEN}✓ Created audit directory structure at: $AUDIT_DIR${RESET}"
fi

# Link wiki knowledge graph to target for Obsidian graph browsing
if [[ ! -e "$AUDIT_DIR/wiki" ]]; then
    ln -sf "$SKILL_ROOT/wiki" "$AUDIT_DIR/wiki"
    echo -e "${GREEN}✓ Linked Knowledge Graph (15 Canons) into $AUDIT_DIR/wiki${RESET}"
fi

# 4. Verify Boundary
echo ""
echo -e "${BOLD}[3/4] Running Isolation Verification...${RESET}"
"$SKILL_ROOT/scripts/verify-isolation.sh" "$TARGET_PATH"

# 5. Launch Instructions for Claude Code / AGY
echo ""
echo -e "${BOLD}${CYAN}================================================================${RESET}"
echo -e "${BOLD}${GREEN}[4/4] Environment Ready! Choose your agent execution mode:${RESET}"
echo -e "${BOLD}${CYAN}================================================================${RESET}"
echo ""
echo -e "${BOLD}Option A: Run with Claude Code (Haiku / Sonnet Scouting):${RESET}"
echo -e "  cd \"$TARGET_PATH\""
echo -e "  ${CYAN}claude \"Read $SKILL_ROOT/SKILL.md and $SKILL_ROOT/wiki/index.md. Conduct Phase 1 Baseline Reconnaissance using Haiku / Sonnet for risky code, RLS leaks, and architectural coupling. Write Obsidian-formatted findings to audit/findings/AUD-XXX.md.\"${RESET}"
echo ""
echo -e "${BOLD}Option B: Run with Antigravity Swarm (Multi-Model):${RESET}"
echo -e "  Open this workspace in Antigravity and run ${CYAN}/swarm board${RESET} (alt+s)."
echo ""
echo -e "${BOLD}Obsidian Ready:${RESET}"
echo -e "  Open ${CYAN}$AUDIT_DIR${RESET} in Obsidian to visualize the live Knowledge Graph & findings."
echo -e "${BOLD}${CYAN}================================================================${RESET}"
