# [AUD-XXX] Short Finding Title

- **Finding ID**: AUD-XXX
- **Severity**: Critical | High | Medium | Low | Informational
- **Confidence**: High | Medium | Low
- **Category**: Architecture | Security | Database | Performance | Reliability | Code Quality
- **Location**: `path/to/file.ext` (Line XX-YY) or System Component

---

## 1. Description & Evidence
Explain what was found with exact references and supporting code snippets, log extracts, or query plans.

```typescript
// Insert problematic code or evidence snippet here
```

---

## 2. Actual or Credible Failure Scenario
Describe concretely how this issue manifests under real-world runtime conditions, traffic spikes, or adversarial inputs.

---

## 3. Technical & Business Impact
- **Technical Impact**: (e.g., Memory leak, unhandled promise rejection, race condition, data loss)
- **Business Impact**: (e.g., Revenue discrepancy, customer checkout failure, unauthorized data access, regulatory risk)

---

## 4. Proposed Correction
Concrete, minimal, and bounded remediation plan. Prefer fixing existing patterns over introducing new libraries or broad refactors.

---

## 5. Verification Criteria
How will we deterministically verify that the issue is resolved without regression?
- [ ] Unit or integration test covering the failure scenario
- [ ] Static type check / linting pass
- [ ] Runtime smoke test or verification query
