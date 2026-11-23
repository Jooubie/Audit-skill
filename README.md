# Isolated Engineering Audit Environment

Welcome to the **Isolated Engineering Audit Environment**. This workspace is a self-contained, decoupled engineering audit harness equipped with the **15 Software Engineering Proof Canons**, preflight verification scripts, architectural configurations, audit findings, and implementation tickets.

---

## Quick Navigation

| Resource | Path | Description |
|---|---|---|
| **Audit Report** | [AUDIT-REPORT.md](./AUDIT-REPORT.md) | Executive verdict, domain scoreboard, and 10 detailed findings |
| **Claude Code Handoff** | [HANDOFF.md](./HANDOFF.md) | Instructions and step-by-step runbook for continuing with Claude Code |
| **Knowledge Graph** | [wiki/index.md](./wiki/index.md) | Master canon index linking all 15 proof books & conflict rules |
| **Master Plan** | [phases/phase-2-plan.md](./phases/phase-2-plan.md) | Phase 2 synthesis grouping 10 tickets into 4 implementation phases |
| **Findings** | [findings/](./findings/) | Markdown findings `AUD-001.md` through `AUD-010.md` |
| **Tickets** | [tickets/](./tickets/) | Remediation tickets `TCK-001.md` through `TCK-010.md` |
| **Preflight Suite** | [scripts/preflight.sh](./scripts/preflight.sh) | Executable preflight checker (typecheck, lint, knip, squawk, vitest) |
| **Isolation Verifier** | [scripts/verify-isolation.sh](./scripts/verify-isolation.sh) | Boundary & environment verification script |

---

## The 15 Engineering Proof Canons (`wiki/`)

Every finding, review, and code modification in this workspace is grounded in seminal engineering literature:

1. **Module Depth**: [01-ousterhout-module-depth.md](./wiki/01-ousterhout-module-depth.md) (*A Philosophy of Software Design*)
2. **Schema Evolution**: [02-kleppmann-schema-evolution.md](./wiki/02-kleppmann-schema-evolution.md) (*Designing Data-Intensive Applications*)
3. **Dimensional Modeling**: [03-kimball-star-schema-retail.md](./wiki/03-kimball-star-schema-retail.md) (*The Data Warehouse Toolkit*)
4. **Bounded Contexts**: [04-ddd-bounded-contexts.md](./wiki/04-ddd-bounded-contexts.md) (*Domain-Driven Design*)
5. **Testing Policy**: [05-khorikov-testing-policy.md](./wiki/05-khorikov-testing-policy.md) (*Unit Testing Principles, Practices, and Patterns*)
6. **Refactoring Vocabulary**: [06-fowler-refactoring-vocabulary.md](./wiki/06-fowler-refactoring-vocabulary.md) (*Refactoring*)
7. **TypeScript Strictness**: [07-typescript-conventions.md](./wiki/07-typescript-conventions.md)
8. **Pragmatic Principles**: [08-pragmatic-principles.md](./wiki/08-pragmatic-principles.md) (*The Pragmatic Programmer*)
9. **Clean Architecture**: [09-clean-architecture-boundaries.md](./wiki/09-clean-architecture-boundaries.md) (*Clean Architecture*)
10. **Fitness Functions**: [10-evolutionary-fitness-functions.md](./wiki/10-evolutionary-fitness-functions.md) (*Building Evolutionary Architectures*)
11. **Production Stability**: [11-nygard-production-stability.md](./wiki/11-nygard-production-stability.md) (*Release It!*)
12. **Data Lifecycle**: [12-data-engineering-lifecycle.md](./wiki/12-data-engineering-lifecycle.md) (*Fundamentals of Data Engineering*)
13. **Postgres Performance**: [13-postgres-query-performance.md](./wiki/13-postgres-query-performance.md) (*Use The Index, Luke*)
14. **OWASP & Database Security**: [14-owasp-security-and-supabase-rls.md](./wiki/14-owasp-security-and-supabase-rls.md)
15. **UI Craft & WCAG 2.2**: [15-ui-craft-and-wcag22.md](./wiki/15-ui-craft-and-wcag22.md)
- **Conflict Resolution Matrix**: [00-canon-index-and-conflicts.md](./wiki/00-canon-index-and-conflicts.md)

---

## Workflow Status

- **Phase 0: Isolation Verification** — **COMPLETE** (`./scripts/verify-isolation.sh` exits 0).
- **Phase 1: Baseline Audit** — **COMPLETE** (10 findings filed in `findings/`).
- **Phase 2: Planning & Tickets** — **COMPLETE** (10 tickets formulated in `tickets/`, master plan in `phases/phase-2-plan.md`).
- **Phase 3: Bounded Implementation** — **READY FOR EXECUTION** (Awaiting Jou's sign-off on 2 design decisions).
- **Phase 4: Independent Verification** — Standing by.
- **Phase 5: Release Gate** — Gated by Jou's explicit yes.

---

## Operational Commands

```bash
# Verify workspace isolation
./scripts/verify-isolation.sh

# Run comprehensive preflight check on target codebase
./scripts/preflight.sh

# Run Postgres catalog security queries
psql -f ./scripts/audit-supabase-catalog.sql

# Branch a target repository for auditing
./scripts/init-audit-env.sh <path-to-target-repo>
```
