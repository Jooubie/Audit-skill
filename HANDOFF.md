# Claude Code Handoff & Session Guide

This document is the operational briefing for **Claude Code** and **Operator Jou** to resume, review, and execute the audit remediation from this workspace.

---

## 1. Context & Session Accomplishments

In this setup session:
1. **Isolated Audit Environment Established**: Decoupled from legacy workflows, circular critique loops, and ad-hoc rules. Validated with [scripts/verify-isolation.sh](./scripts/verify-isolation.sh) (0 errors, 0 warnings).
2. **Knowledge Graph Codified**: 15 Software Engineering Proof Canons and 6 technical tool specifications imported from Google Drive into [wiki/](./wiki/) and indexed in [wiki/index.md](./wiki/index.md).
3. **Phase 1 Baseline Audit Completed**: 10 evidence-backed findings generated across the 6 audit dimensions and saved in [findings/AUD-001.md](./findings/AUD-001.md) through [findings/AUD-010.md](./findings/AUD-010.md).
4. **Phase 2 Implementation Plan Synthesized**: 10 bounded tickets generated in [tickets/TCK-001.md](./tickets/TCK-001.md) through [tickets/TCK-010.md](./tickets/TCK-010.md) and organized into 4 phases in [phases/phase-2-plan.md](./phases/phase-2-plan.md).
5. **Full Executive Report Produced**: [AUDIT-REPORT.md](./AUDIT-REPORT.md) with weighted score (80.3/100, Conditional Pass).

---

## 2. Hard Invariants for Claude Code

When working in or against the target codebase:
1. **Frozen Areas**:
   - `src/lib/erp/**`, `fixtures/**`, `scripts/verify-erp-*` are **FROZEN**. Never modify them.
   - MD5 fixture check must remain `1eaf531368b23a3f56f3bf4ebe0ce67a`.
2. **Ingestion Core**:
   - `src/lib/imports/**` and `src/lib/shopify/**` must not be moved in TCK-008.
3. **Database Migrations**:
   - Schema changes must be new additive migration files with a `REVERSE` rollback comment.
   - Never edit an existing migration.
4. **Test-First Discipline**:
   - For every defect ticket, write a test proving the defect exists before writing the fix ([Ref 05](./wiki/05-khorikov-testing-policy.md)).
5. **No Circular Reviews**:
   - Run deterministic checks ([scripts/preflight.sh](./scripts/preflight.sh)) frequently.
   - AI review happens exactly **once** per completed phase diff.

---

## 3. Decisions Pending from Jou

Before beginning Phase B and Phase C, Jou should decide on two trade-offs:

1. **TCK-004 (Enqueue RPC failure)**:
   - *Recommendation*: **Return 503** (triggers provider backoff retry per fail-fast [Ref 11](./wiki/11-nygard-production-stability.md)).
   - *Alternative*: Keep silent 200 (avoids retry floods, relies on background sweeper).
2. **TCK-007 (Bosta dedup bucket)**:
   - *Recommendation*: **Option C (Document & Accept)**. Data sync is already idempotent at the ledger layer.
   - *Alternative A*: Widen to 1-hour bucket.
   - *Alternative B*: Use request ID header.

---

## 4. Immediate Next Step: Phase A Execution

Phase A contains zero design dependencies and addresses the highest severity security issues:

```bash
# 1. Inspect Phase A tickets
cat tickets/TCK-001.md
cat tickets/TCK-002.md

# 2. Implement TCK-001 (RLS on webhook_events & sync_runs)
# Add additive migration with REVERSE comment

# 3. Implement TCK-002 (Bosta crypto.timingSafeEqual)
# Replace string === with timingSafeEqual in Bosta webhook handler

# 4. Verify Phase A
./scripts/preflight.sh
```

Once Phase A passes preflight tests, proceed to Phase B.
