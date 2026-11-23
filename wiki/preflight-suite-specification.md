# **Audit Preflight Suite Specification**

A unified pre-commit and CI validation script ensuring type safety, linting quality, unused export pruning, database schema migration checks, pgTAP testing, and application unit tests.

# **Target Tooling Breakdown**

| Tool | Category | Check Description | Executable Command |
| :---- | :---- | :---- | :---- |
| **tsc** | Type System | Static type check without output emission | `npx tsc --noEmit` |
| **ESLint** | Code Linting | Static code analysis for JS/TS standards | `npx eslint .` |
| **Knip** | Dependency Audit | Unused files, dependencies, and exports check | `npx knip` |
| **Squawk** | Database Linting | Migration file analysis for Postgres anti-patterns | `npx squawk supabase/migrations/*.sql` |
| **Supabase DB Lint** | Schema Linting | Database structure and policy verification | `supabase db lint` |
| **pgTAP** | DB Unit Tests | PostgreSQL unit testing suite | `supabase test db` |
| **Vitest** | App Testing | Unit and integration testing | `npx vitest run` |

# **Production Preflight Script (`scripts/preflight.sh`)**

h  
\#\!/usr/bin/env bash

# **\==============================================================================**

# **Comprehensive Preflight Audit Script**

# **Validates code quality, types, dependencies, database migrations, and tests.**

# **\==============================================================================**

set \-o pipefail

# **Visual ANSI Color Formatting**

BOLD='\\033\[1m'  
GREEN='\\033\[0;32m'  
RED='\\033\[0;31m'  
YELLOW='\\033\[0;33m'  
BLUE='\\033\[0;34m'  
NC='\\033\[0m' \# No Color

# **Arrays tracking check execution statuses**

FAILED\_CHECKS=()  
PASSED\_CHECKS=()  
SKIPPED\_CHECKS=()

log\_header() {  
echo \-e "\\n\${BOLD}\${BLUE}====================================================\${NC}"  
echo \-e "\${BOLD}\${BLUE}   \$1\${NC}"  
echo \-e "\${BOLD}\${BLUE}====================================================\${NC}"  
}

run\_check() {  
local name="\$1"  
local cmd="\$2"

echo \-e "\\n\${BOLD}\[RUNNING\]\${NC} \${name}..."

if eval "\$cmd"; then  
echo \-e "\${GREEN}✓ \${name} passed successfully.\${NC}"  
PASSED\_CHECKS+=("\$name")  
else  
echo \-e "\${RED}✗ \${name} failed.\${NC}"  
FAILED\_CHECKS+=("\$name")  
fi  
}

run\_optional\_check() {  
local name="\$1"  
local check\_cmd="\$2"  
local run\_cmd="\$3"

echo \-e "\\n\${BOLD}\[RUNNING\]\${NC} \${name}..."

if eval "\$check\_cmd" \>/dev/null 2\>&1; then  
if eval "\$run\_cmd"; then  
echo \-e "\${GREEN}✓ \${name} passed successfully.\${NC}"  
PASSED\_CHECKS+=("\$name")  
else  
echo \-e "\${RED}✗ \${name} failed.\${NC}"  
FAILED\_CHECKS+=("\$name")  
fi  
else  
echo \-e "\${YELLOW}⚠ \${name} skipped (required binary/CLI not found).\${NC}"  
SKIPPED\_CHECKS+=("\$name")  
fi  
}

log\_header "STARTING AUDIT PREFLIGHT CHECKS"

# **1\. TypeScript Compiler Check**

run\_check "TypeScript Type Check (tsc)" "npx tsc \--noEmit"

# **2\. ESLint Code Standard Verification**

run\_check "ESLint Code Standard" "npx eslint ."

# **3\. Knip Unused Dependencies and Code Audit**

run\_check "Knip Dependency Audit" "npx knip"

# **4\. Squawk SQL Migration Linter**

run\_optional\_check   
"Squawk SQL Linter"   
"command \-v squawk \|\| npx \--no-install squawk \--version"   
"npx squawk supabase/migrations/\*.sql"

# **5\. Supabase Database Schema Linter**

run\_optional\_check   
"Supabase DB Lint"   
"command \-v supabase"   
"supabase db lint"

# **6\. pgTAP Database Unit Tests**

run\_optional\_check   
"pgTAP Database Unit Tests"   
"command \-v supabase"   
"supabase test db"

# **7\. Vitest Application Test Suite**

run\_check "Vitest Unit Tests" "npx vitest run"

# **Summary and Exit Status Reporting**

echo \-e "\\n\${BOLD}\${BLUE}====================================================\${NC}"  
echo \-e "\${BOLD}\${BLUE}                AUDIT SUMMARY                       \${NC}"  
echo \-e "\${BOLD}\${BLUE}====================================================\${NC}"

if \[ \${\#PASSED\_CHECKS\[@\]} \-gt 0 \]; then  
echo \-e "\${GREEN}\${BOLD}PASSED CHECKS (\${\#PASSED\_CHECKS\[@\]}):\${NC}"  
for item in "\${PASSED\_CHECKS\[@\]}"; do  
echo \-e "  \${GREEN}✓\${NC} \$item"  
done  
fi

if \[ \${\#SKIPPED\_CHECKS\[@\]} \-gt 0 \]; then  
echo \-e "\\n\${YELLOW}\${BOLD}SKIPPED CHECKS (\${\#SKIPPED\_CHECKS\[@\]}):\${NC}"  
for item in "\${SKIPPED\_CHECKS\[@\]}"; do  
echo \-e "  \${YELLOW}⚠\${NC} \$item"  
done  
fi

if \[ \${\#FAILED\_CHECKS\[@\]} \-gt 0 \]; then  
echo \-e "\\n\${RED}\${BOLD}FAILED CHECKS (\${\#FAILED\_CHECKS\[@\]}):\${NC}"  
for item in "\${FAILED\_CHECKS\[@\]}"; do  
echo \-e "  \${RED}✗\${NC} \$item"  
done  
echo \-e "\\n\${RED}\${BOLD}PREFLIGHT AUDIT FAILED:\${NC} Please fix the errors above before proceeding."  
exit 1  
else  
echo \-e "\\n\${GREEN}\${BOLD}PREFLIGHT AUDIT PASSED:\${NC} All mandatory security and code quality checks succeeded."  
exit 0  
fi

````

## Integration Guide

### 1. File Permissions
Grant execution permissions to the script file after saving:

```bash
chmod +x scripts/preflight.sh
````

## **2\. Package Configuration (`package.json`)**

Register the runner script within your project dependencies:

```
{
  "scripts": {
    "audit:preflight": "./scripts/preflight.sh"
  }
}
```

## **3\. Git Pre-Push Hook Setup (Husky)**

Ensure all audits run automatically before pushing changes to remote repositories:

```
npx husky add .husky/pre-push "npm run audit:preflight"
```

# **Maintenance Sign-Off**

* **Last Updated:** Date  
* **Lead Engineer:** Person  
* **Repository:** File

