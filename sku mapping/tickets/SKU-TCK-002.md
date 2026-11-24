---
type: ticket
id: SKU-TCK-002
title: "Harden single-edit RPC lookup and revoke direct authenticated bypass on inner mapping write RPCs"
finding: "[[SKU-AUD-004]]"
phase: "[[phase-2-plan]]"
status: draft
priority: P1
assigned_agent: "Claude Sonnet"
created: 2026-11-24
updated: 2026-11-24
tags:
  - audit
  - ticket
  - security
  - database
  - sku-mapping
---

# [[SKU-TCK-002]]: Harden single-edit RPC lookup and revoke direct `authenticated` bypass on inner mapping write RPCs

- **Ticket ID**: SKU-TCK-002
- **Related Finding**: [[SKU-AUD-004]]
- **Implementation Phase**: [[phase-2-plan]] (Phase A — RLS Alignment & Write Security)
- **Status**: Draft
- **Assigned Agent**: Claude Sonnet (`seemly-data`)

---

## 1. Problem Definition
1. `rpc_admin_edit_channel_mapping` (called when `p_single = true` in `rpc_admin_mapping_edit_with_impact`) selects an existing `channel_codes` row using `LIMIT 1` with no `ORDER BY` (missing the `ORDER BY cc.active DESC NULLS LAST, cc.id` fix applied to `rpc_admin_batch_mapping_edit`), omits the post-`UPDATE` `unmapped: multi-item lokal order%` race check, and is `SECURITY INVOKER` with `SET search_path TO 'public'` (no `pg_temp`).
2. Both `rpc_admin_edit_channel_mapping` and `rpc_admin_batch_mapping_edit` still grant `EXECUTE` to `authenticated`, allowing signed-in operators to bypass `rpc_admin_mapping_edit_with_impact`'s `p_expected_impact` check and 8-table `SHARE ROW EXCLUSIVE` lock ordering.

---

## 2. Expected Outcome
- `rpc_admin_edit_channel_mapping` orders deterministically (`ORDER BY cc.active DESC NULLS LAST, cc.id LIMIT 1`), performs the post-`UPDATE` multi-item lokal check, and pins `pg_temp` in `search_path`.
- Direct `EXECUTE` from `authenticated` is revoked on `rpc_admin_edit_channel_mapping` and `rpc_admin_batch_mapping_edit` (subject to Operator Decision #1), leaving `rpc_admin_mapping_edit_with_impact` as the single authenticated entrypoint and `service_role` retaining internal/script access if needed.

---

## 3. Affected Files & Services
- `supabase/migrations/YYYYMMDDHHMMSS_harden_inner_mapping_rpcs.sql` (new additive migration with `-- REVERSE:` comment; **IMPORTANT**: build strictly on post-`20261125100000_mapping_rebuild_ops.sql` `schema.sql` — do NOT alter or drop `alias_move`, `alias_clear`, `code_clear`, `product_edit`, or the `channel_aliases` lock in `rpc_admin_mapping_edit_with_impact` / `rpc_admin_batch_mapping_edit`)
- `src/lib/testing/mapping-contracts.test.ts` (update direct-call tests if Decision #1 revokes `authenticated` `EXECUTE`)
- `src/lib/testing/batch-alias-op.test.ts` (update direct-call tests if Decision #1 revokes `authenticated` `EXECUTE`)
- `src/lib/testing/showroom-mapping-integrity.test.ts`

---

## 4. Acceptance Criteria
- [ ] 1. `p_single = true` via `rpc_admin_mapping_edit_with_impact` succeeds when an inactive normalized twin exists alongside an active `channel_codes` row.
- [ ] 2. `rpc_admin_edit_channel_mapping` rolls back if a concurrent re-import commits an `unmapped: multi-item lokal order%` line between its pre-check and `UPDATE`.
- [ ] 3. Direct `authenticated` calls to `rpc_admin_edit_channel_mapping` and `rpc_admin_batch_mapping_edit` are rejected (`42501`) if Decision #1 is approved; `rpc_admin_mapping_edit_with_impact` remains executable by `authenticated` (`is_mapping_operator_role()`).
- [ ] 4. Migration includes `-- REVERSE:` block and passes `verify-migration-reverse.mjs`.

---

## 5. Regression Test Specification
- **Test-first**: Write a failing SQL test seeding an inactive normalized twin `'A B C'` before an active `'ABC'` row and calling `rpc_admin_mapping_edit_with_impact(..., p_single := true)`, plus a test for concurrent multi-item lokal order race and `authenticated` `EXECUTE` check.
- Test path: `src/lib/testing/mapping-contracts.test.ts`
- Expected assertion: Deterministic selection of the active row; rollback on multi-item lokal race; `42501` on direct inner RPC call by `authenticated`.

---

## 6. Risks & Rollback Requirements
- **Risk Assessment**: Medium — revoking `authenticated` `EXECUTE` on `rpc_admin_batch_mapping_edit` requires checking all SQL tests and any external callers; `src/lib/sku-mapping/sku-mapping-repo.ts` already exclusively uses `rpc_admin_mapping_edit_with_impact`.
- **Rollback Procedure**: Execute `-- REVERSE:` block to re-grant `EXECUTE` and restore the prior `rpc_admin_edit_channel_mapping` definition.
