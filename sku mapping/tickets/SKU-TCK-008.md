---
type: ticket
id: SKU-TCK-008
title: "Add erp_item_master table, authoritative ERP SKU gate, and 5001/5002 -> 5015/5016 alignment"
finding: "[[GOAL-ARCHITECTURE]]"
phase: "[[phase-2-plan]]"
status: draft
priority: P2
assigned_agent: "Claude Opus + Claude Sonnet"
created: 2026-11-24
updated: 2026-11-24
tags:
  - audit
  - ticket
  - database
  - erp-master
  - sku-mapping
---

# [[SKU-TCK-008]]: Add `erp_item_master` table, authoritative ERP SKU gate, and `5001/5002 -> 5015/5016` alignment

- **Ticket ID**: SKU-TCK-008
- **Related Finding / Design**: [[GOAL-ARCHITECTURE]] (Layer 1; Decision 60 & Decision 63; Gemini Finding B)
- **Implementation Phase**: [[phase-2-plan]] (Phase E — Authoritative ERP Gate & Wiring Provenance)
- **Status**: Draft
- **Assigned Agent**: Claude Opus + Claude Sonnet (`seemly-data` + `seemly-backend`)

---

## 1. Problem Definition
1. Postgres has **no `erp_item_master` table** (`supabase/schema.sql` only has `variants.in_erp_export DEFAULT true` at line `12857`, `erp_codes` at `11311`, and `erp_export_rules` at `11376`). Neither `scripts/seed-master-data.js` nor `new_sku` in `rpc_admin_batch_mapping_edit` verifies new or mapped SKUs against the accountant's ERP item list.
2. `variants.in_erp_export` is only checked in TypeScript (`src/lib/sku-mapping/mapping-repo.ts:73,82`, `csv-import-plan.ts:63`) and is **ignored** by Postgres mapping write RPCs (`rpc_admin_batch_mapping_edit`, `rpc_admin_edit_channel_mapping`, `rpc_map_unmapped_line`, `rpc_resolve_staged_alias`) and by `rpc_erp_export_source` (`supabase/schema.sql:5101-5170`).
3. Per `conflict-review.md` and Decision 63, Shopify Essentials `5001/5002` vs Collective `5015/5016` remains unresolved until the ERP item list is authoritative in the DB.

---

## 2. Expected Outcome
- `public.erp_item_master` exists in Postgres (`item_code` primary key/normalized key, `item_name`, `product_group`, `active`, `raw_row`, `synced_at`, `synced_by`) with RLS (`SELECT` for `is_mapping_operator_role()` + `is_erp_operator`, writes restricted to `admin`/`service_role`).
- An authenticated import/sync endpoint + CLI/seed script populates `erp_item_master` from the accountant's ERP Item List workbook/CSV and reconciles `variants.in_erp_export` (reporting any active `variants.sku` missing from `erp_item_master`).
- Mapping write RPCs (`rpc_admin_batch_mapping_edit`, `rpc_admin_edit_channel_mapping`, `rpc_map_unmapped_line`, `rpc_resolve_staged_alias`) and `new_sku` enforce `v.in_erp_export = true` (and `erp_item_master` presence when `erp_item_master` is populated, subject to Decision #5).
- A pre-export diagnostic view/RPC flags any `sales_lines` in a candidate export range whose `seemly_sku` is missing from `erp_item_master`, **without touching `rpc_erp_export_source` or `src/lib/erp/**`**.
- **Decision 63 execution (separate owner-approved data step)**: Once `erp_item_master` confirms `5015/5016` is the canonical ERP SKU, wire/move Shopify Essentials `5001/5002` onto `5015/5016` through the audited mapping API (respecting historical protection rules).

---

## 3. Affected Files & Services
- `supabase/migrations/YYYYMMDDHHMMSS_erp_item_master_gate.sql` (new additive migration with `SET LOCAL lock_timeout = '5s'` and `-- REVERSE:` block)
- `src/lib/sku-mapping/erp-master.ts` & `src/lib/sku-mapping/erp-master-repo.ts` (sync parser, diff report, pre-export SKU check)
- `src/app/api/sku-mapping/erp-master/route.ts` (sync + drift status endpoint)
- `scripts/seed-erp-item-master.mjs` (optional CLI loader using `keys run`)
- `Seemly-Wiki/wiki/database/sku-and-catalogue-tables.md` (fix stale `in_erp_export` documentation noted by Gemini verifier)
- `src/lib/testing/erp-master-gate.test.ts`

---

## 4. Acceptance Criteria
- [ ] 1. `public.erp_item_master` created with RLS policies and `-- REVERSE:` block; passes `verify-migration-reverse.mjs`.
- [ ] 2. When `erp_item_master` is populated, `new_sku` and mapping writes reject SKUs absent from `erp_item_master` (or `variants.in_erp_export = false`), with clear error messages surfacing in the UI.
- [ ] 3. Pre-export check detects unexported `sales_lines.seemly_sku` absent from `erp_item_master` before generating an ERP zip.
- [ ] 4. **Frozen ERP invariant**: `src/lib/erp/**`, `fixtures/**`, `scripts/verify-erp-*`, and `rpc_erp_export_source` (`supabase/schema.sql:5101-5170`) remain 100% untouched (`node scripts/verify-erp-fixtures.mjs | md5sum` = `1eaf531368b23a3f56f3bf4ebe0ce67a`).
- [ ] 5. Shopify `5001/5002 -> 5015/5016` data move is executed only after Jou's explicit sign-off on Decision #5 and `erp_item_master` verification.

---

## 5. Regression Test Specification
- **Test-first**: Write failing SQL/unit tests proving:
  1. `rpc_map_unmapped_line` and `rpc_admin_batch_mapping_edit` currently accept a variant with `in_erp_export = false` or absent from `erp_item_master`.
  2. Pre-export diagnostic misses an unverified SKU.
- Test path: `src/lib/testing/erp-master-gate.test.ts`
- Expected assertion: Writes to non-ERP-master SKUs are rejected; empty `erp_item_master` preserves backward-compatible fallback or explicit strict mode per Decision #5; `verify-erp` passes untouched.

---

## 6. Risks & Rollback Requirements
- **Risk Assessment**: Medium — if `erp_item_master` is enabled in strict mode before the full accountant item list is loaded, legitimate `new_sku` creation would be blocked. Mitigated by an explicit sync step + grace flag (`erp_item_master` count > 0 or Decision #5 mode).
- **Rollback Procedure**: Run the `-- REVERSE:` block to drop `public.erp_item_master` and restore prior RPC bodies; revert TS commit.
