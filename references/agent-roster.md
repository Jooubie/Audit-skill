# Agent Roster & Responsibilities

This matrix maps engineering audit tasks to specific agent roles and model families to ensure diversity of perspectives and avoid blind spots.

| Task / Job | Assigned Agent | Primary Model | Scope & Deliverable |
|---|---|---|---|
| **Codebase Reconnaissance** | Audit Scout | Claude Haiku / Sonnet | Broad codebase mapping, file tree analysis, dependency graphing, initial issue spotting. |
| **Architecture & Repair Plan** | Lead Architect | Claude Opus | Synthesizing findings, designing bounded fixes, writing phase tickets, estimating risks. |
| **Bounded Code Fixes** | Implementation Specialist | Agy / Gemini | Test-driven implementation of bounded bug fixes, typing fixes, schema adjustments. |
| **Docker & Runtime Audit** | Infrastructure Auditor | Claude + Docker Tools | Container build efficiency, layer caching, Dockerfile security, compose runtime posture. |
| **Static Security Analysis** | Security Auditor | Trail of Bits Tools / Linters | AST scans, secret leakage, dependency vulnerabilities, auth and access boundary checks. |
| **Independent Verification** | Independent Reviewer | Codex / Fresh Subagent | Read-only phase review checking diffs against acceptance criteria without inherited bias. |
| **Final Review & Release Gate** | Chief Auditor + Operator | Claude Opus + Operator (Jou) | Final release validation, operator sign-off, live verification, smoke test confirmation. |

---

## Hand-off Rules

1. **Scout to Architect**:
   - Scout files raw findings conforming to `finding-template.md`.
   - No code modifications are permitted during scouting.

2. **Architect to Implementation**:
   - Architect structures findings into sequential phases and tickets (`ticket-template.md`).
   - Every ticket must define acceptance criteria, affected files, and test requirements.
   - Operator (Jou) must approve the plan before execution begins.

3. **Implementation to Independent Review**:
   - Implementation agent delivers a clean git diff with passing local tests.
   - The Independent Reviewer inspects the diff once.
   - Circular review loops (e.g. multiple back-and-forth review iterations without user intervention) are strictly prohibited.

4. **Review to Release**:
   - High or Critical severity findings block release.
   - Minor observations are logged as follow-up items.
   - Release requires operator's explicit `deploy` confirmation in the active session.
