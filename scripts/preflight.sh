#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Comprehensive Preflight Audit Script
# Validates code quality, types, dependencies, database migrations, and tests.
# ==============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

FAILED_CHECKS=()
PASSED_CHECKS=()
SKIPPED_CHECKS=()

log_header() {
    echo -e "\n${BOLD}${BLUE}====================================================${NC}"
    echo -e "${BOLD}${BLUE}   $1${NC}"
    echo -e "${BOLD}${BLUE}====================================================${NC}"
}

run_check() {
    local name="$1"
    local cmd="$2"

    echo -e "\n${BOLD}[RUNNING]${NC} ${name}..."
    if eval "$cmd"; then
        echo -e "${GREEN}✓ ${name} passed successfully.${NC}"
        PASSED_CHECKS+=("$name")
    else
        echo -e "${RED}✗ ${name} failed.${NC}"
        FAILED_CHECKS+=("$name")
    fi
}

run_optional_check() {
    local name="$1"
    local check_cmd="$2"
    local run_cmd="$3"

    echo -e "\n${BOLD}[RUNNING]${NC} ${name}..."
    if eval "$check_cmd" >/dev/null 2>&1; then
        if eval "$run_cmd"; then
            echo -e "${GREEN}✓ ${name} passed successfully.${NC}"
            PASSED_CHECKS+=("$name")
        else
            echo -e "${RED}✗ ${name} failed.${NC}"
            FAILED_CHECKS+=("$name")
        fi
    else
        echo -e "${YELLOW}⚠ ${name} skipped (required binary/CLI not found).${NC}"
        SKIPPED_CHECKS+=("$name")
    fi
}

log_header "STARTING AUDIT PREFLIGHT CHECKS"

# 1. TypeScript Compiler Check
run_check "TypeScript Type Check (tsc)" "npx tsc --noEmit"

# 2. ESLint Code Standard Verification
run_check "ESLint Code Standard" "npx eslint ."

# 3. Knip Unused Dependencies and Code Audit
run_check "Knip Dependency Audit" "npx knip"

# 4. Squawk SQL Migration Linter
run_optional_check \
    "Squawk SQL Linter" \
    "command -v squawk || npx --no-install squawk --version" \
    "npx squawk supabase/migrations/*.sql"

# 5. Supabase Database Schema Linter
run_optional_check \
    "Supabase DB Lint" \
    "command -v supabase" \
    "supabase db lint"

# 6. pgTAP Database Unit Tests
run_optional_check \
    "pgTAP Database Unit Tests" \
    "command -v supabase" \
    "supabase test db"

# 7. Vitest Application Test Suite
run_check "Vitest Unit Tests" "npx vitest run"

# Summary and Exit Status Reporting
echo -e "\n${BOLD}${BLUE}====================================================${NC}"
echo -e "${BOLD}${BLUE}                AUDIT SUMMARY                       ${NC}"
echo -e "${BOLD}${BLUE}====================================================${NC}"

if [ ${#PASSED_CHECKS[@]} -gt 0 ]; then
    echo -e "${GREEN}${BOLD}PASSED CHECKS (${#PASSED_CHECKS[@]}):${NC}"
    for item in "${PASSED_CHECKS[@]}"; do
        echo -e "  ${GREEN}✓${NC} $item"
    done
fi

if [ ${#SKIPPED_CHECKS[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}${BOLD}SKIPPED CHECKS (${#SKIPPED_CHECKS[@]}):${NC}"
    for item in "${SKIPPED_CHECKS[@]}"; do
        echo -e "  ${YELLOW}⚠${NC} $item"
    done
fi

if [ ${#FAILED_CHECKS[@]} -gt 0 ]; then
    echo -e "\n${RED}${BOLD}FAILED CHECKS (${#FAILED_CHECKS[@]}):${NC}"
    for item in "${FAILED_CHECKS[@]}"; do
        echo -e "  ${RED}✗${NC} $item"
    done
    echo -e "\n${RED}${BOLD}PREFLIGHT AUDIT FAILED:${NC} Please fix the errors above before proceeding."
    exit 1
else
    echo -e "\n${GREEN}${BOLD}PREFLIGHT AUDIT PASSED:${NC} All mandatory security and code quality checks succeeded."
    exit 0
fi
