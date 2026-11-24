---
type: finding
id: SKU-AUD-003
title: "rpc_unresolved_sales collapses all code-less unmapped items per channel into one group"
severity: High
confidence: High
category: Database
status: open
canon: "[[01-ousterhout-module-depth]]"
created: 2026-11-24
updated: 2026-11-24
tags:
  - audit
  - finding
  - database
  - sku-mapping
  - queue
---

# [[SKU-AUD-003]]: `rpc_unresolved_sales` collapses all code-less unmapped items per channel into one group

- **Finding ID**: SKU-AUD-003
- **Severity**: High
- **Confidence**: High
- **Category**: Database
- **Governing Canon**: [[01-ousterhout-module-depth]]
- **Location**: `supabase/schema.sql` (Lines 8815-8882 post-`20261125100000`), `src/components/sku-mapping/queue.ts` (Lines 46-52, 87-103)

---

## 1. Description & Evidence

`rpc_unresolved_sales` aggregates unresolved ledger lines using `GROUP BY l.channel_id, c.name, l.channel_code`:

```sql
-- supabase/schema.sql:8853-8861
  groups AS (
    SELECT l.channel_id, c.name AS channel_name, l.channel_code AS code,
           (array_agg(l.channel_product ORDER BY l.sale_date DESC NULLS LAST) FILTER (WHERE l.channel_product IS NOT NULL))[1] AS product,
           count(*) AS lines, COALESCE(sum(l.qty), 0) AS units_net, COALESCE(sum(l.net), 0) AS net,
           min(l.sale_date) AS first_day, max(l.sale_date) AS last_day,
           array_agg(DISTINCT l.period ORDER BY l.period) AS periods
    FROM lines l JOIN public.channels c ON c.id = l.channel_id
    GROUP BY l.channel_id, c.name, l.channel_code
  ),
```

By contrast, `rpc_automap_candidates` (`supabase/schema.sql`) and `src/lib/sku-mapping/export-unmapped.ts:25-43` partition unmapped items by `(channel_id, key_kind, key_norm)`, grouping code-less lines by `mapping_alias_key(channel_product)` and coded lines by `mapping_code_key(channel_code)`. In `src/components/sku-mapping/queue.ts:46-51`, `cardCoversGroup` explicitly comments: *"Code-less (alias) cards all share code '', so the text must match too, or one confirmation would hide every code-less line of the channel (04/B3)."*

---

## 2. Actual or Credible Failure Scenario

1. A showroom with code-less lines (`channel_code IS NULL` or blank, such as Sash, Genz details reports, or uncoded `mr.local`/`lokal` rows) has 20 distinct unmapped products. `rpc_unresolved_sales` collapses all 20 products into **1 group** (`code = NULL`) showing only the single latest `channel_product` string while summing `lines`, `units_net`, and `net` across all 20 products. An operator tapping "Pick a SKU" in the "To confirm" queue sees aggregated metrics from 20 products attributed to 1 product name.
2. Coded lines with whitespace/case differences (`'SEE 1'` vs `'SEE1'`) produce duplicate cards in the queue even though `rpc_map_unmapped_line` normalizes them as one key.
3. `totals.codes` (`count(DISTINCT (channel_id, channel_code))`, line 8867) undercounts distinct unmapped code-less items to `1` per channel.

---

## 3. Technical & Business Impact
- **Technical Impact**: Grouping mismatch between `rpc_unresolved_sales` and `rpc_automap_candidates` / `export-unmapped.ts` / `queue.ts`.
- **Business Impact**: Operators cannot see or individually map distinct unmapped code-less products in the UI queue, and queue totals/metrics misrepresent unmapped volume per product.

---

## 4. Proposed Correction
Update `rpc_unresolved_sales` in a new additive migration (with `-- REVERSE:` comment) to group by `(channel_id, key_kind, key_norm)` using `mapping_code_key(channel_code)` when `btrim(COALESCE(channel_code, '')) <> ''`, else `mapping_alias_key(channel_product)`, matching `rpc_automap_candidates` and `export-unmapped.ts` while preserving the existing JSON response shape (`code`, `product`, `lines`, `units_net`, `net`, `first_day`, `last_day`, `periods`) and `totals.codes` distinct key count.

---

## 5. Verification Criteria
- [ ] SQL test proving two code-less unmapped products in the same channel return two separate groups in `rpc_unresolved_sales`, and case/whitespace variants of the same code/text merge into one group.
- [ ] Existing `src/lib/sku-mapping/unresolved-sales.test.ts` and `src/components/sku-mapping/queue.test.ts` pass.
