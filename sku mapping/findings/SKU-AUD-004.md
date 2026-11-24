---
type: finding
id: SKU-AUD-004
title: "Legacy mapping write RPCs exposed to authenticated plus non-deterministic single-edit lookup"
severity: High
confidence: High
category: Security
status: open
canon: "[[14-owasp-security-and-supabase-rls]]"
created: 2026-11-24
updated: 2026-11-24
tags:
  - audit
  - finding
  - security
  - database
  - sku-mapping
---

# [[SKU-AUD-004]]: Legacy mapping write RPCs exposed to `authenticated` plus non-deterministic single-edit lookup

- **Finding ID**: SKU-AUD-004
- **Severity**: High
- **Confidence**: High
- **Category**: Security
- **Governing Canon**: [[14-owasp-security-and-supabase-rls]]
- **Location**: `supabase/schema.sql` (Lines 2710-2819, 2826-2873 post-`20261125100000`), `supabase/acl.sql` (Lines 325-328)

---

## 1. Description & Evidence

All application grid edits (`src/lib/sku-mapping/sku-mapping-repo.ts:26-34`) call `rpc_admin_mapping_edit_with_impact`, which acquires cross-channel advisory locks and `SHARE ROW EXCLUSIVE` table locks, verifies `p_expected_impact`, and then delegates to either `rpc_admin_edit_channel_mapping` (`p_single = true`) or `rpc_admin_batch_mapping_edit` (`p_single = false`).

Three defects remain in these inner functions:
1. **Direct `authenticated` grants bypass impact & locking**: `supabase/acl.sql:325,327` grants `EXECUTE` on both `rpc_admin_batch_mapping_edit` and `rpc_admin_edit_channel_mapping` directly to `authenticated`, allowing a signed-in mapping operator to call `rpc_admin_batch_mapping_edit` via PostgREST while bypassing `rpc_admin_mapping_edit_with_impact`'s `p_expected_impact` stale-preview check and `LOCK TABLE` ordering.
2. **Inconsistent `SECURITY INVOKER` + missing `pg_temp` on `rpc_admin_edit_channel_mapping`**: Unlike `rpc_admin_mapping_edit_with_impact` and `rpc_admin_batch_mapping_edit`, `rpc_admin_edit_channel_mapping` (`supabase/schema.sql:2710-2712`) is `SECURITY INVOKER` with `SET search_path TO 'public'` (no `pg_temp`). Calling it directly as `authenticated` fails on revoked table privileges (`channel_codes`, `sales_lines`, `audit_log`), even though `EXECUTE` is granted.
3. **Non-deterministic `LIMIT 1` and missing multi-item race check in `rpc_admin_edit_channel_mapping`**: Migration `20261102120000_showroom_mapping_integrity.sql:67-78` patched `rpc_admin_batch_mapping_edit` Pass 3 with `ORDER BY cc.active DESC NULLS LAST, cc.id LIMIT 1`, but missed `rpc_admin_edit_channel_mapping` (`supabase/schema.sql:2751-2757`), which still runs `LIMIT 1` with **no `ORDER BY`**. It also lacks the post-`UPDATE` `unmapped: multi-item lokal order%` race guard added in `20261119100000_batch_alias_op.sql`.

---

## 2. Actual or Credible Failure Scenario

1. When a single-code edit (`POST /api/sku-mapping`, `p_single = true`) targets a code that has an inactive normalized twin alongside an active row (a state explicitly permitted by `channel_codes_active_mapping_key`), `rpc_admin_edit_channel_mapping`'s unordered `LIMIT 1` can select the inactive row and attempt `SET active = true`, failing with SQLSTATE `23505` instead of updating the active row.
2. Any authenticated mapping operator (or client holding a valid JWT) can call `rpc_admin_batch_mapping_edit` directly via PostgREST, bypassing the confirmed-range / ERP-export impact acknowledgement enforced by `rpc_admin_mapping_edit_with_impact`.

---

## 3. Technical & Business Impact
- **Technical Impact**: Stale-impact bypass surface on `authenticated`; `23505` failure on single-code edits with inactive twins; missing post-update multi-item lokal guard.
- **Business Impact**: Single-code edits fail unexpectedly on codes with historical inactive twins; direct RPC calls could modify confirmed periods or exported data without preview verification.

---

## 4. Proposed Correction
In a new additive migration (with `-- REVERSE:` comment):
1. Check whether any tests/scripts call `rpc_admin_batch_mapping_edit` or `rpc_admin_edit_channel_mapping` directly as `authenticated` (note: `mapping-contracts.test.ts` and `batch-alias-op.test.ts` call `rpc_admin_batch_mapping_edit` directly—decide in Phase 2 whether to migrate those callers/tests to `rpc_admin_mapping_edit_with_impact` or revoke `authenticated` after updating tests).
2. Add `ORDER BY cc.active DESC NULLS LAST, cc.id` to `rpc_admin_edit_channel_mapping` (line 2757) and add the post-`UPDATE` `unmapped: multi-item lokal order%` check, or route `p_single = true` through `rpc_admin_batch_mapping_edit` / unify both paths cleanly.

---

## 5. Verification Criteria
- [ ] SQL test proving `p_single = true` in `rpc_admin_mapping_edit_with_impact` succeeds when inactive normalized twins exist alongside an active row.
- [ ] Verify `acl.sql` / least-privilege tests pass after revoking direct `authenticated` execution if approved.
