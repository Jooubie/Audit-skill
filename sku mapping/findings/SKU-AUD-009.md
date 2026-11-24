---
type: finding
id: SKU-AUD-009
title: "Shallow pass-throughs, duplicated pagination helpers, and missing reason length cap on staged aliases"
severity: Low
confidence: High
category: Architecture
status: open
canon: "[[01-ousterhout-module-depth]]"
created: 2026-11-24
updated: 2026-11-24
tags:
  - audit
  - finding
  - architecture
  - maintainability
---

# [[SKU-AUD-009]]: Shallow pass-throughs, duplicated pagination helpers, and missing reason length cap on staged aliases

- **Finding ID**: SKU-AUD-009
- **Severity**: Low
- **Confidence**: High
- **Category**: Architecture
- **Governing Canon**: [[01-ousterhout-module-depth]]
- **Location**: `src/lib/sku-mapping/` (`holds.ts`, `holds-repo.ts`, `mapping-repo.ts`, `export-repo.ts`, `csv-import-repo.ts`, `shopify-preview-repo.ts`, `schema.ts`), `supabase/schema.sql:7408`, `src/app/api/unmapped/README.md:11`

---

## 1. Description & Evidence

1. **Duplicated Supabase pagination helper**: Identical 1,000-row paging loops (`from += 1000`, `.range(...)`) are re-implemented in five places: `mapping-repo.ts:111-122`, `export-repo.ts:10-18`, `csv-import-repo.ts:17-25`, `holds-repo.ts:7-14,20-30`, and `shopify-preview-repo.ts:21-26,32-39,48-57`.
2. **Shallow pass-through module**: `src/lib/sku-mapping/holds.ts` (12 lines) solely forwards `loadHeldKeys` and `loadAllHeldKeys` directly to `holds-repo.ts` (`[[01-ousterhout-module-depth]]`).
3. **Inconsistent `reason` length validation**: `codeEditSchema` (`schema.ts:24`), `batchRequestSchema` (`schema.ts:50`), `unmappedLineSchema` (`schema.ts:87`), `rpc_admin_batch_mapping_edit`, and `rpc_admin_edit_channel_mapping` all enforce a 500-character limit on `reason`, whereas `approveStagedSchema`, `rejectStagedBody` (`schema.ts:64-72`), and `rpc_resolve_staged_alias` (`supabase/schema.sql:7028-7036`) accept unbounded `reason` strings.
4. **Doc drift**: `src/app/api/unmapped/README.md:11` states `withRoute({ capability: 'erp.operate', ... })`, whereas `src/app/api/unmapped/map/route.ts:11` uses `capability: 'skuMapping.edit'`.

---

## 2. Actual or Credible Failure Scenario

- Any change to Supabase pagination error handling or page size must be patched across five files.
- An oversized `reason` payload on `/api/sku-mapping/staged-aliases` writes arbitrarily large JSONB entries into `audit_log.new_values`.

---

## 3. Technical & Business Impact
- **Technical Impact**: Maintenance overhead from duplicated paging logic and shallow wrappers; unbounded `reason` field on staged-alias audit entries.
- **Business Impact**: Low immediate risk; increases drift and audit-log bloat over time.

---

## 4. Proposed Correction
1. Extract a shared `readAllPages` helper (or reuse one inside `src/lib/sku-mapping/mapping-repo.ts` / `src/lib/supabase/`) across `sku-mapping` repositories and inline/consolidate `holds.ts` only if bounded within a cleanup ticket (do not touch `src/lib/imports/**` or `src/lib/shopify/**` without behavioral equivalence tests).
2. Add the 500-character cap to `approveStagedSchema` / `rejectStagedBody` (and `rpc_resolve_staged_alias`) to match the other mapping endpoints.
3. Update `src/app/api/unmapped/README.md:11` to reflect `capability: 'skuMapping.edit'`.

---

## 5. Verification Criteria
- [ ] Unit tests covering 500-char `reason` rejection on staged-alias approve/reject.
- [ ] `npm run ci` (`tsc`, `eslint`, `knip`, unit tests) passes.
