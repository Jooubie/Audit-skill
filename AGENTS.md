# AGENTS.md: Isolated Engineering Audit Environment

You are operating inside the **Isolated Engineering Audit Environment**.

## Core Operational Directives

1. **Isolation**: You are decoupled from legacy workflows, circular critique loops, and inherited automation policies.
2. **Knowledge Graph & Grounding**: All audit findings, architectural reviews, and code remediation MUST be grounded in the canons codified in `wiki/index.md`. Consult specific canon references before declaring defects or implementing fixes.
3. **Authority**: Operator Joubie (Jou) holds final authority over all architectural approvals, phase scopes, and release deployments.
4. **Evidence-Based**: Never invent facts, SKUs, numbers, or issues. Every finding must provide concrete file and line references, reproduction steps, or verifiable metrics.
5. **Read-Only Baseline**: During Phase 1 (Baseline Audit), never modify application source code, configuration, or database records.
6. **No Circular Reviews**: Deterministic tests and linters provide verification. AI review happens exactly **once** per completed phase diff.
7. **Durable State**: Keep phase progress documented in `phases/` using the state template, not conversational memory.

## Technical Canon Reference Map (`wiki/`)
- **Module Depth & Complexity**: `wiki/01-ousterhout-module-depth.md`
- **Schema Evolution**: `wiki/02-kleppmann-schema-evolution.md`
- **Dimensional Modeling**: `wiki/03-kimball-star-schema-retail.md`
- **DDD Bounded Contexts**: `wiki/04-ddd-bounded-contexts.md`
- **Testing Policy & Verification**: `wiki/05-khorikov-testing-policy.md`
- **Refactoring Standards**: `wiki/06-fowler-refactoring-vocabulary.md`
- **TypeScript Strictness**: `wiki/07-typescript-conventions.md`
- **Pragmatic Invariants**: `wiki/08-pragmatic-principles.md`
- **Clean Architecture Boundaries**: `wiki/09-clean-architecture-boundaries.md`
- **Production Resilience**: `wiki/11-nygard-production-stability.md`
- **Postgres Performance**: `wiki/13-postgres-query-performance.md`
- **OWASP & Database Security**: `wiki/14-owasp-security-and-supabase-rls.md`
- **Master Precedence & Conflicts**: `wiki/00-canon-index-and-conflicts.md`

## Workflow Phases
- **Phase 0**: Isolation Verification (`./scripts/verify-isolation.sh`)
- **Phase 1**: Read-Only Baseline Audit (`references/audit-checklist.md` -> `findings/`)
- **Phase 2**: Planning & Phase Tickets (`templates/ticket-template.md`) -> **Requires Jou's Approval**
- **Phase 3**: Bounded Implementation (Test-first, bounded diffs)
- **Phase 4**: Independent Review Pass (Single fresh review pass)
- **Phase 5**: Gated Release (`deploy` requires explicit user confirmation)
- **Phase 6**: Post-Release Reconciliation & Cleanup

For full specifications, refer to [SKILL.md](./SKILL.md) and [references/contract.md](./references/contract.md).
