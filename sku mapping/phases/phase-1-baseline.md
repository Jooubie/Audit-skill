---
type: phase-state
phase: 1
title: "Phase 1 — SKU Mapping Baseline Reconnaissance"
status: complete
updated: 2026-11-24
tags:
  - audit
  - phase-1
  - sku-mapping
---

# Phase 1 — SKU Mapping Baseline Reconnaissance (`~/Code/seemlyops`)

- **Scope**: Read-only audit of SKU mapping SQL schema, migrations, RLS policies, indexes, RPCs, backend modules (`src/lib/sku-mapping/**`), API routes (`src/app/api/sku-mapping/**`, `src/app/api/unmapped/**`, `src/app/api/automation/sku-map/**`), and UI queue helpers (`src/components/sku-mapping/**`).
- **Source Modifications**: **0** (read-only baseline).
- **Baseline Checks Observed**:
  - `npx tsc --noEmit`: pass (0 errors).
  - `npx eslint src/lib/sku-mapping src/app/api/sku-mapping src/app/api/unmapped`: pass (0 errors).
  - Targeted unit tests (`280` tests across `src/lib/sku-mapping/*.test.ts`, `auto-map/*.test.ts`, `product-attributes/*.test.ts`, `src/app/api/sku-mapping/**/*.test.ts`, `src/app/api/unmapped/**/*.test.ts`): `280` pass, `0` fail.
  - Note: Live Postgres SQL tests (`src/lib/testing/*.test.ts`) require `SQL_TEST_DATABASE_URL` (`bash scripts/sql-test-db.sh`) and were inspected statically via `supabase/schema.sql` and `supabase/acl.sql`.

---

## Findings Summary (9 Confirmed Findings)

| ID | Severity | Category | Summary | Canon |
|---|---|---|---|---|
| [[SKU-AUD-001]] | **High** | Security | Stale `is_ops_role()` RLS policies on `channel_mapping_holds`, `channel_alias_staging`, `automap_batches`, `automap_actions` exclude `finance` and expose rows to `operations`/`customer_support` | [[14-owasp-security-and-supabase-rls]] |
| [[SKU-AUD-002]] | **High** | Database | `rpc_map_unmapped_line` crashes with `23505` on normalized twins (`ON CONFLICT` mismatch) and omits `size = v.size` + post-update multi-item lokal race guard | [[02-kleppmann-schema-evolution]] |
| [[SKU-AUD-003]] | **High** | Database | `rpc_unresolved_sales` collapses all code-less unmapped items per channel into a single group and splits coded whitespace/case variants | [[01-ousterhout-module-depth]] |
| [[SKU-AUD-004]] | **High** | Security | `rpc_admin_batch_mapping_edit` & `rpc_admin_edit_channel_mapping` still grant `EXECUTE` to `authenticated` (bypassing impact/locking) and `rpc_admin_edit_channel_mapping` has unordered `LIMIT 1` | [[14-owasp-security-and-supabase-rls]] |
| [[SKU-AUD-005]] | **Medium** | Performance | Unindexed normalized `sales_lines` lookups run inside 500-edit batch loops under 8-table `SHARE ROW EXCLUSIVE` locks | [[13-postgres-query-performance]] |
| [[SKU-AUD-006]] | **Medium** | Code Quality | `genzCodeGuard` uses exact-string `.eq('channel_code', code)` in `latestText` and skips `new_sku.codes` in batches | [[08-pragmatic-principles]] |
| [[SKU-AUD-007]] | **Medium** | Database | Inline `lower(regexp_replace(...))` drifts from `COLLATE "C"` key functions and `channel_alias_staging` lacks normalized pending uniqueness | [[02-kleppmann-schema-evolution]] |
| [[SKU-AUD-008]] | **Medium** | Reliability | `rpc_automap_apply_item` / `rpc_automap_undo_action` omits `size` in snapshot and looks up `prev_mapping` by exact string | [[11-nygard-production-stability]] |
| [[SKU-AUD-009]] | **Low** | Architecture | Duplicated 1,000-row paging loops across 5 repos, shallow `holds.ts` pass-through, unbounded `reason` on staged aliases, minor `README.md` drift | [[01-ousterhout-module-depth]] |

---

## Next Action
Proceed to **Phase 2 — Architectural Synthesis & Planning**: synthesize `SKU-AUD-001` through `SKU-AUD-009` into bounded tickets (`tickets/SKU-TCK-*.md`) and a phased plan (`phases/phase-2-plan.md`), then present open design decisions to Operator Jou for sign-off before any code or migration edits.
