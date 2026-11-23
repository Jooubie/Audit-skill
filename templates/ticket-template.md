---
type: ticket
id: TCK-XXX
title: "Ticket Title"
finding: "[[AUD-XXX]]"
phase: "[[phase-2-plan]]"
status: draft
priority: P1 | P2 | P3
assigned_agent: "Claude Sonnet | Claude Opus | Gemini | Codex"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - audit
  - ticket
  - remediation
---

# [[TCK-XXX]]: Ticket Title

- **Ticket ID**: TCK-XXX
- **Related Finding**: [[AUD-XXX]]
- **Implementation Phase**: [[phase-2-plan]]
- **Status**: Draft | Approved | In-Progress | Verified | Closed
- **Assigned Agent**: Claude Sonnet | Claude Opus | Gemini | Codex

---

## 1. Problem Definition
Summary of the defect or vulnerability to be addressed per [[AUD-XXX]].

---

## 2. Expected Outcome
The desired state once this ticket is implemented.

---

## 3. Affected Files & Services
- `src/path/to/fileA.ts`
- `src/path/to/fileB.ts`
- `supabase/migrations/2026XXXXXXXX_migration_name.sql`

---

## 4. Acceptance Criteria
- [ ] 1. Bounded fix implemented adhering strictly to existing conventions.
- [ ] 2. No modification of unrelated files or architectural patterns ([[01-ousterhout-module-depth]]).
- [ ] 3. Backwards compatibility and financial calculations preserved ([[02-kleppmann-schema-evolution]]).

---

## 5. Regression Test Specification
Deterministic test case proving the bug is fixed and preventing recurrence per [[05-khorikov-testing-policy]]:
- Test path: `tests/...`
- Expected assertion:

---

## 6. Risks & Rollback Requirements
- **Risk Assessment**: Low | Medium | High
- **Rollback Procedure**: (e.g., Git revert commit SHA, rollback database migration step)
