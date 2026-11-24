---
type: finding
id: SKU-AUD-005
title: "Unindexed normalized sales_lines lookups execute inside 500-item batch loops under 8-table exclusive locks"
severity: Medium
confidence: High
category: Performance
status: open
canon: "[[13-postgres-query-performance]]"
created: 2026-11-24
updated: 2026-11-24
tags:
  - audit
  - finding
  - performance
  - database
  - indexing
---

# [[SKU-AUD-005]]: Unindexed normalized `sales_lines` lookups execute inside 500-item batch loops under 8-table exclusive locks

- **Finding ID**: SKU-AUD-005
- **Severity**: Medium
- **Confidence**: High
- **Category**: Performance
- **Governing Canon**: [[13-postgres-query-performance]]
- **Location**: `supabase/schema.sql` (Lines 698-704, 2826-2873, 5577-5722, 14165-14305 post-`20261125100000`), `supabase/migrations/20261125100000_mapping_rebuild_ops.sql` (Lines 538-805)

---

## 1. Description & Evidence

Every mapping write and preview path filters `sales_lines` by `channel_id` and normalized code/product text:
- `rpc_admin_batch_mapping_edit` (`supabase/migrations/20261125100000_mapping_rebuild_ops.sql:538-805`): executes `UPDATE sales_lines` (without `variant_id IS NULL` in Pass 3 and with `variant_id = v_variant_id` in Pass 4) inside a `FOR` loop of up to **500 edits**, filtering by `lower(regexp_replace(sl.channel_code, '\s', '', 'g'))` or `lower(btrim(regexp_replace(sl.channel_product, '\s+', ' ', 'g')))` (while `alias_move`/`alias_clear` already call `mapping_alias_key`).
- `rpc_admin_mapping_edit_with_impact` (`supabase/schema.sql:2848-2857`): holds `pg_advisory_xact_lock` on every channel AND `LOCK TABLE products, variants, channel_codes, channel_aliases, import_batches, sales_lines, confirmed_ranges, erp_exports, erp_export_files IN SHARE ROW EXCLUSIVE MODE` for the entire duration of `rpc_mapping_edit_impact` + `rpc_admin_batch_mapping_edit`.
- `channel_aliases_refuse_held()` trigger (`supabase/schema.sql:698-704`): runs an `EXISTS (SELECT 1 FROM sales_lines ...)` scan on every `channel_aliases` insert/update.

Inspection of all `sales_lines` indexes (`supabase/schema.sql:14165-14305`) confirms there are **no B-Tree functional indexes** on `(channel_id, mapping_code_key(channel_code))` or `(channel_id, mapping_alias_key(channel_product))` (only `idx_sales_unmapped (channel_id) WHERE variant_id IS NULL` and `gin_trgm_ops` indexes on raw un-normalized columns).

---

## 2. Actual or Credible Failure Scenario

When an operator applies a 200–500 row CSV import via `/api/sku-mapping/batch`, Postgres acquires `SHARE ROW EXCLUSIVE` locks on 8 core tables (blocking concurrent Shopify order syncs, showroom file imports, and product edits) and then performs up to 500 sequential scans over a channel's entire `sales_lines` history—risking hitting the 8-second session `statement_timeout` or causing lock-queue stalls across background sync jobs (`[[11-nygard-production-stability]]`).

---

## 3. Technical & Business Impact
- **Technical Impact**: $O(N_{\text{edits}} \times N_{\text{channel\_lines}})$ table/index scan amplification while holding global `SHARE ROW EXCLUSIVE` locks.
- **Business Impact**: Large CSV mapping imports risk timing out mid-batch or temporarily stalling concurrent Shopify/showroom sync workers.

---

## 4. Proposed Correction
1. Add functional B-Tree partial indexes in a new additive migration (note: `migrate-and-seed.mjs` runs each file inside a transaction, so `CREATE INDEX CONCURRENTLY` is disallowed per `supabase/migrations/README.md:76`; use `SET LOCAL lock_timeout = '5s'`):
   - `CREATE INDEX idx_sales_lines_channel_code_key ON public.sales_lines (channel_id, public.mapping_code_key(channel_code)) WHERE channel_code IS NOT NULL;`
   - `CREATE INDEX idx_sales_lines_channel_alias_key ON public.sales_lines (channel_id, public.mapping_alias_key(channel_product)) WHERE channel_product IS NOT NULL;`
2. Rewrite the `sales_lines` predicates in `rpc_admin_batch_mapping_edit`, `rpc_mapping_edit_impact`, `rpc_map_unmapped_line`, `rpc_resolve_staged_alias`, `rpc_staged_alias_evidence`, `rpc_mapping_import_lines`, and `channel_aliases_refuse_held` to use `public.mapping_code_key(...)` / `public.mapping_alias_key(...)` so the planner uses the indexes (and optionally join/batch updates in `rpc_admin_batch_mapping_edit` instead of 500 separate round-trip updates).

---

## 5. Verification Criteria
- [ ] `EXPLAIN (ANALYZE, BUFFERS)` in SQL tests (`SET LOCAL enable_seqscan = off`) confirming Index Scan / Bitmap Index Scan on `idx_sales_lines_channel_code_key` and `idx_sales_lines_channel_alias_key`.
- [ ] `npx squawk` / `verify-migration-reverse.mjs` / `npm run ci:full` pass.
