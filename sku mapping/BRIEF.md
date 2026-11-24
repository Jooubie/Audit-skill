---
type: brief
id: SKU-MAP-BRIEF
status: active
tags: [sku-mapping, sql, migrations, db, seemlyops, audit-skill]
---

# SKU Mapping — Expert Onboarding & AuditSkill Reference Brief

## 1. Your Role & Working Folder
- **Role**: SQL, PostgreSQL/Supabase database architecture, and schema migrations expert for SeemlyOps **SKU mapping** work.
- **Working Folder**: `/home/joubie/Audit-skill/sku mapping`
- **Audit Workspace**: `/home/joubie/Audit-skill`

---

## 2. How AuditSkill Works (Framework & Operating Contract)
Read [AGENTS.md](../AGENTS.md), [SKILL.md](../SKILL.md), and [wiki/index.md](../wiki/index.md) before proposing defects, schemas, or code changes.

### 4-Phase Execution Lifecycle
1. **Phase 1 — Read-Only Reconnaissance**:
   - Inspect the target codebase across the 6 audit dimensions (*Architecture, Security, Reliability, Performance, Maintainability, Governance*) with zero source modifications.
   - Every finding requires concrete `file:line` evidence, a reproducible failure scenario, and a governing canon citation (`[[wikilink]]`) using [finding-template.md](../templates/finding-template.md).
2. **Phase 2 — Architectural Synthesis & Planning**:
   - Group findings into bounded tickets ([ticket-template.md](../templates/ticket-template.md)) and phase plans ([phase-2-plan.md](../phases/phase-2-plan.md)).
   - Prefer repairing and deepening existing modules over speculative rewrites (`[[01-ousterhout-module-depth]]`, `[[06-fowler-refactoring-vocabulary]]`).
   - Present trade-offs and architectural/product decisions to Operator Jou numbered, with your recommendation first, and wait for explicit sign-off.
3. **Phase 3 — Bounded Test-First Implementation**:
   - Write a failing test proving the defect or contract before implementing (`[[05-khorikov-testing-policy]]`).
   - Keep diffs bounded to approved tickets; never mix refactoring with feature edits (`[[06-fowler-refactoring-vocabulary]]`).
4. **Phase 4 — Independent Verification (Single Pass)**:
   - Run deterministic checks (`./scripts/preflight.sh`, `npx tsc --noEmit`, ESLint boundaries `configs/eslint.config.mjs`, Knip `configs/knip.json`, Squawk `configs/squawk.toml`, live catalog audit `scripts/audit-supabase-catalog.sql`).
   - Exactly **one** fresh read-only review pass per completed phase diff (no circular review loops).

### Key Canons for SQL, DB, Migrations & Architecture (`wiki/`)
- **Precedence**: [[00-canon-index-and-conflicts]] (Statutory > Most Restrictive > Domain Specialization > Recency).
- **Schema Evolution**: [[02-kleppmann-schema-evolution]] — additive migrations only, backward/forward compatibility, dual-write/backfill phases where needed, never edit applied migrations, always include a `REVERSE` rollback comment.
- **Retail Dimensional Modeling**: [[03-kimball-star-schema-retail]] — line-item SKU grain, conformed dimensions, surrogate keys, clean fact/dimension separation.
- **Domain & Clean Boundaries**: [[04-ddd-bounded-contexts]] & [[09-clean-architecture-boundaries]] — strict bounded contexts, aggregate invariants, anti-corruption layers, unidirectional dependency rule, strict TypeScript + Zod boundary validation ([[07-typescript-conventions]]).
- **Postgres Performance**: [[13-postgres-query-performance]] — B-Tree & composite index column ordering, N+1 elimination, `EXPLAIN (ANALYZE, BUFFERS)`, lock-safe migrations (Squawk).
- **Security & RLS**: [[14-owasp-security-and-supabase-rls]] — RLS enforced on every tenant table, parameterized queries, `SECURITY DEFINER` `search_path` protection, strict multi-tenant isolation.
- **Resilience & Pipelines**: [[11-nygard-production-stability]] & [[12-data-engineering-lifecycle]] — idempotent transformations, fail-fast mechanics, timeouts/bulkheads.

---

## 3. Upcoming Work: SKU Mapping (SeemlyOps)
We are preparing a full **SKU mapping** engineering cycle on **SeemlyOps** (`~/Code/seemlyops`, Next.js 16 + self-hosted Supabase on `seemly-vps`):

1. **Codebase Review (SKU Mapping & Related DB Layer)**:
   - Audit the current SKU mapping tables, migrations, RLS policies, indexes, SQL functions/RPCs, and TypeScript/backend modules in `~/Code/seemlyops`.
   - Identify broken logic, data-integrity risks, performance bottlenecks, tenant-isolation gaps, and technical debt ("replace the shitty code we have").
2. **Module Building & Feature Remediation**:
   - Design clean, deep SKU-mapping modules (`[[01-ousterhout-module-depth]]`, `[[04-ddd-bounded-contexts]]`) and lock-safe additive Postgres migrations (`[[02-kleppmann-schema-evolution]]`, `[[13-postgres-query-performance]]`).
   - Fix all existing SKU-mapping features end-to-end and replace the brittle legacy implementation with well-tested, deterministic code (`[[05-khorikov-testing-policy]]`).
3. **Verification & Gated Deployment**:
   - Verify with deterministic preflight checks, migration linting, and read-only production verification (`seemly_proof` / read-only `vps.sh sql`), then deploy only after Jou's explicit approval to replace the old code in production.

### Non-Negotiable SeemlyOps Invariants
- **Frozen ERP Export**: Never touch `src/lib/erp/**`, `fixtures/**`, `scripts/verify-erp-*` (`node scripts/verify-erp-fixtures.mjs | md5sum` = `1eaf531368b23a3f56f3bf4ebe0ce67a`).
- **Ingestion Core**: Changes touching `src/lib/imports/**` or `src/lib/shopify/**` require tests proving existing behavior is unchanged.
- **Data Integrity**: Never invent a SKU, price, quantity, or total. Ledger and mapping fixes go through the app—never write to production by hand.
- **No Feature Loss**: Check `src/lib/access/role-tabs.ts` and `destinations.ts` before removing or reshaping any UI/workflow capability.
- **Human Gates**: Production DB pushes/writes, pushes to `main`, and deploys (`scripts/vps.sh deploy`) require Jou's explicit approval in the current session.
