---
type: ticket
id: SKU-TCK-007
title: "Cap staged-alias reason length, extract shared paging helper, and fix unmapped README drift"
finding: "[[SKU-AUD-009]]"
phase: "[[phase-2-plan]]"
status: draft
priority: P3
assigned_agent: "Claude Sonnet"
created: 2026-11-24
updated: 2026-11-24
tags:
  - audit
  - ticket
  - architecture
  - cleanup
  - sku-mapping
---

# [[SKU-TCK-007]]: Cap staged-alias `reason` length, extract shared paging helper, and fix unmapped README drift

- **Ticket ID**: SKU-TCK-007
- **Related Finding**: [[SKU-AUD-009]]
- **Implementation Phase**: [[phase-2-plan]] (Phase D — Input Bounds & Hygiene)
- **Status**: Draft
- **Assigned Agent**: Claude Sonnet (`seemly-backend`)

---

## 1. Problem Definition
1. `approveStagedSchema` and `rejectStagedBody` (`src/lib/sku-mapping/schema.ts:64-72`) and `rpc_resolve_staged_alias` (`supabase/schema.sql:7408` post-`20261125100000`) accept unbounded `reason` strings, unlike every other mapping write (`max 500 chars`).
2. Five `sku-mapping` repository files duplicate identical 1,000-row Supabase pagination loops (`mapping-repo.ts`, `export-repo.ts`, `csv-import-repo.ts`, `holds-repo.ts`, `shopify-preview-repo.ts`).
3. `src/app/api/unmapped/README.md:11` documents `capability: 'erp.operate'` instead of `capability: 'skuMapping.edit'`.

---

## 2. Expected Outcome
- Staged-alias approve/reject endpoints enforce the same 500-character `reason` limit (`400` on overflow) as all other mapping endpoints.
- All five `sku-mapping` repositories reuse one shared `readAllPages` helper (avoiding any behavior change to `src/lib/imports/**` or `src/lib/shopify/**`).
- `src/app/api/unmapped/README.md:11` matches `src/app/api/unmapped/map/route.ts`.

---

## 3. Affected Files & Services
- `src/lib/sku-mapping/schema.ts`
- `src/lib/sku-mapping/mapping-repo.ts` (export shared `readAllPages` or place in a small shared helper)
- `src/lib/sku-mapping/export-repo.ts`
- `src/lib/sku-mapping/csv-import-repo.ts`
- `src/lib/sku-mapping/holds-repo.ts`
- `src/lib/sku-mapping/shopify-preview-repo.ts`
- `src/app/api/unmapped/README.md`
- `src/app/api/sku-mapping/staged-aliases/route.test.ts`

---

## 4. Acceptance Criteria
- [ ] 1. `POST` and `DELETE /api/sku-mapping/staged-aliases` return HTTP `400` when `reason.trim().length > 500`.
- [ ] 2. Duplicated pagination loops across the 5 `sku-mapping` repo files share one helper with unchanged error/paging semantics.
- [ ] 3. `src/app/api/unmapped/README.md` accurately lists `capability: 'skuMapping.edit'`.
- [ ] 4. `npm run ci` (`tsc`, `eslint`, `knip`, `verify:docs`, `npm test`) passes.

---

## 5. Regression Test Specification
- **Test-first**: Add failing test in `src/app/api/sku-mapping/staged-aliases/route.test.ts` sending a 501-char `reason` to `POST` and `DELETE`.
- Test path: `src/app/api/sku-mapping/staged-aliases/route.test.ts`
- Expected assertion: HTTP 400 with consistent message `'The reason is too long (500 characters max).'`.

---

## 6. Risks & Rollback Requirements
- **Risk Assessment**: Low — purely local validation, helper deduplication, and doc sync.
- **Rollback Procedure**: Revert commit.
