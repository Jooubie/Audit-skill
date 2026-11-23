---
type: phase
phase_id: "Phase-X"
name: "Phase Name"
status: planned
approval_status: pending
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - audit
  - phase
  - roadmap
---

# Phase State: [[Phase-X]] - Phase Name

- **Phase**: Phase X
- **Status**: Planned | In-Progress | Under-Review | Verified | Blocked | Complete
- **Last Updated**: YYYY-MM-DDTHH:MM:SSZ
- **Operator Approval**: Pending | Approved (Sign-off: Joubie)

---

## 1. Scope & Goals
Brief summary of what this phase covers and what it explicitly excludes per [[00-canon-index-and-conflicts]].

---

## 2. Included Tickets
| Ticket ID | Title | Assignee | Status |
|---|---|---|---|
| [[TCK-001]] | Add RLS policies to webhook_events | Claude Sonnet | Complete |
| [[TCK-002]] | Timing-safe auth verification | Claude Sonnet | In-Progress |

---

## 3. Changed Files & Diffs
List of files modified in this phase:
- `path/to/file1.ts`
- `path/to/file2.ts`

---

## 4. Verification Evidence
Deterministic proof of correctness:
- **Preflight Suite**: `./scripts/preflight.sh` (Exit code: 0)
- **Automated Tests**: `npm test` per [[05-khorikov-testing-policy]]
- **Independent AI Review**: Reviewer: Claude Sonnet, Result: [Pass/Fail]
- **Evidence Log**:
  ```
  Paste test run or verification output here
  ```

---

## 5. Blockers & Risks
Document any unexpected findings, regressions, or blockers.

---

## 6. Next Action
Next concrete action step for this phase.
