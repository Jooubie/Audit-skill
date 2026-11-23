# **PostgreSQL Migration Linter Configuration**

Enterprise Database Migration Safety Standards and Squawk Configuration

# **Document Metadata**

* **Primary Maintainer:** Person  
* **Effective Date:** Date  
* **Target PostgreSQL Version:** 15.0+  
* **Associated Repository:** File

# **Executive Summary**

Squawk is an open-source linter for PostgreSQL migration scripts. It parses SQL migration files to detect operations that cause exclusive table locks, performance degradation, or zero-downtime deployment violations.

This document defines the standard configuration file (.squawk.toml) and continuous integration guidelines to enforce non-blocking database migrations across all deployment pipelines.

# **Standard Configuration File (`.squawk.toml`)**

Place the following configuration file in the root directory of the application repository or within the database migrations path.

```
# Squawk Configuration File (.squawk.toml)
# Schema Migration Linter Ruleset

# Targeted PostgreSQL Engine Version
target_version = "15.0"

# List of migration file paths or glob patterns to include
exclude = [
  "db/schema.sql",
  "db/structure.sql",
  "db/seeds.rb",
  "migrations/archive/*.sql"
]

# Rule Configuration Matrix
[rules]
# Lock Risk: Adding columns with non-null constraints without default values
ban-add-column-not-null-no-default = "error"

# Lock Risk: Adding NOT NULL constraint to existing column without validation
ban-add-not-null-constraint = "error"

# Lock Risk: Creating indexes non-concurrently on populated tables
require-concurrent-index = "error"

# Lock Risk: Removing tables without verifying usage
ban-drop-table = "warning"

# Lock Risk: Removing columns directly (requires multi-step deployment)
ban-drop-column = "warning"

# Lock Risk: Changing column types directly (causes full table rewrite)
ban-change-column-type = "error"

# Lock Risk: Renaming columns or tables (breaks active application instances)
ban-rename-column = "error"
ban-rename-table = "error"

# Lock Risk: Setting DEFAULT values on existing large tables without timeout control
ban-set-default = "warning"

# Lock Risk: Adding foreign key constraints without NOT VALID
require-foreign-key-not-valid = "error"

# Enforcement: Explicit lock timeout specification in migration transactions
require-lock-timeout = "error"

# Enforcement: Environment-specific safety checks
disallow-raw-sql-execution = "ignore"
```

# **Rule Enforcements Matrix**

| Rule Identifier | Severity | Risk Level | Mitigation Standard |
| :---- | :---- | :---- | :---- |
| `require-concurrent-index` | Error | High | Always use `CREATE INDEX CONCURRENTLY`. Ensure transaction block is disabled for index creation. |
| `ban-add-column-not-null-no-default` | Error | High | Add column as nullable, populate data asynchronously, then apply `NOT NULL` with a `CHECK` constraint marked `NOT VALID`. |
| `ban-change-column-type` | Error | Critical | Create a new column with the desired type, dual-write via application/triggers, backfill data, and swap columns. |
| `require-foreign-key-not-valid` | Error | High | Add foreign keys using `NOT VALID` to avoid table scans during lock retention, followed by `VALIDATE CONSTRAINT` in a separate transaction. |
| `ban-rename-column` | Error | Critical | Add new column, copy data, update application code to use new column, then schedule old column deprecation. |
| `require-lock-timeout` | Error | Medium | Prepend every migration script with `SET lock_timeout = '5s';` to prevent cascading query queue lockups. |
| `ban-drop-table` | Warning | Medium | Require senior DBA review before dropping tables to confirm zero dependency. |

# **CI/CD Pipeline Integration**

## **GitHub Actions Integration**

Add the following step into `.github/workflows/migration-check.yml` to ensure every pull request modifying database schemas passes Squawk verification.

```
name: Database Migration Linting

on:
  pull_request:
    paths:
      - 'db/migrations/**'
      - '.squawk.toml'

jobs:
  squawk-lint:
    name: Lint PostgreSQL Migrations
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Run Squawk Migration Linter
        uses: squawk-postgres/squawk-action@v2
        with:
          config: .squawk.toml
          migration_dir: db/migrations
```

# **Exception & Bypass Protocols**

In rare cases where an operational trade-off requires executing an unsafe operation (such as maintenance-window migrations), rules can be ignored inline or through pull request approvals.

## **Inline Rule Suppression**

Suppress specific rules for individual lines by inserting a comment directly above the offending SQL statement:

```
-- squawk-ignore require-concurrent-index
CREATE INDEX idx_users_created_at ON users (created_at);
```

## **Sign-off Matrix for Bypassing Warnings**

* **Error Bypasses:** Requires approval from Person and an assigned Database Administrator.  
* **Warning Bypasses:** Requires approval from the Tech Lead associated with the pull request.

