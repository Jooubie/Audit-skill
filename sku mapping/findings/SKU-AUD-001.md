---
type: finding
id: SKU-AUD-001
title: "Stale is_ops_role() RLS policies exclude finance and expose mapping tables"
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
  - rls
  - sku-mapping
---

# [[SKU-AUD-001]]: Stale `is_ops_role()` RLS policies exclude `finance` and expose mapping tables

- **Finding ID**: SKU-AUD-001
- **Severity**: High
- **Confidence**: High
- **Category**: Security
- **Governing Canon**: [[14-owasp-security-and-supabase-rls]]
- **Location**: `supabase/schema.sql` (Lines 1280-1344, 15462-15625 post-`20261125100000`), `src/lib/access/policy.ts` (Line 70), `src/app/api/sku-mapping/batch/import-preview/route.ts`, `src/app/api/sku-mapping/export/route.ts`, `src/app/api/sku-mapping/staged-aliases/route.ts`

---

## 1. Description & Evidence

In `src/lib/access/policy.ts:17,70`, `skuMapping.edit` belongs to `ADMIN_FINANCE` (`['admin', 'finance']`), and `is_mapping_operator_role()` (`supabase/schema.sql:1280-1287`) admits `('admin', 'manager', 'finance')`. However, four SKU-mapping tables still enforce RLS policies using `is_ops_role()` (`('admin', 'manager', 'operations', 'customer_support')`, `supabase/schema.sql:1322-1329`):

```sql
-- supabase/schema.sql:15618
CREATE POLICY channel_mapping_holds_select_ops ON public.channel_mapping_holds
  FOR SELECT TO authenticated
  USING ((( SELECT public.is_ops_role() AS is_ops_role) AND (NOT ( SELECT public.is_support_restricted() AS is_support_restricted))));

-- supabase/schema.sql:15566
CREATE POLICY channel_alias_staging_select_ops ON public.channel_alias_staging
  FOR SELECT TO authenticated
  USING ((( SELECT public.is_ops_role() AS is_ops_role) AND (NOT ( SELECT public.is_support_restricted() AS is_support_restricted))));

-- supabase/schema.sql:15462 & 15475
CREATE POLICY automap_actions_select_ops ON public.automap_actions ...
CREATE POLICY automap_batches_select_ops ON public.automap_batches ...
```

Meanwhile:
- `POST /api/sku-mapping/batch/import-preview` (`src/lib/sku-mapping/csv-import-repo.ts:55`) and `GET /api/sku-mapping/export` (`src/lib/sku-mapping/export-mappings.ts:16`) query `channel_mapping_holds` using the caller's session client (`userDb()`).
- `GET /api/sku-mapping/staged-aliases` (`src/app/api/sku-mapping/staged-aliases/route.ts:14-16`) bypasses RLS via `adminDb` (service role).

---

## 2. Actual or Credible Failure Scenario

1. A `finance` operator opens `/sku-mapping`, uploads a CSV in `import-preview`, or downloads `GET /api/sku-mapping/export?kind=mappings`. Because `finance` is not in `is_ops_role()`, Postgres RLS silently returns **0 rows** from `channel_mapping_holds`. Held keys (`1007-XS`, etc.) are falsely shown as `ready` in import preview (only failing later on save via trigger) and `held=false` in the exported CSV.
2. `operations` and `customer_support` sessions retain `SELECT` visibility over `channel_mapping_holds`, `channel_alias_staging`, `automap_batches`, and `automap_actions` even though they hold no `skuMapping.edit` capability.

---

## 3. Technical & Business Impact
- **Technical Impact**: RLS policy mismatch against the application capability matrix (`policy.ts`); silent empty reads for `finance`; unnecessary `adminDb` usage in `GET /api/sku-mapping/staged-aliases`.
- **Business Impact**: Finance operators receive misleading CSV import previews and inaccurate mapping exports; unauthorized roles retain read access to mapping queue/automation tables.

---

## 4. Proposed Correction
1. Add an additive migration (with `-- REVERSE:` comment) updating the `SELECT` policies on `channel_mapping_holds`, `channel_alias_staging`, `automap_batches`, and `automap_actions` to `(SELECT public.is_mapping_operator_role())` (matching `channel_codes` and `channel_aliases`).
2. Switch `GET /api/sku-mapping/staged-aliases` from `adminDb` to `userDb` so RLS applies uniformly to staged-queue reads.

---

## 5. Verification Criteria
- [ ] pgTAP / SQL RLS test proving `admin`, `manager`, and `finance` can `SELECT` from all four tables while `operations`, `customer_support`, `warehouse`, and `anon` receive 0 rows per [[05-khorikov-testing-policy]].
- [ ] Integration test verifying `import-preview` and `export` detect active holds when invoked as `finance`.
- [ ] `./scripts/preflight.sh` and `npm run verify:fast` pass.
