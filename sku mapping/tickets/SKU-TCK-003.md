---
type: ticket
id: SKU-TCK-003
title: "Fix rpc_map_unmapped_line normalized twin reuse, size propagation, and automap undo snapshots"
finding: "[[SKU-AUD-002]]"
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
  - data-integrity
  - sku-mapping
---

# [[SKU-TCK-003]]: Fix `rpc_map_unmapped_line` normalized twin reuse, `size` propagation, and automap undo snapshots

- **Ticket ID**: SKU-TCK-003
- **Related Finding**: [[SKU-AUD-002]], [[SKU-AUD-008]]
- **Implementation Phase**: [[phase-2-plan]] (Phase B — Core Resolution & Undo Integrity)
- **Status**: Draft
- **Assigned Agent**: Claude Sonnet (`seemly-data`)

---

## 1. Problem Definition
1. `rpc_map_unmapped_line` inserts with `ON CONFLICT (channel_id, code)` / `ON CONFLICT (channel_id, product_text)` instead of matching normalized `mapping_code_key` / `mapping_alias_key` twins, causing SQLSTATE `23505` crashes (HTTP 500) when mapping a differently-cased or spaced spelling for the same `variant_id`.
2. Both `UPDATE sales_lines` statements in `rpc_map_unmapped_line` omit `size = v.size` and lack the post-`UPDATE` `unmapped: multi-item lokal order%` race guard.
3. `rpc_automap_apply_item` / `rpc_automap_undo_action` omits `size` from `line_methods` snapshots and queries `v_prev` by exact string (`code = v_map_key`, `product_text = v_map_key`), which would cause undo to `DELETE` a pre-existing normalized mapping row once `rpc_map_unmapped_line` reuses normalized twins.

---

## 2. Expected Outcome
- `rpc_map_unmapped_line` deterministically looks up and reuses/reactivates existing normalized `channel_codes` (`ORDER BY active DESC NULLS LAST, id LIMIT 1`) or `channel_aliases` rows for the same `variant_id`, writes `size = v.size` on `sales_lines`, and checks `v_multi_item` post-`UPDATE`.
- `rpc_automap_apply_item` snapshots `size` and queries `v_prev` by `mapping_code_key` / `mapping_alias_key`; `rpc_automap_undo_action` restores `size` cleanly.

---

## 3. Affected Files & Services
- `supabase/migrations/YYYYMMDDHHMMSS_fix_map_unmapped_and_automap_undo.sql` (new additive migration with `-- REVERSE:` comment)
- `src/lib/testing/showroom-mapping-integrity.test.ts` (update line 24 assertion from `23505` crash to idempotent reuse)
- `src/lib/testing/mapping-contracts.test.ts` (assert `size` is set on `sales_lines` + alias twin reuse + post-update race guard)
- `src/lib/testing/automap.test.ts` (assert `size` snapshot/restore + `prev_mapping` capture for normalized twins)

---

## 4. Acceptance Criteria
- [ ] 1. `rpc_map_unmapped_line` succeeds idempotently when an active normalized twin (`code` or `alias`) exists for the same `variant_id`, and reactivates an inactive normalized code twin.
- [ ] 2. Cross-variant normalized conflicts still raise `P0001` (`conflict: ...`) before any writes.
- [ ] 3. `sales_lines.size` is populated with `v.size` after `rpc_map_unmapped_line`, and restored to its prior value on `rpc_automap_undo_action`.
- [ ] 4. `rpc_automap_apply_item` + `rpc_automap_undo_action` restores (never deletes) a pre-existing normalized twin in `channel_codes` / `channel_aliases`.
- [ ] 5. Migration includes `-- REVERSE:` block.

---

## 5. Regression Test Specification
- **Test-first**: Write failing SQL tests verifying `sales_lines.size` is currently `NULL` after `rpc_map_unmapped_line`, normalized alias twin throws `23505`, and automap undo misses `size` / normalized `prev_mapping`.
- Test paths: `src/lib/testing/mapping-contracts.test.ts`, `src/lib/testing/showroom-mapping-integrity.test.ts`, `src/lib/testing/automap.test.ts`
- Expected assertion: All tests pass with zero `23505` errors and accurate `size` + `prev_mapping` restoration.

---

## 6. Risks & Rollback Requirements
- **Risk Assessment**: Medium — `rpc_map_unmapped_line` is used by `/api/unmapped/map` and `rpc_automap_apply_item`; keeping the exact return JSON shape preserves API compatibility.
- **Rollback Procedure**: Run the `-- REVERSE:` block to restore the prior `rpc_map_unmapped_line`, `rpc_automap_apply_item`, and `rpc_automap_undo_action` bodies.
