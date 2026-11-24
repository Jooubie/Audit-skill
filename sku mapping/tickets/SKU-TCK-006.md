---
type: ticket
id: SKU-TCK-006
title: "Normalize Genz latestText lookup and enforce Genz guard on new_sku codes"
finding: "[[SKU-AUD-006]]"
phase: "[[phase-2-plan]]"
status: draft
priority: P2
assigned_agent: "Claude Sonnet"
created: 2026-11-24
updated: 2026-11-24
tags:
  - audit
  - ticket
  - correctness
  - genz
  - sku-mapping
---

# [[SKU-TCK-006]]: Normalize Genz `latestText` lookup and enforce Genz guard on `new_sku` codes

- **Ticket ID**: SKU-TCK-006
- **Related Finding**: [[SKU-AUD-006]]
- **Implementation Phase**: [[phase-2-plan]] (Phase C — Performance, Key Parity & Genz Guard)
- **Status**: Draft
- **Assigned Agent**: Claude Sonnet (`seemly-backend`)

---

## 1. Problem Definition
1. `latestText` in `src/lib/sku-mapping/genz-guard-repo.ts:56` queries `sales_lines` using exact `.eq('channel_code', code)`, missing ledger rows whose `channel_code` differs in whitespace or case from the trimmed input and silently bypassing the bracketed-size refusal.
2. `codeEditsOf` (`src/lib/sku-mapping/genz-guard-repo.ts:75-79`) only extracts `{ kind: 'code' }` edits, so `{ kind: 'new_sku', codes: { Genz: string | string[] } }` edits (`20261125100000_mapping_rebuild_ops.sql:271-279`) in `/api/sku-mapping/batch` bypass `genzCodeGuard` completely.

---

## 2. Expected Outcome
- `latestText` matches `sales_lines.channel_code` using normalized key parity (`mapping_code_key`, e.g., via a small read-only `STABLE` SQL helper or normalized filter) so whitespace/case variants still surface the bracketed text size.
- `genzCodeGuard` extracts both scalar string and `string[]` Genz entries from any `new_sku` edit's `codes` map and validates each code against the new SKU's derived size (from the last `-<size>` segment, matching `rpc_admin_batch_mapping_edit`) and Genz item siblings, while preserving the Decision 104.5 `ONE`-size warning behavior.

---

## 3. Affected Files & Services
- `src/lib/sku-mapping/genz-guard-repo.ts`
- `src/lib/sku-mapping/mapping-edit.ts` (if `new_sku` edit validation hooks into `genzCodeGuard`)
- `supabase/migrations/YYYYMMDDHHMMSS_genz_latest_text_rpc.sql` (only if a small normalized `STABLE` lookup RPC is used for `latestText`; or query `ilike` + filter in JS)
- `src/lib/sku-mapping/genz-guard-repo.test.ts`
- `src/lib/sku-mapping/mapping-edit-genz-guard.test.ts`

---

## 4. Acceptance Criteria
- [ ] 1. `latestText` finds `sales_lines.channel_product` when `sales_lines.channel_code` has extra spaces or different casing (e.g., `' 7081-1-2 '` vs `'7081-1-2'`).
- [ ] 2. `editMappingBatch` refuses a `new_sku` edit whose `codes.Genz` suffix (`-2`) disagrees with the new SKU's size (`-L`) with `editIndex` pointing to the `new_sku` edit.
- [ ] 3. Existing Genz guard unit tests and SQL tests pass.

---

## 5. Regression Test Specification
- **Test-first**: Add failing unit tests in `genz-guard-repo.test.ts` and `mapping-edit-genz-guard.test.ts` for whitespace-variant `channel_code` and `new_sku.codes.Genz` size mismatch.
- Test paths: `src/lib/sku-mapping/genz-guard-repo.test.ts`, `src/lib/sku-mapping/mapping-edit-genz-guard.test.ts`
- Expected assertion: Refusal returned with exact `editIndex`; no RPC write attempted.

---

## 6. Risks & Rollback Requirements
- **Risk Assessment**: Low — purely tightens pre-save Genz validation on existing write paths.
- **Rollback Procedure**: Revert commit (and `-- REVERSE:` if an RPC is added).
