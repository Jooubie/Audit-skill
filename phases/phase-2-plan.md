# Phase 2 — Repair Plan: Phased Ticket Synthesis

- **Phase**: Phase 2 — Planning & Architecture
- **Status**: Complete (Pending Operator Approval)
- **Last Updated**: 2026-11-23T22:05:00Z
- **Operator Approval**: Pending

---

## 1. Scope & Goals

Synthesize the 10 confirmed findings from Phase 1 Baseline Audit (AUD-001 through AUD-010) into bounded repair tickets grouped into 4 implementation phases, ordered by production risk, security impact, data integrity, functional dependencies, and implementation cost.

**Explicitly excluded**: Architectural rewrites, new frameworks, new libraries, new services, or new abstractions. All corrections prefer repairing existing functionality per Ousterhout (Ref 01) and Fowler (Ref 06).

---

## 2. Phase Groupings

### Phase A: Security & Data Integrity (Highest Priority)
> Production risk: **Critical** — tenant isolation and authentication bypasses

| Ticket | Finding | Title | Risk | Dependencies |
|---|---|---|---|---|
| [TCK-001](../tickets/TCK-001.md) | [AUD-001](../findings/AUD-001.md) | Add RLS policies to `webhook_events` and `sync_runs` | High | None |
| [TCK-002](../tickets/TCK-002.md) | [AUD-002](../findings/AUD-002.md) | Replace plain string equality with `timingSafeEqual` in Bosta auth | Low | None |

**Rationale**: AUD-001 is the only High-severity finding — missing RLS policies on tenant-scoped tables. AUD-002 is a timing-side-channel vulnerability in webhook authentication. Both are security fixes with no functional dependencies and must land first.

**Parallelizable**: TCK-001 and TCK-002 touch different files; can be assigned to separate specialists.

---

### Phase B: Reliability & Fail-Fast (Second Priority)
> Production risk: **Medium** — silent data gaps and unrecoverable event processing failures

| Ticket | Finding | Title | Risk | Dependencies |
|---|---|---|---|---|
| [TCK-003](../tickets/TCK-003.md) | [AUD-003](../findings/AUD-003.md) | Surface `markWebhookEvents` failures as structured error results | Low | None |
| [TCK-004](../tickets/TCK-004.md) | [AUD-006](../findings/AUD-006.md) | Return 503 on enqueue RPC failure instead of silent 200 | Medium | **Requires Jou's decision** on 200-vs-503 trade-off |

**Rationale**: Both findings describe silent failure paths where the system absorbs errors without surfacing them. TCK-003 is straightforward; TCK-004 is a design decision (the 200-on-failure was deliberate to avoid retry floods) that Jou must approve.

**Parallelizable**: TCK-003 and TCK-004 touch different files; can proceed in parallel once TCK-004 is unblocked.

---

### Phase C: Integration Resilience (Third Priority)
> Production risk: **Low-Medium** — integration robustness under edge conditions

| Ticket | Finding | Title | Risk | Dependencies |
|---|---|---|---|---|
| [TCK-005](../tickets/TCK-005.md) | [AUD-005](../findings/AUD-005.md) | Implement cursor-based pagination in `listWebhookSubscriptions` | Low | None |
| [TCK-006](../tickets/TCK-006.md) | [AUD-008](../findings/AUD-008.md) | Add retry with exponential backoff for Shopify GraphQL | Low | None |
| [TCK-007](../tickets/TCK-007.md) | [AUD-004](../findings/AUD-004.md) | Widen Bosta dedup bucket or document boundary gap | Low | None |

**Rationale**: These improve resilience against external API edge cases (pagination limits, rate limiting, dedup boundary). The sync layer is idempotent at the data level, so these are correctness improvements, not data-loss risks.

**Parallelizable**: All three touch different files; fully parallel.

---

### Phase D: Architecture & Governance (Lowest Priority)
> Production risk: **Low** — structural improvement, documentation, and test coverage

| Ticket | Finding | Title | Risk | Dependencies |
|---|---|---|---|---|
| [TCK-008](../tickets/TCK-008.md) | [AUD-007](../findings/AUD-007.md) | Move domain services from `src/lib/` to `src/server/services/` | Medium | **Depends on TCK-001** (both touch `integrations-repo.ts`) |
| [TCK-009](../tickets/TCK-009.md) | [AUD-009](../findings/AUD-009.md) | Verify REVERSE comments on all migrations + CI lint | Low | None |
| [TCK-010](../tickets/TCK-010.md) | [AUD-010](../findings/AUD-010.md) | Add BOM edge-case regression tests for `readTextCapped` | Very Low | None |

**Rationale**: TCK-008 is a pure Move Function refactoring (Ref 06) that must not mix with feature work. TCK-009 and TCK-010 are governance and test-coverage-only tickets. All have zero production urgency but improve maintainability and audit compliance.

**Note**: TCK-008 is sequenced after Phase A because it touches files modified by TCK-001. TCK-009 and TCK-010 are independent and can run any time.

---

## 3. Decisions Required from Operator Jou

| # | Decision | Ticket | Recommendation |
|---|---|---|---|
| 1 | **200 vs 503 on enqueue failure**: Change webhook routes to return 503 when `rpc_enqueue_job` fails? This triggers Shopify/Bosta retries but risks flood under sustained DB failure. | TCK-004 | Yes — 503 is correct per fail-fast (Ref 11); provider backoff mitigates flood risk. Document rate-limit behavior. |
| 2 | **Bosta dedup bucket strategy**: Widen to 1-hour (Option A), use request ID header (Option B), or document and accept (Option C)? | TCK-007 | Option C (document and accept) — sync is idempotent; the boundary collision is a resource-waste concern, not a data issue. Add a test to prove the boundary behavior. |

---

## 4. Execution Constraints

- **ERP export frozen**: `src/lib/erp/**`, `fixtures/**`, `scripts/verify-erp-*` are untouched by all tickets.
- **Ingestion core**: `src/lib/imports/**`, `src/lib/shopify/**` are not moved in TCK-008 per SeemlyOps hard rules.
- **Schema changes**: TCK-001 migration is additive with REVERSE comment.
- **Max 2 worktrees at once** per SeemlyOps workflow rules.
- **Test-first**: Each ticket requires test coverage proving the defect before the fix (Ref 05).

---

## 5. Finding-to-Ticket Traceability Matrix

| Finding | Severity | Ticket | Phase |
|---|---|---|---|
| AUD-001 | High | TCK-001 | A |
| AUD-002 | Medium | TCK-002 | A |
| AUD-003 | Medium | TCK-003 | B |
| AUD-004 | Low | TCK-007 | C |
| AUD-005 | Low | TCK-005 | C |
| AUD-006 | Medium | TCK-004 | B |
| AUD-007 | Medium | TCK-008 | D |
| AUD-008 | Low | TCK-006 | C |
| AUD-009 | Informational | TCK-009 | D |
| AUD-010 | Low | TCK-010 | D |

---

## 6. Next Action

Present this plan to Operator Jou for approval. Block on decisions #1 and #2 above before beginning Phase B (TCK-004) and Phase C (TCK-007).
