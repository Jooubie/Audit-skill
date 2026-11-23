# 🛡️ AuditSkill: Canon-Grounded Engineering Audits & Bounded AI Remediation

> **Transform autonomous coding agents from erratic code-generators into disciplined, Principal-level software auditors.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Grounded Canons: 15](https://img.shields.io/badge/Grounded%20Canons-15%20Proof%20Books-emerald.svg)](./wiki/index.md)
[![Obsidian Ready](https://img.shields.io/badge/Obsidian-Native%20Graph-purple.svg)](./templates/finding-template.md)
[![Verification: Deterministic](https://img.shields.io/badge/Verification-Deterministic%20Preflight-green.svg)](./scripts/preflight.sh)

AuditSkill is an isolated, canon-grounded engineering harness for **Claude Code** and autonomous coding agents. It prevents agent drift, stops hallucinated defects, breaks circular review loops, and bounds code remediation strictly within **15 seminal software engineering literature canons**.

---

## 🚀 Quickstart: Run an Audit in 60 Seconds

You can run an audit on **any** repository or local folder on your machine:

```bash
# 1. Clone AuditSkill
git clone https://github.com/Jooubie/Audit-skill.git ~/Audit-skill
cd ~/Audit-skill

# 2. Launch the interactive bootstrap
./scripts/start-audit.sh
```

The script will prompt for your target codebase, verify git branch isolation (`audit/<date>-baseline`), create an **Obsidian-ready** `audit/` folder, and link the 15-canon Knowledge Graph directly into your project.

### Running with Claude Code

Once initialized, point Claude Code at the target codebase:

```bash
cd /path/to/your/project
claude "Read audit/wiki/index.md and run Phase 1 Codebase Reconnaissance using Haiku / Sonnet for risky code, auth timing, RLS leaks, and architectural coupling. Write Obsidian-formatted findings to audit/findings/AUD-XXX.md."
```

---

## 🧠 Why Coding Agents Fail (And How AuditSkill Fixes Them)

| Common Agent Failure Mode | What Happens Without AuditSkill | How AuditSkill Governs AI Behavior |
|---|---|---|
| **Circular Critique Loops** | Review agents argue endlessly about style preferences without converging. | Replaces multi-turn AI debate with deterministic CI preflight and **exactly one** fresh review pass. |
| **Speculative Over-Refactoring** | Agents rewrite working architectures, introduce complex abstractions, or swap frameworks. | Enforces Ousterhout (*Ref 01*) and Fowler (*Ref 06*): strictly bounded repair tickets; zero gratuitous abstractions. |
| **Hallucinated "Defects"** | Agents invent vulnerabilities based on function names without verifying context. | Every finding requires concrete line numbers, reproducible failure scenarios, and citation of an established canon. |
| **Tenant & Data Leakage** | Agents write queries that forget `tenant_id` or violate double-entry accounting. | Enforces non-negotiable silent invariants: Row-Level Security on all tables, fixed decimal math, append-only ledgers. |
| **Cognitive Blind Spots** | Single model reviews its own output and misses its own bias. | Multi-model division of labor: **Haiku/Sonnet** for scouting, **Opus** for architectural planning, and **Sonnet/Codex** for verification. |

---

## 📚 The 15 Software Engineering Proof Canons

Every finding, review, and remediation ticket is directly anchored in foundational computer science literature:

```
wiki/
├── 00-canon-index-and-conflicts.md     # Master Precedence: Statutory > Standards > Domain > Recency
├── 01-ousterhout-module-depth.md       # A Philosophy of Software Design (Deep vs Shallow Modules)
├── 02-kleppmann-schema-evolution.md    # Designing Data-Intensive Applications (Additive Migrations)
├── 03-kimball-star-schema-retail.md    # The Data Warehouse Toolkit (Dimensional Data Modeling)
├── 04-ddd-bounded-contexts.md          # Domain-Driven Design (Context Boundaries & Aggregate Roots)
├── 05-khorikov-testing-policy.md       # Unit Testing Principles (Test-First Observable Behavior)
├── 06-fowler-refactoring-vocabulary.md # Refactoring: Improving Existing Code (Atomic Refactoring)
├── 07-typescript-conventions.md        # Strict TypeScript (Branded Types, Zero-any, Zod Parsing)
├── 08-pragmatic-principles.md          # The Pragmatic Programmer (DRY, Orthogonality, Contracts)
├── 09-clean-architecture-boundaries.md # Clean Architecture (The Unidirectional Dependency Rule)
├── 10-evolutionary-fitness-functions.md# Building Evolutionary Architectures (Architectural Fitness)
├── 11-nygard-production-stability.md   # Release It! (Circuit Breakers, Timeouts, Fail-Fast)
├── 12-data-engineering-lifecycle.md    # Fundamentals of Data Engineering (Pipelines & Idempotence)
├── 13-postgres-query-performance.md    # Use The Index, Luke! (B-Tree Indexing & Query Tuning)
├── 14-owasp-security-and-supabase-rls.md# OWASP Top 10 & Row-Level Security Enforcement
└── 15-ui-craft-and-wcag22.md           # WCAG 2.2 AA & Modern Responsive UI Craft
```

Read the full knowledge graph overview in [wiki/index.md](./wiki/index.md).

---

## 🗂️ Obsidian-Native Knowledge Architecture

AuditSkill is designed from the ground up to integrate with **Obsidian**:

- **Bi-directional Wikilinks**: Every finding (`[[AUD-001]]`) links directly to its governing canon (`[[14-owasp-security-and-supabase-rls]]`) and implementation ticket (`[[TCK-001]]`).
- **Graph View Exploration**: Open the `audit/` folder in Obsidian to visually explore vulnerability clusters, architectural hotspots, and remediation phases.
- **Structured Metadata**: YAML frontmatter (`type`, `id`, `severity`, `confidence`, `status`, `tags`) enables Obsidian Dataview queries across findings and tickets.

```yaml
---
type: finding
id: AUD-001
severity: High
category: Security
canon: "[[14-owasp-security-and-supabase-rls]]"
tags: [audit, finding, security]
---
```

---

## ⚙️ Automated Preflight & Linting Suite

AuditSkill includes deterministic checkers that execute in milliseconds before and after remediation:

| Tool | Focus | Command / Config |
|---|---|---|
| **TypeScript** | Strict type system integrity | `npx tsc --noEmit` |
| **ESLint 9** | Architectural boundaries & DDD isolation | [configs/eslint.config.mjs](./configs/eslint.config.mjs) |
| **Knip** | Unused exports & dead-code elimination | [configs/knip.json](./configs/knip.json) |
| **Squawk** | Postgres migration lock & safety linter | [configs/squawk.toml](./configs/squawk.toml) |
| **Catalog Audit**| Live Postgres RLS, rules & `search_path` diagnostic | [scripts/audit-supabase-catalog.sql](./scripts/audit-supabase-catalog.sql) |
| **Preflight Runner**| Unified deterministic test runner | [scripts/preflight.sh](./scripts/preflight.sh) |

---

## 🔄 4-Phase Audit Lifecycle

1. **Phase 1: Read-Only Reconnaissance (Haiku / Sonnet)**
   Scans the codebase across 6 structural dimensions. Generates `findings/AUD-XXX.md`. Zero code modifications.
2. **Phase 2: Architectural Synthesis (Opus)**
   Synthesizes findings into bounded tickets (`tickets/TCK-XXX.md`) grouped into sequential phases (`phases/phase-2-plan.md`). Identifies explicit decisions for human sign-off.
3. **Phase 3: Bounded Implementation (Test-First)**
   Each ticket writes a failing test proving the defect before fixing it. Frozen business areas remain completely untouched.
4. **Phase 4: Independent Verification (Single Pass)**
   A fresh reviewer verifies the complete diff and deterministic test output against acceptance criteria. No recursive re-review loops.

---

## 🤝 Contributing & Extending

AuditSkill is modular. You can add company-specific domain rules or compliance frameworks by adding new canon files to `wiki/` and indexing them in `wiki/00-canon-index-and-conflicts.md`.

---

## 📄 License

MIT © [Yousef Mohamed Sayed Diyab (Jooubie)](https://github.com/Jooubie)
