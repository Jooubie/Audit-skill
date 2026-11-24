---
type: ticket
id: SKU-TCK-009
title: "Add mapping provenance, forward-only effective-dated remaps, split-brain closure, and rpc_wiring_health_audit()"
finding: "[[GOAL-ARCHITECTURE]]"
phase: "[[phase-2-plan]]"
status: draft
priority: P2
assigned_agent: "Claude Opus + Claude Sonnet"
created: 2026-11-24
updated: 2026-11-24
tags:
  - audit
  - ticket
  - database
  - provenance
  - effective-dating
  - sku-mapping
---

# [[SKU-TCK-009]]: Add mapping provenance, forward-only effective-dated remaps, split-brain closure, and `rpc_wiring_health_audit()`

- **Ticket ID**: SKU-TCK-009
- **Related Finding / Design**: [[GOAL-ARCHITECTURE]] (Layer 2; Gemini Findings A, C, D, E)
- **Implementation Phase**: [[phase-2-plan]] (Phase E — Authoritative ERP Gate & Wiring Provenance)
- **Status**: Draft
- **Assigned Agent**: Claude Opus + Claude Sonnet (`seemly-data` + `seemly-backend` + `seemly-frontend`)

---

## 1. Problem Definition
1. **No provenance on wiring (`Finding A`)**: `channel_codes` (`supabase/schema.sql:11181-11190`) and `channel_aliases` (`supabase/schema.sql:11168-11174`) lack `verification_status`, `verified_by`, `verified_at`, `source`, and `season_tag`. Operators cannot distinguish legacy sheet imports from operator-verified seasonal mappings.
2. **Historical rewrites & silent N:1 additions (`Finding C`)**: Neither mapping table has `valid_from` / `valid_to`. `rpc_admin_edit_channel_mapping` (`schema.sql:2769-2785`), `rpc_admin_batch_mapping_edit` (`20261125100000:538-549`), and `alias_move` (`20261125100000:663-677`) unconditionally rewrite all historical `sales_lines` (including confirmed/ERP-exported periods). Meanwhile, `size-row.tsx:77-95` ("Add code or name") allows N:1 codes without prompting when an active code already exists for that showroom + variant.
3. **Remaining split-brain (`Finding D`)**:
   - `channel_list_prices` enforces exact `(channel_id, product_text)` (`schema.sql:13143`) instead of `mapping_alias_key(product_text)`.
   - `rpc_resolve_staged_alias` (`schema.sql:7467-7492`) approves a staged alias without upgrading matching `mapping_method = 'inventory'` lines (`lines_updated = 0`), and `alias_move` (`20261125100000:672`) skips `'inventory'` lines.
4. **No `rpc_wiring_health_audit()` & TS-only Genz parity (`Finding E`)**: `rpc_wiring_health_audit()` does not exist anywhere in `~/Code/seemlyops`, and Genz size/family consistency checks live only in TS (`genz-guard.ts`).

---

## 2. Expected Outcome
- **Additive provenance & effective-dating columns**:
  - `channel_codes` & `channel_aliases`: add `verification_status text NOT NULL DEFAULT 'unverified'` (`CHECK IN ('unverified','verified','disputed')`), `verified_by uuid`, `verified_at timestamptz`, `source text NOT NULL DEFAULT 'legacy'`, `season_tag text`.
  - `channel_codes`: add `valid_from date`, `valid_to date` (nullable = open-ended; preserving N:1 active codes per `(channel_id, variant_id)` — **NO** unique constraint on `(channel_id, variant_id)`).
- **Safe remap modes & N:1 prompt**:
  - Add `remap_mode` (`'forward_only'` vs `'rewrite_all'`) to `rpc_admin_mapping_edit_with_impact` / `rpc_mapping_edit_impact` so remaps affecting confirmed/exported ranges default to closing the old code (`valid_to = cutoff - 1`, `active = false` or date-windowed) and creating the new period row without altering exported history unless explicitly overridden (Decision #6).
  - UI `size-row.tsx` / `MappingPreviewPanel` shows a confirmation prompt when adding a second active code to a `(channel_id, variant_id)` that already has one (`"Variant already has active code X in this showroom — add seasonal/secondary code?"`).
- **Split-brain closure**:
  - `channel_list_prices`: normalize lookup/uniqueness via `mapping_alias_key(product_text)` (after checking prod for normalized duplicates).
  - `rpc_resolve_staged_alias` & `alias_move`: upgrade matching `mapping_method = 'inventory'` lines (not covered by an active code) so `sales_lines` converges with `channel_aliases`. *(Note: this intentionally updates the legacy `lines_updated = 0` contract documented in `src/lib/sku-mapping/INTEGRITY.md:39-41`; update `INTEGRITY.md` and `src/lib/testing/resolve-staged*.test.ts` in the same ticket.)*
- **Health Audit & DB Genz Guard**:
  - New read-only `rpc_wiring_health_audit()` (`SECURITY DEFINER`, `SET search_path TO 'pg_catalog', 'public', 'pg_temp'`, gated by `is_mapping_operator_role()`) returning structured diagnostics: unverified active mappings, N:1 active code groups, `channel_list_prices` vs `channel_aliases` drift, `inventory` lines not yet upgraded, `erp_item_master` mismatches, and Genz prefix-size mismatches (respecting `ONE`-size exception).
  - Postgres helper/trigger enforcing Genz suffix-size parity on `channel_codes` inserts/updates while explicitly allowing `ONE`-size styles (Decision 104.5).

---

## 3. Affected Files & Services
- `supabase/migrations/YYYYMMDDHHMMSS_wiring_provenance_effective_dating.sql` (new additive migration with `SET LOCAL lock_timeout = '5s'` and `-- REVERSE:` block)
- `src/lib/sku-mapping/mapping-edit.ts`, `mapping-repo.ts`, `schema.ts` (support `remap_mode`, `effective_from`, `verification_status`, `season_tag`)
- `src/components/sku-mapping/find-edit/size-row.tsx` & `mapping-preview-panel.tsx` (N:1 active code confirmation prompt + verification badge/season tag + forward-only vs rewrite warning)
- `src/app/api/sku-mapping/health/route.ts` (exposes `rpc_wiring_health_audit()`)
- `src/lib/testing/wiring-provenance-audit.test.ts`

---

## 4. Acceptance Criteria
- [ ] 1. Existing N:1 active codes (e.g., Rizz dual barcodes, Genz `3008`/`3347`) continue to work; UI warns/confirms before adding a second active code to the same `(channel_id, variant_id)`.
- [ ] 2. `forward_only` remap preserves confirmed/ERP-exported `sales_lines` before `effective_from` while resolving lines on/after `effective_from` to the new variant.
- [ ] 3. `rpc_resolve_staged_alias` upgrades matching `mapping_method = 'inventory'` lines (when not covered by an active code) and records accurate `lines_updated`.
- [ ] 4. `rpc_wiring_health_audit()` exists, passes `acl.sql` / RLS checks (`is_mapping_operator_role()`), and detects seeded split-brain, unverified, and Genz suffix-mismatch anomalies while allowing `ONE`-size Genz mappings.
- [ ] 5. Frozen ERP export (`src/lib/erp/**`, `fixtures/**`, `rpc_erp_export_source`) remains untouched.

---

## 5. Regression Test Specification
- **Test-first**: Write failing SQL/integration tests asserting:
  1. Remapping a code with confirmed prior-month lines in `forward_only` mode leaves confirmed lines unchanged and updates only unconfirmed/future lines.
  2. Approving a staged alias upgrades `mapping_method = 'inventory'` lines.
  3. `rpc_wiring_health_audit()` returns expected counts for unverified mappings, N:1 codes, and Genz mismatches (`ONE`-size exempted).
- Test path: `src/lib/testing/wiring-provenance-audit.test.ts`
- Expected assertion: All assertions pass; `npm run ci:checks` and `sql-test-db.sh` pass.

---

## 6. Risks & Rollback Requirements
- **Risk Assessment**: Medium — effective-dated `channel_codes` uniqueness must stay compatible with `channel_codes_active_mapping_key` and `resolveMappings()` tier-1 lookup. Keep `active = true` uniqueness on `(channel_id, mapping_code_key(code))` when open-ended, or `(channel_id, mapping_code_key(code)) WHERE active AND valid_to IS NULL` if historical periods stay row-retained.
- **Rollback Procedure**: Run `-- REVERSE:` block to drop added columns/functions and restore prior RPC bodies; revert TS/UI commit.
