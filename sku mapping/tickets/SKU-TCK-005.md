---
type: ticket
id: SKU-TCK-005
title: "Add functional sales_lines mapping indexes, unify COLLATE C key usage, and guard pending alias staging uniqueness"
finding: "[[SKU-AUD-005]]"
phase: "[[phase-2-plan]]"
status: draft
priority: P2
assigned_agent: "Claude Sonnet"
created: 2026-11-24
updated: 2026-11-24
tags:
  - audit
  - ticket
  - performance
  - database
  - indexing
---

# [[SKU-TCK-005]]: Add functional `sales_lines` mapping indexes, unify `COLLATE "C"` key usage, and guard pending alias staging uniqueness

- **Ticket ID**: SKU-TCK-005
- **Related Finding**: [[SKU-AUD-005]], [[SKU-AUD-007]]
- **Implementation Phase**: [[phase-2-plan]] (Phase C — Performance, Key Parity & Genz Guard)
- **Status**: Draft
- **Assigned Agent**: Claude Sonnet (`seemly-data`)

---

## 1. Problem Definition
1. `sales_lines` lacks functional B-Tree indexes on `(channel_id, mapping_code_key(channel_code))` and `(channel_id, mapping_alias_key(channel_product))`, forcing full per-channel scans inside `rpc_admin_batch_mapping_edit` (up to 500 iterations while holding 8-table `SHARE ROW EXCLUSIVE` locks), `rpc_mapping_edit_impact`, `rpc_staged_alias_evidence`, and `channel_aliases_refuse_held`.
2. Mapping/staging RPCs duplicate inline `lower(regexp_replace(...))` expressions without `COLLATE "C"`, bypassing existing functional indexes on `channel_codes` / `channel_aliases` and risking collation drift.
3. `channel_alias_staging` only enforces raw `(channel_id, product_text)` uniqueness, allowing duplicate `pending` rows when casing/whitespace varies.

---

## 2. Expected Outcome
- Partial B-Tree indexes `idx_sales_lines_channel_code_key` and `idx_sales_lines_channel_alias_key` exist on `sales_lines`.
- Mapping/staging RPCs and triggers (`rpc_admin_batch_mapping_edit`, `rpc_admin_edit_channel_mapping`, `rpc_map_unmapped_line`, `rpc_mapping_edit_impact`, `rpc_resolve_staged_alias`, `rpc_staged_alias_evidence`, `rpc_automap_candidates`, `rpc_import_batch_atomic`, `channel_aliases_refuse_held`) use `public.mapping_code_key(...)` and `public.mapping_alias_key(...)` consistently.
- `rpc_import_batch_atomic` (and `channel_alias_staging`, subject to Decision #2) prevents duplicate `pending` rows for the same normalized `mapping_alias_key(product_text)`.

---

## 3. Affected Files & Services
- `supabase/migrations/YYYYMMDDHHMMSS_mapping_indexes_and_key_parity.sql` (new additive migration with `SET LOCAL lock_timeout = '5s'` and `-- REVERSE:` comment; no `CONCURRENTLY` per `migrate-and-seed.mjs` single-transaction invariant. **IMPORTANT**: when updating `rpc_admin_batch_mapping_edit` and `rpc_mapping_edit_impact`, start from the current `20261125100000_mapping_rebuild_ops.sql` / `schema.sql` bodies and preserve `alias_move`, `alias_clear`, `code_clear`, `product_edit`, and `channel_aliases` row locking)
- `src/lib/testing/mapping-contracts.test.ts` / `src/lib/testing/showroom-mapping-integrity.test.ts` (add `EXPLAIN` index-usage assertion + staging normalized-dedup assertion)

---

## 4. Acceptance Criteria
- [ ] 1. `idx_sales_lines_channel_code_key` and `idx_sales_lines_channel_alias_key` created without exceeding `lock_timeout`.
- [ ] 2. `EXPLAIN (COSTS OFF)` with `enable_seqscan = off` confirms index usage for `sales_lines` lookups using `mapping_code_key` and `mapping_alias_key`.
- [ ] 3. No duplicate `pending` rows created in `channel_alias_staging` when `rpc_import_batch_atomic` stages `'Blue  Top'` after `'blue top'`.
- [ ] 4. All existing SQL parity and mapping contract tests pass; frozen ERP functions untouched.

---

## 5. Regression Test Specification
- **Test-first**: Write a failing SQL test asserting index scan plan on `sales_lines` by `mapping_code_key` and asserting `rpc_import_batch_atomic` deduplicates pending staging aliases by `mapping_alias_key`.
- Test path: `src/lib/testing/showroom-mapping-integrity.test.ts`
- Expected assertion: Index scan confirmed; 1 pending row in `channel_alias_staging`.

---

## 6. Risks & Rollback Requirements
- **Risk Assessment**: Medium — creating two indexes on `sales_lines` inside a transaction briefly takes a `ShareLock` (blocks writes to `sales_lines` during index build; mitigated by `SET LOCAL lock_timeout = '5s'` and deploying during low traffic / maintenance window).
- **Rollback Procedure**: Execute `-- REVERSE:` block to drop both indexes (and optional staging index) and restore prior RPC bodies.
