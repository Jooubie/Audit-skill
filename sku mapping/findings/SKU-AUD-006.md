---
type: finding
id: SKU-AUD-006
title: "Genz code guard uses exact-string ledger lookup and skips new_sku batch codes"
severity: Medium
confidence: High
category: Security
status: open
canon: "[[08-pragmatic-principles]]"
created: 2026-11-24
updated: 2026-11-24
tags:
  - audit
  - finding
  - correctness
  - genz
  - sku-mapping
---

# [[SKU-AUD-006]]: Genz code guard uses exact-string ledger lookup and skips `new_sku` batch codes

- **Finding ID**: SKU-AUD-006
- **Severity**: Medium
- **Confidence**: High
- **Category**: Code Quality
- **Governing Canon**: [[08-pragmatic-principles]]
- **Location**: `src/lib/sku-mapping/genz-guard-repo.ts` (Lines 55-79), `src/lib/sku-mapping/mapping-edit.ts` (Line 53)

---

## 1. Description & Evidence

`genzCodeGuard` protects Genz mappings against size mismatches (suffix `1..5` and bracketed text size like `(S,gray)`) and item family mismatches:

```typescript
// src/lib/sku-mapping/genz-guard-repo.ts:55-60
async function latestText(db: Db, channelId: string, code: string): Promise<string | null> {
  const { data, error } = await db.from('sales_lines').select('channel_product').eq('channel_id', channelId).eq('channel_code', code)
    .not('channel_product', 'is', null).order('sale_date', { ascending: false }).limit(1)
  if (error) throw error
  return data?.[0]?.channel_product ?? null
}

// src/lib/sku-mapping/genz-guard-repo.ts:75-79
export const codeEditsOf = (edits: readonly Json[]): GuardedCodeEdit[] => edits.flatMap((edit, editIndex) => {
  const e = edit as { kind?: unknown; channel_id?: unknown; code?: unknown; variant_id?: unknown } | null
  return e && typeof e === 'object' && e.kind === 'code' && typeof e.channel_id === 'string' && typeof e.code === 'string' && typeof e.variant_id === 'string'
    ? [{ channelId: e.channel_id, code: e.code, variantId: e.variant_id, editIndex }] : []
})
```

Two gaps exist:
1. `latestText` uses `.eq('channel_code', code)` (exact string match), whereas `channel_codes` and `sales_lines` resolve by normalized key (`mapping_code_key`, stripping whitespace and folding ASCII case).
2. `codeEditsOf` only inspects `{ kind: 'code' }` edits. If a batch contains `{ kind: 'new_sku', sku: '...', codes: { Genz: '70034-3-2' } }`, `rpc_admin_batch_mapping_edit` Pass 2 queues that code into `v_code_ops` and writes it to `channel_codes` + `sales_lines`, completely bypassing `genzCodeGuard`.

---

## 2. Actual or Credible Failure Scenario

1. A Genz sales line in `sales_lines` has `channel_code = ' 7081-1-2 '` (or `'abc-s'`) with `channel_product = 'baby zip up (S,gray)'`. An operator maps `'7081-1-2'` (trimmed) to an `M` variant; `latestText` returns `null` because of the whitespace difference, skipping the bracketed-size refusal.
2. An operator creates a `new_sku` row in the mapping grid with size `XL` and types a Genz code ending in `-2` (`S`) in the Genz column; `genzCodeGuard` is skipped because `edit.kind === 'new_sku'`, allowing the mismatched Genz code to save.

---

## 3. Technical & Business Impact
- **Technical Impact**: Normalization mismatch in `latestText`; validation bypass on `new_sku.codes`.
- **Business Impact**: Wrong-size SKU mappings can slip past the Genz guard into the ledger and ERP exports.

---

## 4. Proposed Correction
1. Resolve `latestText` using normalized key matching (either via a small indexed RPC or filtered query matching `mapping_code_key`) instead of exact `.eq('channel_code', code)`.
2. Extend `genzCodeGuard` / `previewOrSave` (or add a DB/service check) to also validate any Genz entry in `new_sku.codes` (against the new SKU's `size` and existing item siblings).

---

## 5. Verification Criteria
- [ ] Unit tests in `src/lib/sku-mapping/genz-guard-repo.test.ts` and `mapping-edit-genz-guard.test.ts` covering whitespace/case-variant `channel_code` in `latestText` and `new_sku` with a mismatched Genz code.
- [ ] `npm test` and `npx tsc --noEmit` pass.
