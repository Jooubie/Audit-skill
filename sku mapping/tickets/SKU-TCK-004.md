---
type: ticket
id: SKU-TCK-004
title: "Partition rpc_unresolved_sales by normalized code or alias key"
finding: "[[SKU-AUD-003]]"
phase: "[[phase-2-plan]]"
status: draft
priority: P1
assigned_agent: "Claude Sonnet"
created: 2026-11-24
updated: 2026-11-24
tags:
  - audit
  - ticket
  - database
  - queue
  - sku-mapping
---

# [[SKU-TCK-004]]: Partition `rpc_unresolved_sales` by normalized code or alias key

- **Ticket ID**: SKU-TCK-004
- **Related Finding**: [[SKU-AUD-003]]
- **Implementation Phase**: [[phase-2-plan]] (Phase B — Core Resolution & Undo Integrity)
- **Status**: Draft
- **Assigned Agent**: Claude Sonnet (`seemly-data`)

---

## 1. Problem Definition
`rpc_unresolved_sales` groups unmapped lines solely by `(l.channel_id, c.name, l.channel_code)` and picks `(array_agg(l.channel_product ...))[1]`. All code-less unmapped products in a channel (`channel_code IS NULL` or blank) collapse into a single group, hiding distinct unmapped items in the "To confirm" queue, while coded lines differing only in case/whitespace split into separate cards.

---

## 2. Expected Outcome
- `rpc_unresolved_sales` classifies each line by `key_kind` (`'code'` when `btrim(COALESCE(sl.channel_code, '')) <> ''`, else `'alias'`) and `key_norm` (`mapping_code_key(channel_code)` vs `mapping_alias_key(channel_product)`), matching `rpc_automap_candidates` and `export-unmapped.ts`.
- Rows with neither code nor product text (`key_norm = ''`) are handled explicitly without collapsing distinct named products together.
- Existing JSON response keys (`range`, `totals`, `groups` with `channel_id`, `channel_name`, `code`, `product`, `lines`, `units_net`, `net`, `first_day`, `last_day`, `periods`) remain unchanged for `queue.ts` and `use-confirm-queue.ts`.

---

## 3. Affected Files & Services
- `supabase/migrations/YYYYMMDDHHMMSS_unresolved_sales_group_by_key.sql` (new additive migration with `-- REVERSE:` comment)
- `src/lib/testing/unresolved-sales.test.ts` (or new SQL test covering code-less grouping & normalized code merging)

---

## 4. Acceptance Criteria
- [ ] 1. Two code-less unmapped products in the same channel (`Sash`, `lokal`, etc.) return two distinct entries in `groups` with their own `product`, `lines`, `units_net`, and `net`.
- [ ] 2. Two coded lines `'SEE 1'` and `'see1'` in the same channel merge into one group (preserving a representative `code` string).
- [ ] 3. `totals.codes` reflects the total distinct unresolved `(channel_id, key_kind, key_norm)` keys (subject to Operator Decision #3).
- [ ] 4. Unsold listing rows (`qty = 0 AND net = 0`) remain excluded, and money visibility (`v_money`) remains gated by `is_money_reader_role()`.
- [ ] 5. Migration includes `-- REVERSE:` block.

---

## 5. Regression Test Specification
- **Test-first**: Write a failing SQL test inserting two distinct code-less unmapped `sales_lines` (`'Product A'`, `'Product B'`) and two case/space-variant coded lines (`'SEE 1'`, `'see1'`) in the same channel and asserting `groups.length === 3`.
- Test path: `src/lib/testing/mapping-contracts.test.ts` (or dedicated `src/lib/testing/unresolved-sales-sql.test.ts`)
- Expected assertion: Separate groups per code-less product; merged group for normalized code variants; accurate totals.

---

## 6. Risks & Rollback Requirements
- **Risk Assessment**: Low-Medium — verify `queue.ts:cardCoversGroup` (`code ?? ''`, `product ?? ''`) and `use-confirm-queue.ts` work cleanly with distinct alias groups (they already expect one group per product text!).
- **Rollback Procedure**: Execute `-- REVERSE:` block to restore the prior `rpc_unresolved_sales` function definition.
