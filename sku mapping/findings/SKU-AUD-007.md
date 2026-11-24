---
type: finding
id: SKU-AUD-007
title: "Inline normalization drifts from COLLATE C key functions and channel_alias_staging lacks normalized uniqueness"
severity: Medium
confidence: High
category: Database
status: open
canon: "[[02-kleppmann-schema-evolution]]"
created: 2026-11-24
updated: 2026-11-24
tags:
  - audit
  - finding
  - database
  - normalization
---

# [[SKU-AUD-007]]: Inline normalization drifts from `COLLATE "C"` key functions and `channel_alias_staging` lacks normalized uniqueness

- **Finding ID**: SKU-AUD-007
- **Severity**: Medium
- **Confidence**: High
- **Category**: Database
- **Governing Canon**: [[02-kleppmann-schema-evolution]]
- **Location**: `supabase/schema.sql` (Lines 1420-1435, 5224-5315, 7383-7553, 8444-8490, 13738 post-`20261125100000`)

---

## 1. Description & Evidence

Migration `20261102120000_showroom_mapping_integrity.sql` established `public.mapping_code_key(text)` and `public.mapping_alias_key(text)` with explicit `COLLATE "C"` (`supabase/schema.sql:1420-1435`) so SQL key normalization matches JS `normalizeCode`/`normalizeName` regardless of host/DB locale (`INTEGRITY.md:8-16`).

However:
1. Nearly every RPC (`rpc_resolve_staged_alias` lines 7432-7520, `rpc_staged_alias_evidence` lines 8450-8490, `rpc_map_unmapped_line` lines 5448-5533, `rpc_admin_batch_mapping_edit`, `rpc_admin_edit_channel_mapping` lines 2744-2784, `rpc_mapping_edit_impact` lines 5577-5722, `rpc_automap_candidates`, `rpc_import_batch_atomic` lines 5264-5288) still uses inline `lower(btrim(regexp_replace(..., '\s+', ' ', 'g')))` or `lower(regexp_replace(..., '\s', '', 'g'))` **without `COLLATE "C"`**.
2. `channel_alias_staging` only has an exact-string unique index `channel_alias_staging_channel_text_key ON (channel_id, product_text)` (`supabase/schema.sql:13738`), unlike `channel_aliases` which has `channel_aliases_mapping_key ON (channel_id, mapping_alias_key(product_text))`. In `rpc_import_batch_atomic:5283`, `ON CONFLICT (channel_id, product_text)` can insert duplicate staging rows when casing/whitespace differs from an existing pending row.

---

## 2. Actual or Credible Failure Scenario

1. Because inline expressions lack `COLLATE "C"` and do not call `mapping_code_key`/`mapping_alias_key`, Postgres cannot match them against the functional unique/B-Tree indexes on `channel_codes`, `channel_aliases`, or proposed `sales_lines` indexes, and non-ASCII whitespace/case behavior can diverge under non-C database collations.
2. An import containing `'Blue  Top'` after an earlier import staged `'blue top'` creates a second `pending` row in `channel_alias_staging` instead of updating the existing pending suggestion.

---

## 3. Technical & Business Impact
- **Technical Impact**: Duplicated normalization logic (`[[08-pragmatic-principles]]` DRY violation); missed index usage (`[[13-postgres-query-performance]]`); duplicate pending rows in `channel_alias_staging`.
- **Business Impact**: Duplicate suggestion cards in the "To confirm" queue and inconsistent key matching on non-ASCII/whitespace inputs.

---

## 4. Proposed Correction
1. Replace inline `lower(...)` normalization expressions in the mapping/staging RPCs with `public.mapping_code_key(...)` and `public.mapping_alias_key(...)`.
2. Add a normalized uniqueness check/index strategy for `channel_alias_staging` (or update `rpc_import_batch_atomic` / `rpc_replace_with_day_batches` to match pending rows by `mapping_alias_key(product_text)` before inserting).

---

## 5. Verification Criteria
- [ ] SQL test verifying `rpc_import_batch_atomic` does not create duplicate `pending` staging rows for whitespace/case variants of the same `product_text`.
- [ ] `npm run ci:full` passes with parity corpus tests intact.
