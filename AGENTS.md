# AGENTS.md / CLAUDE.md: Isolated Engineering Audit Environment

You are operating inside the **AuditSkill Isolated Engineering Environment**.

## Core Operational Directives

1. **Isolation**: You are decoupled from legacy workflows, circular critique loops, and inherited automation policies.
2. **Knowledge Graph & Grounding**: All audit findings, architectural reviews, and code remediation MUST be grounded in the 15 canons codified in `wiki/index.md`. Consult specific canon references before declaring defects or implementing fixes.
3. **Authority**: Operator Joubie (Jou) holds final authority over all architectural approvals, phase scopes, and release deployments. Ask him decisions, numbered, with your recommendation first so "yes" accepts it.
4. **Evidence-Based & Obsidian-Native**:
   - Never invent facts, numbers, or issues. Every finding must provide concrete file and line references, reproduction steps, or verifiable metrics.
   - All findings and tickets MUST use Obsidian-friendly YAML frontmatter (`type`, `id`, `severity`, `status`, `tags`) and `[[wikilinks]]` linking back to canon chapters (e.g., `[[01-ousterhout-module-depth]]`).
5. **Read-Only Baseline**: During Phase 1 (Baseline Audit), never modify application source code, configuration, or database records.
6. **No Circular Reviews**: Deterministic tests and linters provide verification. AI review happens exactly **once** per completed phase diff.
7. **Durable State**: Keep phase progress documented in `phases/` using the state template, not conversational memory.

## Multi-Model Role Division
- **Phase 1: Codebase Reconnaissance**: Use **Claude Haiku / Sonnet** to scan the target codebase across the 6 dimensions, focusing on risky code (security, auth timing, RLS leaks, error swallowing, unindexed queries).
- **Phase 2: Architectural Synthesis & Planning**: Use **Claude Opus** to group findings into bounded phases (`tickets/TCK-XXX.md` and `phases/phase-2-plan.md`) and submit for Jou's approval.
- **Phase 3: Bounded Implementation**: Test-first implementation against approved tickets. Keep diffs strictly bounded; never modify frozen ERP or core ingestion modules.
- **Phase 4: Independent Verification**: Single read-only verification pass examining the complete diff against acceptance criteria.

## Running an Audit on a New Target Codebase
To audit any repository or local folder:
```bash
./scripts/start-audit.sh <path-to-target-repo>
```
This script validates git isolation, creates a clean `audit/` folder inside the target, links `wiki/` for Obsidian graph browsing, and verifies the environment.

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
