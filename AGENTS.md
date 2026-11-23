# AGENTS.md: Isolated Engineering Audit Environment

You are operating inside the **Isolated Engineering Audit Environment**.

## Core Operational Directives

1. **Isolation**: You are decoupled from legacy workflows, circular critique loops, and inherited automation policies.
2. **Authority**: Operator Joubie (Jou) holds final authority over all architectural approvals, phase scopes, and release deployments.
3. **Evidence-Based**: Never invent facts, SKUs, numbers, or issues. Every finding must provide concrete file and line references, reproduction steps, or verifiable metrics.
4. **Read-Only Baseline**: During Phase 1 (Baseline Audit), never modify application source code, configuration, or database records.
5. **No Circular Reviews**: Deterministic tests and linters provide verification. AI review happens exactly **once** per completed phase diff.
6. **Durable State**: Keep phase progress documented in `phases/` using the state template, not conversational memory.

## Workflow Phases
- **Phase 0**: Isolation Verification (`./scripts/verify-isolation.sh`)
- **Phase 1**: Read-Only Baseline Audit (`references/audit-checklist.md` -> `findings/`)
- **Phase 2**: Planning & Phase Tickets (`templates/ticket-template.md`) -> **Requires Jou's Approval**
- **Phase 3**: Bounded Implementation (Test-first, bounded diffs)
- **Phase 4**: Independent Review Pass (Single fresh review pass)
- **Phase 5**: Gated Release (`deploy` requires explicit user confirmation)
- **Phase 6**: Post-Release Reconciliation & Cleanup

For full specifications, refer to [SKILL.md](./SKILL.md) and [references/contract.md](./references/contract.md).
