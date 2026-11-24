---
type: ticket
id: SKU-TCK-010
title: "Add channel_listings map-once registry and New listings to map queue"
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
  - listings
  - map-once
  - sku-mapping
---

# [[SKU-TCK-010]]: Add `channel_listings` map-once registry and "New listings to map" queue

- **Ticket ID**: SKU-TCK-010
- **Related Finding / Design**: [[GOAL-ARCHITECTURE]] (Layer 2; Decisions 58–59; `goal.md` next phase)
- **Implementation Phase**: [[phase-2-plan]] (Phase F — Map-Once Listing Registry)
- **Status**: Draft
- **Assigned Agent**: Claude Opus + Claude Sonnet (`seemly-data` + `seemly-backend` + `seemly-frontend`)

---

## 1. Problem Definition
1. `sku-mapping-rebuild` (`19345270`) delivered `POST /api/sku-mapping/listing-preview` (`listing-plan.ts`, `listing-plan-repo.ts`) as a stateless preview over existing sales/prices/mappings, and `rpc_unresolved_sales` (`schema.sql:8842`) explicitly excludes unsold rows (`NOT (sl.qty = 0 AND sl.net = 0)`).
2. Consequently, there is **no persistent `channel_listings` registry** fed by portal stock/catalogue exports (Shopify CSV, Locally/Lokal catalogue sheets, Genz `0/0` unsold rows), so new channel listings cannot be mapped **once before their first sale** — operators still discover unmapped items only after sales fail on `/imports`.

---

## 2. Expected Outcome
- New `public.channel_listings` table storing normalized portal listings (`id`, `channel_id`, `external_key_kind` `'code'|'alias'`, `external_key_norm`, `raw_code`, `raw_product_text`, `listing_style_key`, `source` `'stock_export'|'catalogue'|'genz_unsold'|'manual'`, `status` `'unmapped'|'mapped'|'ignored'`, `variant_id`, `first_seen_at`, `last_seen_at`, `last_batch_id`), with RLS aligned to `is_mapping_operator_role()`.
- Ingestion hooks (without altering `sales_lines` financial math or `resolveMappings()` behavior):
  - Genz `0/0` unsold listing rows upserted into `channel_listings` during import.
  - Portal stock/catalogue export upload or sync feeds `channel_listings` (`lokal`, `locally`, `mr.local`, `shopify`; **Sash excluded until Decision 95/102 stop lifts**).
- "New listings to map" queue on `/sku-mapping` (grouped by listing/style using existing `listing-plan.ts` + `lookup.ts` + `MappingPreviewPanel`), allowing operators to map an entire style's sizes in one batch before sales arrive.

---

## 3. Affected Files & Services
- `supabase/migrations/YYYYMMDDHHMMSS_channel_listings_registry.sql` (new additive migration with `SET LOCAL lock_timeout = '5s'` and `-- REVERSE:` block)
- `src/lib/sku-mapping/listings-repo.ts` & `src/lib/sku-mapping/listings-service.ts`
- `src/lib/sku-mapping/listing-plan.ts` & `listing-plan-repo.ts` (connect persisted unmapped listings to existing preview/apply pipeline)
- `src/app/api/sku-mapping/listings/route.ts` (queue + ingest/ignore endpoints, gated by `skuMapping.edit`)
- `src/lib/imports/**` (additive non-blocking hook recording Genz `0/0` unsold rows into `channel_listings` — requires behavioral equivalence test on `resolveMappings` / `sales_lines`)
- `src/components/sku-mapping/` (New listings to map tab/panel, checked at 1440px and 390px)
- `src/lib/testing/channel-listings.test.ts`

---

## 4. Acceptance Criteria
- [ ] 1. `public.channel_listings` created with normalized unique index `(channel_id, external_key_kind, external_key_norm)` (`COLLATE "C"` parity), RLS policies (`is_mapping_operator_role()`), and `-- REVERSE:` block.
- [ ] 2. Re-uploading a catalogue or importing Genz `0/0` rows upserts `channel_listings` idempotently and automatically marks listings `'mapped'` when an active `channel_codes` or `channel_aliases` entry already covers them.
- [ ] 3. Mapping a listing via the queue calls `rpc_admin_mapping_edit_with_impact`, respects `erp_item_master` (`[[SKU-TCK-008]]`), and leaves Sash untouched unless explicitly enabled.
- [ ] 4. Existing `src/lib/imports/**` behavioral tests prove `sales_lines` resolution and ledger math are 100% unchanged.
- [ ] 5. UI verified at `1440px` and `390px` viewports; `src/lib/access/role-tabs.ts` & `destinations.ts` checked for no feature loss.

---

## 5. Regression Test Specification
- **Test-first**: Write failing SQL/unit tests for:
  1. Idempotent upsert of Genz `0/0` unsold rows into `channel_listings` without creating unmapped `sales_lines` queue noise.
  2. Auto-reconciling `channel_listings.status` to `'mapped'` once `channel_codes` / `channel_aliases` is written.
  3. Behavioral equivalence test proving `resolveMappings()` output on existing import fixtures is byte-for-byte unchanged.
- Test path: `src/lib/testing/channel-listings.test.ts`
- Expected assertion: All tests pass; frozen ERP verification passes untouched.

---

## 6. Risks & Rollback Requirements
- **Risk Assessment**: Medium — touches import pipeline for Genz `0/0` listing capture (guarded by behavioral equivalence tests) and adds a new UI queue (guarded by viewport & role-tab checks).
- **Rollback Procedure**: Run `-- REVERSE:` block to drop `public.channel_listings` and helper RPCs; revert TS/UI commits.
