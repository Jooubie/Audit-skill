---
type: finding
id: AUD-XXX
title: "Short Finding Title"
severity: Critical | High | Medium | Low | Informational
confidence: High | Medium | Low
category: Architecture | Security | Database | Performance | Reliability | Code Quality
status: open
canon: "[[00-canon-index-and-conflicts]]"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - audit
  - finding
  - security
---

# [[AUD-XXX]]: Short Finding Title

- **Finding ID**: AUD-XXX
- **Severity**: Critical | High | Medium | Low | Informational
- **Confidence**: High | Medium | Low
- **Category**: Architecture | Security | Database | Performance | Reliability | Code Quality
- **Governing Canon**: [[00-canon-index-and-conflicts]]
- **Location**: `path/to/file.ext` (Line XX-YY)

---

## 1. Description & Evidence
Explain what was found with exact references and supporting code snippets, log extracts, or query plans.

```typescript
// Insert problematic code or evidence snippet here
```

---

## 2. Actual or Credible Failure Scenario
Describe concretely how this issue manifests under real-world runtime conditions, traffic spikes, or adversarial inputs per [[11-nygard-production-stability]].

---

## 3. Technical & Business Impact
- **Technical Impact**: (e.g., Memory leak, unhandled promise rejection, race condition, data loss)
- **Business Impact**: (e.g., Revenue discrepancy, customer checkout failure, unauthorized data access)

---

## 4. Proposed Correction
Concrete, minimal, and bounded remediation plan. Prefer repairing existing patterns over introducing new libraries per [[01-ousterhout-module-depth]] and [[06-fowler-refactoring-vocabulary]].

---

## 5. Verification Criteria
How will we deterministically verify that the issue is resolved without regression?
- [ ] Unit or integration test covering the failure scenario per [[05-khorikov-testing-policy]]
- [ ] Static type check / linting pass (`scripts/preflight.sh`)
- [ ] Runtime smoke test or verification query
