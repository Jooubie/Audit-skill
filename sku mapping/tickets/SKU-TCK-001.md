---
type: ticket
id: SKU-TCK-001
title: "Align RLS policies on holds, alias staging, and automap tables to is_mapping_operator_role()"
finding: "[[SKU-AUD-001]]"
phase: "[[phase-2-plan]]"
status: draft
priority: P1
assigned_agent: "Claude Sonnet"
created: 2026-11-24
updated: 2026-11-24
tags:
  - audit
  - ticket
  - security
  - rls
  - sku-mapping
---

# [[SKU-TCK-001]]: Align RLS policies on holds, alias staging, and automap tables to `is_mapping_operator_role()`

- **Ticket ID**: SKU-TCK-001
- **Related Finding**: [[SKU-AUD-001]]
- **Implementation Phase**: [[phase-2-plan]] (Phase A — RLS Alignment & Write Security)
- **Status**: Draft
- **Assigned Agent**: Claude Sonnet (`seemly-data` + `seemly-backend`)

---

## 1. Problem Definition
`channel_mapping_holds`, `channel_alias_staging`, `automap_batches`, and `automap_actions` enforce `SELECT` RLS policies using `is_ops_role()` (`admin`, `manager`, `operations`, `customer_support`), whereas `skuMapping.edit` belongs to `ADMIN_FINANCE` (`is_mapping_operator_role()`: `admin`, `manager`, `finance`). Consequently, `finance` silently receives 0 rows from `channel_mapping_holds` during `import-preview` and `export` (`userDb()`), while `operations` and `customer_support` retain read access, and `GET /api/sku-mapping/staged-aliases` relies on `adminDb` to bypass RLS.

---

## 2. Expected Outcome
- `channel_mapping_holds`, `channel_alias_staging`, `automap_batches`, and `automap_actions` restrict `SELECT` to `(SELECT public.is_mapping_operator_role())` (matching `channel_codes` and `channel_aliases`).
- `GET /api/sku-mapping/staged-aliases` uses `userDb` instead of `adminDb`.
- `finance` sees active mapping holds accurately in CSV `import-preview` and `export`.

---

## 3. Affected Files & Services
- `supabase/migrations/YYYYMMDDHHMMSS_mapping_tables_rls_finance.sql` (new additive migration with `-- REVERSE:` comment)
- `src/app/api/sku-mapping/staged-aliases/route.ts` (switch `GET` from `adminDb` to `userDb`)
- `src/lib/sku-mapping/mapping-answers.ts` (`stagedQueueAnswer` parameter rename `adminDb` -> `userDb` if appropriate)
- `src/app/api/sku-mapping/staged-aliases/route.test.ts`
- `src/lib/testing/showroom-mapping-integrity.test.ts` (update/add `finance` and `operations` hold RLS assertions)

---

## 4. Acceptance Criteria
- [ ] 1. New additive migration drops `*_select_ops` and creates `*_select_mapping_operator` policies using `(SELECT public.is_mapping_operator_role())` on all 4 tables, with a valid `-- REVERSE:` comment block.
- [ ] 2. `GET /api/sku-mapping/staged-aliases` reads via `userDb` (no `adminDb` import/usage for `GET`).
- [ ] 3. `finance`, `admin`, and `manager` can `SELECT` from all 4 tables; `operations`, `customer_support`, `warehouse`, `showroom`, and `anon` receive 0 rows.
- [ ] 4. No unrelated files or frozen ERP/ingestion modules touched (`[[01-ousterhout-module-depth]]`).

---

## 5. Regression Test Specification
- **Test-first**: Write failing SQL/integration tests proving `finance` receives 0 rows from `channel_mapping_holds` and `operations` receives >0 rows before the migration, then apply the migration.
- Test path: `src/lib/testing/showroom-mapping-integrity.test.ts` and `src/app/api/sku-mapping/staged-aliases/route.test.ts`
- Expected assertion: `finance` sees holds and staged aliases via `userDb`; `operations` and `customer_support` see 0 rows.

---

## 6. Risks & Rollback Requirements
- **Risk Assessment**: Low — aligns DB RLS directly with `src/lib/access/policy.ts` and `role-matrix.test.ts`.
- **Rollback Procedure**: Run the `-- REVERSE:` block in the migration to restore the `*_select_ops` policies and revert the `staged-aliases/route.ts` commit.
