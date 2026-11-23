# Baseline Audit Checklist

Use this checklist during **Phase 1: Baseline Audit** to ensure all operational and architectural vectors are systematically evaluated.

## 1. Code Quality & Architecture
- [ ] Directory structure conforms to standard idioms (e.g., Next.js App Router / server vs client boundaries).
- [ ] No dead code, obsolete feature flags, or orphaned exports.
- [ ] Type safety: No abusive `any` or `@ts-ignore` masking real runtime type mismatches.
- [ ] Clean separation of concerns between data access, business domain, and UI rendering.

## 2. Database & Data Integrity
- [ ] Schema consistency: All foreign keys have indexes and appropriate deletion constraints (`ON DELETE CASCADE` / `RESTRICT`).
- [ ] Migration history is strictly additive with clear down/reverse scripts.
- [ ] Query performance: Identification of N+1 query patterns, unindexed filters, or unbound queries.
- [ ] Financial / numerical integrity: Decimal precision preserved, no float inaccuracies in money/inventory calculations.
- [ ] Ledger & transaction atomicity: Multi-table state mutations wrapped in database transactions.

## 3. Security, Authentication & Access
- [ ] Row Level Security (RLS) or application-layer authorization verified for every table/endpoint.
- [ ] Session tokens, cookies, and headers handled with proper `SameSite`, `HttpOnly`, and `Secure` attributes.
- [ ] Secrets management: No credentials, keys, or passwords committed or logged in client bundles.
- [ ] Input validation: Rigorous schema validation (e.g., Zod) on all public and internal API inputs.

## 4. API & Integration Reliability
- [ ] External webhook handling is idempotent and validates signatures.
- [ ] Rate limiting, retry backoff, and circuit breaking for third-party integrations.
- [ ] Error responses do not leak internal stack traces or database error details.

## 5. Performance & Frontend
- [ ] Bundle size and code-splitting boundaries analyzed.
- [ ] Core Web Vitals: Server-side rendering vs client fetching posture.
- [ ] Responsive design verified at desktop (1440px) and mobile (390px) viewports.

## 6. Infrastructure, Docker & Deployment
- [ ] Multi-stage Docker builds minimizing image surface and eliminating build tools from runtime.
- [ ] Containers run as non-root users with least-privilege capabilities.
- [ ] Healthcheck endpoints reflect true system dependency health (DB, cache, storage).
- [ ] Log output is structured, actionable, and free of sensitive payload leaks.

## 7. Testing & Regression
- [ ] Automated test suite runs reliably and deterministically.
- [ ] Critical business paths (checkouts, payments, ingestion, ledger adjustments) covered by end-to-end or integration tests.
- [ ] Edge cases (empty states, network timeouts, invalid payloads) tested.
