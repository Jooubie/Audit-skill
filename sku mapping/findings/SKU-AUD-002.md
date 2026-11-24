---
type: finding
id: SKU-AUD-002
title: "rpc_map_unmapped_line crashes with 23505 on normalized twins and omits size"
severity: High
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
  - data-integrity
  - sku-mapping
---

# [[SKU-AUD-002]]: `rpc_map_unmapped_line` crashes with `23505` on normalized twins and omits `size`

- **Finding ID**: SKU-AUD-002
- **Severity**: High
- **Confidence**: High
- **Category**: Database
- **Governing Canon**: [[02-kleppmann-schema-evolution]]
- **Location**: `supabase/schema.sql` (Lines 5403-5570 post-`20261125100000`)

---

## 1. Description & Evidence

`rpc_map_unmapped_line` checks conflicts using normalized keys (`lower(regexp_replace(...))`), but its `INSERT ... ON CONFLICT` statements target the raw-text unique constraints instead of the normalized unique indexes (`channel_codes_active_mapping_key` and `channel_aliases_mapping_key`):

```sql
-- supabase/schema.sql:5473-5477
INSERT INTO channel_codes (channel_id, variant_id, code, active)
VALUES (p_channel_id, p_variant_id, v_key, true)
ON CONFLICT (channel_id, code) DO UPDATE
  SET variant_id = EXCLUDED.variant_id, active = true
RETURNING id INTO v_mapping_id;

-- supabase/schema.sql:5512-5516
INSERT INTO channel_aliases (channel_id, variant_id, product_text)
VALUES (p_channel_id, p_variant_id, v_key)
ON CONFLICT (channel_id, product_text) DO UPDATE
  SET variant_id = EXCLUDED.variant_id
RETURNING id INTO v_mapping_id;
```

Additionally, both `UPDATE sales_lines` statements in `rpc_map_unmapped_line` (`lines 5479-5496` and `5518-5535`) update `variant_id`, `seemly_sku`, `seemly_item`, `style`, `category`, `product_group`, and `mapping_method = 'manual'`, **omitting `size = v.size`** (which `rpc_admin_batch_mapping_edit` in `20261125100000_mapping_rebuild_ops.sql` and `rpc_admin_edit_channel_mapping` at `schema.sql:2777` do set). It also lacks the post-`UPDATE` `unmapped: multi-item lokal order%` race check present in `rpc_admin_batch_mapping_edit`.

---

## 2. Actual or Credible Failure Scenario

1. A channel already has an active mapping `'KEY TEST'` -> `variant_A` (or `'Blue  Top'` -> `variant_A`). An operator maps an unmapped line carrying `'KEYTEST'` (or `'blue top'`) to the **same** `variant_A` via `/api/unmapped/map` or `rpc_automap_apply_item`. The conflict check passes (same variant), `ON CONFLICT (channel_id, code)` / `(channel_id, product_text)` does not match the different spelling, and `INSERT` collides with `channel_codes_active_mapping_key` / `channel_aliases_mapping_key`, raising SQLSTATE `23505` (confirmed in `src/lib/testing/showroom-mapping-integrity.test.ts:24`). The API returns HTTP 500 `"Could not map this line."`
2. Every `sales_lines` row resolved via `/api/unmapped/map` or `rpc_automap_apply_item` retains `size = NULL` (or raw portal size), causing size-grouped analytics/filters to miss those lines.

---

## 3. Technical & Business Impact
- **Technical Impact**: Unhandled `23505` constraint violation on valid idempotent mappings; denormalized `sales_lines.size` drift; missing concurrent re-import multi-item lokal order guard.
- **Business Impact**: Operators and Hermes auto-map fail with 500 errors when mapping lines whose spacing or casing differs from an existing mapping for the same SKU; size breakdowns undercount manually mapped sales.

---

## 4. Proposed Correction
1. In a new additive migration (with `-- REVERSE:` comment), update `rpc_map_unmapped_line` to:
   - Look up existing `channel_codes` by `(channel_id, mapping_code_key(code))` with `ORDER BY active DESC NULLS LAST, id LIMIT 1` (matching `rpc_admin_batch_mapping_edit`) and reuse/reactivate it via `UPDATE` when found, rather than relying on exact-string `ON CONFLICT (channel_id, code)`.
   - Look up existing `channel_aliases` by `(channel_id, mapping_alias_key(product_text)) LIMIT 1` and reuse its `id` when `variant_id` already matches.
   - Set `size = v.size` in both `UPDATE sales_lines` statements.
   - Add `AND sl.channel_code IS NOT NULL` and the post-`UPDATE` `unmapped: multi-item lokal order%` rollback check.
2. Update `src/lib/testing/showroom-mapping-integrity.test.ts:24` to assert idempotent reuse instead of `23505`.

---

## 5. Verification Criteria
- [ ] SQL test proving `rpc_map_unmapped_line` reuses normalized code/alias twins for the same variant without `23505`, still rejects cross-variant conflicts with `P0001`, and sets `sales_lines.size = v.size`.
- [ ] SQL test proving concurrent multi-item lokal order insertion during `rpc_map_unmapped_line` rolls back.
- [ ] `npm run ci:checks` and SQL test suite pass.
