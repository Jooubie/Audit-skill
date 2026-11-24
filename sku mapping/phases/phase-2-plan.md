---
type: phase
phase_id: "Phase-2"
name: "SKU Mapping Architectural Synthesis & Repair Plan"
status: complete
approval_status: pending
created: 2026-11-24
updated: 2026-11-24
tags:
  - audit
  - phase-2
  - roadmap
  - sku-mapping
---

# Phase 2 — Unified Master Execution Plan: SKU Mapping Architecture & Repair

- **Phase**: Phase 2 — Architectural Synthesis & Planning
- **Goal Architecture**: [[GOAL-ARCHITECTURE]]
- **Status**: Complete (Pending Operator Approval)
- **Last Updated**: 2026-11-24T22:20:00+02:00
- **Operator Approval**: Pending

---

## 1. Scope, Baseline & Post-`sku-mapping-rebuild` Reconciliation

This plan is the **single master execution plan** uniting:
- **Pre-Wave (`sku-review` owner items)**: Operational/data decisions from `Work/sku-review/` after the live `sku-mapping-rebuild` release (`19345270` / `734f2fd7`, migration `20261125100000_mapping_rebuild_ops.sql`).
- **Phases A → D (`[[SKU-TCK-001]]`..`[[SKU-TCK-007]]`)**: Remediation of the 9 confirmed audit findings (`[[SKU-AUD-001]]`..`[[SKU-AUD-009]]` in `[[phase-1-baseline]]`), with `schema.sql` line references verified post-`20261125100000`.
- **Phases E → F (`[[SKU-TCK-008]]`..`[[SKU-TCK-010]]`)**: Strategic Goal Architecture completion (`[[GOAL-ARCHITECTURE]]`) — authoritative `erp_item_master` gate, wiring provenance, effective-dated forward-only remaps, split-brain closure, `rpc_wiring_health_audit()`, and map-once `channel_listings`.

> **Already shipped in `sku-mapping-rebuild` (`19345270` / `734f2fd7`, do NOT re-plan)**: `Find & edit` UI (`_components/find-edit/*`), `GET /api/sku-mapping/lookup`, `POST /api/sku-mapping/listing-preview`, `alias_move`/`alias_clear`/`code_clear`/`product_edit` in `20261125100000_mapping_rebuild_ops.sql`, `genz-guard.ts` `ONE`-size warning (Decision 104.5), `suggest.ts` `missing_size` hints, coded Lokal code-only resolution (T04), and confirm-day `unmapped > 0` gate.

**Explicitly excluded / Frozen Invariants**:
- **Frozen ERP Export**: Never touch `src/lib/erp/**`, `fixtures/**`, `scripts/verify-erp-*`, or the 6 frozen ERP SQL functions — **explicitly including `rpc_erp_export_source` (`supabase/schema.sql:5101-5170`)**. Checksum `node scripts/verify-erp-fixtures.mjs | md5sum` = `1eaf531368b23a3f56f3bf4ebe0ce67a` must remain exact.
- **Ingestion Core**: Changes touching `src/lib/imports/**` or `src/lib/shopify/**` (including `SKU-TCK-010` Genz `0/0` listing capture) require tests proving existing `sales_lines` behavior is unchanged.
- **Sash Hard Stop (Decision 95 / 102)**: Zero Sash mapping or ledger writes until Jooubie confirms the Sash wiring list.
- **No speculative rewrites** (`[[01-ousterhout-module-depth]]`, `[[06-fowler-refactoring-vocabulary]]`); preserve N:1 active `channel_codes` per `(channel_id, variant_id)` and `ONE`-size Genz warnings.

---

## 2. Execution Waves & Phase Groupings

### Pre-Wave: `sku-review` Owner Decisions & Operational Catch-Up (Non-Code)
> Status: `lokal`, `locally`, `mr.local` are **54/54 days confirmed** (Decision 105 ERP `v3` zip generated); 92 `pending_decisions.csv` + `pending_remaps.csv` fixes applied on `19345270` with 0 dry re-resolution diffs.

| Item | Scope | Gate / Owner Action |
|---|---|---|
| **Genz catch-up** | Import Genz 22–23 Nov & verify 15–21 Nov net (blocked by Genz Brand Sales HTTP 500 on 24 Nov) | Retry Genz portal export & confirm days via `/imports` |
| **Owner conflict review** | `conflict-review.md` items: Genz colour `36` (6 styles), `70034`/`11062` remaps, `2042-xs` ERP key, Shopify legacy/`3001-Black-XL` | Jou review (`5001/5002 -> 5015/5016` moves to `[[SKU-TCK-008]]` per Decision 63) |
| **Family/colour proposal** | `family-colour-proposal.md`: 329 products -> 87 families (`products.model`, `products.colour`), 16 low-confidence + 17 conflict rows | Jou approval before applying via `product_edit` |
| **Sash wiring list** | `Black printed -> 2043`, `Top - Black` (9 styles), `Off Shoulder Printed` | **Hard Stop** (Decision 95 / 102) until Jou confirms with team |
| **DB housekeeping** | `sales_lines.size` NULL backfill (Decision 16), 244 `channel_alias_staging_source_batch_id_fkey` orphans, `lokal` Oct unexported check | Read-only audit + approved remediation |

---

### Phase A: RLS Alignment & Mapping Write Security (Highest Priority)
> Production risk: **High** — `finance` silently blinded on holds via RLS, `operations`/`customer_support` over-privileged, and inner RPCs exposed to `authenticated` (`schema.sql:2710-2873`, `acl.sql:325-328`).

| Ticket | Finding(s) | Title | Risk | Dependencies |
|---|---|---|---|---|
| [[SKU-TCK-001]] | [[SKU-AUD-001]] | Align RLS policies on `channel_mapping_holds`, `channel_alias_staging`, `automap_*` to `is_mapping_operator_role()` & switch `staged-aliases` GET to `userDb` | Low | None |
| [[SKU-TCK-002]] | [[SKU-AUD-004]] | Harden `rpc_admin_edit_channel_mapping` (`schema.sql:2710-2819`: `ORDER BY`, post-update lokal race check, `pg_temp`) & revoke direct `authenticated` `EXECUTE` on inner RPCs (`acl.sql:325-328`) | Medium | **Requires Decision #1** |

**Parallelizable**: `SKU-TCK-001` and `SKU-TCK-002` touch disjoint tables/functions; sequential migration timestamps if applied together.

---

### Phase B: Core Resolution, Ledger Consistency & Undo Integrity (High Priority)
> Production risk: **High** — `23505` crashes on normalized twins (`schema.sql:5403-5570`), missing `sales_lines.size`, destructive automap undo, and collapsed code-less queue items (`schema.sql:8815-8882`).

| Ticket | Finding(s) | Title | Risk | Dependencies |
|---|---|---|---|---|
| [[SKU-TCK-003]] | [[SKU-AUD-002]], [[SKU-AUD-008]] | Fix `rpc_map_unmapped_line` (`schema.sql:5403-5570`) normalized twin reuse, `size = v.size` write, post-update lokal check, and `rpc_automap_apply_item`/`undo` snapshots | Medium | None |
| [[SKU-TCK-004]] | [[SKU-AUD-003]] | Partition `rpc_unresolved_sales` (`schema.sql:8815-8882`) by normalized `code` or `alias` key (`mapping_code_key` / `mapping_alias_key`) | Low-Med | **Requires Decision #3** |

**Parallelizable**: `SKU-TCK-003` and `SKU-TCK-004` modify disjoint RPCs (`rpc_map_unmapped_line`/`automap` vs `rpc_unresolved_sales`).

---

### Phase C: Performance Indexing, Key Parity & Genz Guard (Medium Priority)
> Production risk: **Medium** — unindexed 500-iteration `sales_lines` scans under 8-table `SHARE ROW EXCLUSIVE` locks (`schema.sql:2855-2856`), `COLLATE "C"` drift, and Genz guard bypass on `new_sku` / unnormalized codes.

| Ticket | Finding(s) | Title | Risk | Dependencies |
|---|---|---|---|---|
| [[SKU-TCK-005]] | [[SKU-AUD-005]], [[SKU-AUD-007]] | Add functional `sales_lines` mapping indexes, unify `mapping_code_key`/`mapping_alias_key` (`COLLATE "C"`) across RPCs, and guard pending `channel_alias_staging` uniqueness (`schema.sql:13738`) | Medium | After Phase A/B RPC edits; **Requires Decision #2** |
| [[SKU-TCK-006]] | [[SKU-AUD-006]] | Normalize Genz `latestText` ledger lookup (`genz-guard-repo.ts:56`) and enforce `genzCodeGuard` on `new_sku.codes` in batches | Low | None |

---

### Phase D: Input Bounds, Cleanup & Documentation (Low Priority)
> Production risk: **Low** — unbounded `reason` on staged aliases, duplicated paging loops, doc drift.

| Ticket | Finding(s) | Title | Risk | Dependencies |
|---|---|---|---|---|
| [[SKU-TCK-007]] | [[SKU-AUD-009]] | Cap staged-alias `reason` at 500 chars, share `readAllPages` across `sku-mapping` repos, and fix `api/unmapped/README.md` | Low | **Requires Decision #4** |

---

### Phase E: Authoritative ERP Gate, Provenance & Effective-Dated Remaps (Goal Architecture Layer 1 & 2)
> Strategic goal: Prevent non-ERP ghost SKUs, close remaining split-brain (`channel_list_prices` + `inventory` upgrade), protect closed/exported periods from silent history rewrites, and add `rpc_wiring_health_audit()`.

| Ticket | Scope | Title | Risk | Dependencies |
|---|---|---|---|---|
| [[SKU-TCK-008]] | [[GOAL-ARCHITECTURE]] L1, Dec 60 & 63 | Add `public.erp_item_master` table, authoritative ERP SKU write gate, pre-export SKU check (without touching `rpc_erp_export_source`), and `5001/5002 -> 5015/5016` alignment | Medium | After Phases A–C; **Requires Decision #5** |
| [[SKU-TCK-009]] | [[GOAL-ARCHITECTURE]] L2, Gemini A/C/D/E | Add mapping verification provenance, forward-only effective-dated remaps + N:1 UI prompt, `channel_list_prices`/`inventory` split-brain closure, DB Genz guard, and `rpc_wiring_health_audit()` | Medium | After Phase C (`SKU-TCK-005`); **Requires Decision #6** |

---

### Phase F: Map-Once Listing Registry (Goal Architecture Layer 2)
> Strategic goal: Map new portal listings once before their first sale arrives, using the `listing-preview` engine shipped in `sku-mapping-rebuild`.

| Ticket | Scope | Title | Risk | Dependencies |
|---|---|---|---|---|
| [[SKU-TCK-010]] | [[GOAL-ARCHITECTURE]] L2, Dec 58–59 | Add `public.channel_listings` registry (portal stock/catalogue exports + Genz `0/0` unsold capture) and "New listings to map" queue | Medium | After `SKU-TCK-008` & `SKU-TCK-009`; **Requires Decision #7** |

---

## 3. Decisions Required from Operator Jou

| # | Decision | Ticket | Recommendation |
|---|---|---|---|
| 1 | **Revoke direct `authenticated` `EXECUTE` on inner write RPCs?** (`rpc_admin_batch_mapping_edit`, `rpc_admin_edit_channel_mapping`) | [[SKU-TCK-002]] | **Yes — Revoke from `authenticated`** so all session edits must flow through `rpc_admin_mapping_edit_with_impact` (`p_expected_impact` + lock order); update the SQL tests to call `rpc_admin_mapping_edit_with_impact` (or test as `service_role`). *(Alternative: keep `authenticated` `EXECUTE` on `rpc_admin_batch_mapping_edit` and only fix `rpc_admin_edit_channel_mapping`.)* |
| 2 | **Normalized uniqueness on `channel_alias_staging` (`pending` rows)?** | [[SKU-TCK-005]] | **Yes — Check prod read-only first** (`vps.sh sql` / migration pre-check) and add a partial unique index `(channel_id, mapping_alias_key(product_text)) WHERE status = 'pending'`, while updating `rpc_import_batch_atomic` to upsert/dedup by `mapping_alias_key`. *(Alternative: dedup only inside `rpc_import_batch_atomic` without an index.)* |
| 3 | **Counting code-less groups in `rpc_unresolved_sales` `totals.codes`?** | [[SKU-TCK-004]] | **Count all distinct unresolved `(channel_id, key_kind, key_norm)` keys in `totals.codes`** so badges and queue totals reflect distinct unmapped products (codes + aliases) accurately while preserving the existing JSON key names. *(Alternative: count only coded keys in `totals.codes` and add `totals.aliases`.)* |
| 4 | **Keep shallow `holds.ts` pass-through or inline it?** | [[SKU-TCK-007]] | **Keep `holds.ts` as-is** to avoid churn across `resolve-mappings.ts` and `automap-service.ts`, and focus `SKU-TCK-007` on `reason` length cap, shared `readAllPages`, and `README.md` fix. *(Alternative: inline `holds.ts` into `holds-repo.ts`.)* |
| 5 | **Strictness of `erp_item_master` gate & `5001/5002 -> 5015/5016` timing?** | [[SKU-TCK-008]] | **Enforce strictly whenever `erp_item_master` is non-empty**, keep `variants.in_erp_export = true` as the fallback before initial load, and execute `5001/5002 -> 5015/5016` only after uploading the accountant's ERP Item List confirms `5015/5016`. *(Alternative: warn-only on `new_sku` and block only on pre-export check.)* |
| 6 | **Default `remap_mode` when editing a mapping that hits confirmed/exported lines?** | [[SKU-TCK-009]] | **Default to `'forward_only'` (`effective_from = day after latest confirmed/exported date`)** with an explicit override checkbox (`rewrite_all`) + reason for rare intentional restatements like Decision 105. *(Alternative: keep `'rewrite_all'` as default with a warning.)* |
| 7 | **Initial ingestion scope for `channel_listings` map-once registry?** | [[SKU-TCK-010]] | **Start with Genz `0/0` unsold rows + manual/portal stock CSV upload for `lokal`, `locally`, `mr.local`, and `shopify`** (excluding `Sash` until Decision 95/102 stop lifts). *(Alternative: manual CSV upload only, deferring Genz `0/0` hook.)* |

---

## 4. Execution Constraints & Verification Policy
- **Additive Migrations**: Every SQL change is a new forward-only migration with `SET LOCAL lock_timeout` and a `-- REVERSE:` block (`verify-migration-reverse.mjs`). No `CONCURRENTLY` inside transactional migrations.
- **Test-First**: Every ticket starts with a failing unit or SQL test (`[[05-khorikov-testing-policy]]`).
- **Verification**: Run `npx tsc --noEmit`, `npm run ci:checks`, `npm run verify:erp` (`1eaf531368b23a3f56f3bf4ebe0ce67a`), targeted tests, and `bash scripts/sql-test-db.sh` (`npm run ci:full` / `verify:fast` once per phase).
- **Single Review & Release Gate**: Exactly **one** fresh read-only review pass per completed phase diff; no deployment or production DB push without Jou's explicit approval in the active session.

---

## 5. Finding & Goal-Architecture Traceability Matrix

| Source / Finding | Severity / Scope | Ticket | Phase |
|---|---|---|---|
| [[SKU-AUD-001]] | High | [[SKU-TCK-001]] | A |
| [[SKU-AUD-004]] | High | [[SKU-TCK-002]] | A |
| [[SKU-AUD-002]] | High | [[SKU-TCK-003]] | B |
| [[SKU-AUD-008]] | Medium | [[SKU-TCK-003]] | B |
| [[SKU-AUD-003]] | High | [[SKU-TCK-004]] | B |
| [[SKU-AUD-005]] | Medium | [[SKU-TCK-005]] | C |
| [[SKU-AUD-007]] | Medium | [[SKU-TCK-005]] | C |
| [[SKU-AUD-006]] | Medium | [[SKU-TCK-006]] | C |
| [[SKU-AUD-009]] | Low | [[SKU-TCK-007]] | D |
| [[GOAL-ARCHITECTURE]] L1 / Dec 60 & 63 / Gemini B | Strategic | [[SKU-TCK-008]] | E |
| [[GOAL-ARCHITECTURE]] L2 / Gemini A, C, D, E | Strategic | [[SKU-TCK-009]] | E |
| [[GOAL-ARCHITECTURE]] L2 / Dec 58–59 | Strategic | [[SKU-TCK-010]] | F |

---

## 6. Next Action
Await Operator Jou's approval on **Phase 2** (`[[GOAL-ARCHITECTURE]]` + Phases **A–F**) and Decisions **#1–#7** (plus Pre-Wave `sku-review` owner items) before creating a feature/audit branch in `~/Code/seemlyops` and beginning **Phase 3 — Bounded Test-First Implementation** (starting with **Phase A**).

---

## 7. Self-Check & Session Review Notes (2026-11-24)
1. **Post-`20261125100000` `schema.sql` Line Parity**: All `findings/SKU-AUD-001`..`009` line references were re-checked and aligned to current `seemlyops/supabase/schema.sql` (`734f2fd7`).
2. **No Regression Against `sku-mapping-rebuild` (`19345270`)**: `SKU-TCK-002` and `SKU-TCK-005` explicitly instruct builders to start from the current `20261125100000_mapping_rebuild_ops.sql` RPC bodies and preserve `alias_move`, `alias_clear`, `code_clear`, `product_edit`, and `channel_aliases` row locking.
3. **`new_sku.codes` Shape & `ONE`-Size Exception**: `SKU-TCK-006` explicitly handles `codes: { Genz: string | string[] }` and preserves Decision 104.5 (`ONE`-size warning).
4. **Intentional `INTEGRITY.md` Update**: `SKU-TCK-009` explicitly notes that upgrading `mapping_method = 'inventory'` lines in `rpc_resolve_staged_alias` updates the legacy `lines_updated = 0` invariant in `src/lib/sku-mapping/INTEGRITY.md:39-41` and its test assertions.
5. **Visual Master Companion**: Published alongside the Markdown pack in [SKU-MAPPING-MASTER-PLAN.html](../SKU-MAPPING-MASTER-PLAN.html) for interactive review and Claude Code handoff.
