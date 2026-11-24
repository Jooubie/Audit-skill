---
type: finding
id: SKU-AUD-008
title: "rpc_automap_apply_item / undo snapshot omits size and reads prev_mapping by exact string"
severity: Medium
confidence: High
category: Reliability
status: open
canon: "[[11-nygard-production-stability]]"
created: 2026-11-24
updated: 2026-11-24
tags:
  - audit
  - finding
  - reliability
  - automap
---

# [[SKU-AUD-008]]: `rpc_automap_apply_item` / undo snapshot omits `size` and reads `prev_mapping` by exact string

- **Finding ID**: SKU-AUD-008
- **Severity**: Medium
- **Confidence**: High
- **Category**: Reliability
- **Governing Canon**: [[11-nygard-production-stability]]
- **Location**: `supabase/schema.sql` (Lines 3524-3554, 3720-3755 post-`20261125100000`)

---

## 1. Description & Evidence

In `rpc_automap_apply_item` (`supabase/schema.sql:3524-3554`):
1. `v_methods` snapshots `mapping_method`, `seemly_sku`, `seemly_item`, `style`, `category`, `product_group` before calling `rpc_map_unmapped_line`, **omitting `size`**, and `rpc_automap_undo_action` (`lines 3720-3730`) does not restore `size`.
2. `v_prev` is queried with exact equality:
```sql
-- supabase/schema.sql:3543-3549
IF v_map_kind = 'code' THEN
  SELECT jsonb_build_object('id', id, 'variant_id', variant_id, 'active', active) INTO v_prev
    FROM channel_codes WHERE channel_id = v_channel AND code = v_map_key;
ELSE
  SELECT jsonb_build_object('id', id, 'variant_id', variant_id) INTO v_prev
    FROM channel_aliases WHERE channel_id = v_channel AND product_text = v_map_key;
END IF;
```

---

## 2. Actual or Credible Failure Scenario

1. Once `rpc_map_unmapped_line` is fixed to set `size = v.size` (`SKU-AUD-002`) and reuse normalized twins (`mapping_code_key` / `mapping_alias_key`), undoing an auto-map action would leave `sales_lines.size` populated on an unmapped line.
2. Worse, if `channel_codes` or `channel_aliases` already had a normalized twin (e.g., an inactive `'ABC 1'` row when `v_map_key` is `'ABC1'`), the exact-string `v_prev` lookup returns `NULL`, so `rpc_automap_undo_action` (`lines 3396-3398`) **deletes** the pre-existing `channel_codes`/`channel_aliases` row instead of restoring its prior `variant_id` and `active` state.

---

## 3. Technical & Business Impact
- **Technical Impact**: Incomplete undo snapshot (`size` omitted); destructive undo (`DELETE` instead of restore) when `v_prev` misses a normalized twin.
- **Business Impact**: Undoing an automated mapping batch could permanently delete a pre-existing inactive or differently-cased mapping row.

---

## 4. Proposed Correction
In a new additive migration (with `-- REVERSE:` comment):
1. Include `'size', sl.size` in `rpc_automap_apply_item`'s `v_methods` snapshot and restore `size = v_row.line_methods -> sl.id::text ->> 'size'` in `rpc_automap_undo_action`.
2. Query `v_prev` in `rpc_automap_apply_item` using `mapping_code_key(code) = mapping_code_key(v_map_key)` (`ORDER BY active DESC NULLS LAST, id LIMIT 1`) and `mapping_alias_key(product_text) = mapping_alias_key(v_map_key)` (`LIMIT 1`), matching `rpc_map_unmapped_line`.

---

## 5. Verification Criteria
- [ ] SQL test proving `rpc_automap_apply_item` + `rpc_automap_undo_action` restores `sales_lines.size` and restores (rather than deletes) an existing inactive normalized twin in `channel_codes`.
