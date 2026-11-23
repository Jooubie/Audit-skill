# **Reference 05: Engineering Policy on Software & Database Testing Architectural Standards**

This document establishes the official engineering policy for testing standards across application services, database infrastructure, and domain logic. It codifies the principles of Vladimir Khorikov, Kent C. Dodds, real-database integration paradigms, pgTAP Row-Level Security (RLS) testing, and property-based validation.

# **1\. Khorikov’s Four Pillars of a Good Unit Test**

Following Vladimir Khorikov’s framework, every automated test suite must be evaluated against four fundamental attributes. A test suite fails if it maximizes one attribute at the expense of non-negotiable stability.

* **Protection Against Regressions:** The degree to which a test can catch bugs introduced during code modifications. Dependent on code complexity, domain significance, and amount of executed code.  
* **Resistance to Refactoring:** The degree to which a test can pass after code refactoring without false positives. Tests tied to implementation details produce false alarms and degrade trust in the CI pipeline.  
* **Fast Feedback:** The speed at which tests execute. Faster tests encourage frequent execution and rapid iteration loops.  
* **Maintainability:** The effort required to read, understand, and update the test code, driven by test size and state configuration complexity.

## **The Trade-Off Paradox**

It is mathematically impossible to maximize all four pillars simultaneously. Resistance to refactoring is binary (a test either couples to implementation or it does not), whereas Protection against Regressions and Fast Feedback exist in direct conflict when choosing between Unit, Integration, and End-to-End scopes.

| Pillar / Trade-off | Unit Tests | Integration Tests | End-to-End Tests |
| :---- | :---- | :---- | :---- |
| Protection Against Regressions | Low to Moderate | High | Maximum |
| Resistance to Refactoring | High (if black-box) | High | Maximum |
| Fast Feedback | Extremely High | Moderate | Low |
| Maintainability | High | Moderate | Low (flaky, complex setup) |

# **2\. Dodds’ Testing Philosophy & The Testing Trophy**

Kent C. Dodds’ testing framework focuses on user behavior and real-world confidence: *"The more your tests resemble the way your software is used, the more confidence they can give you."*

## **The Testing Trophy Structure**

* **Static Analysis:** TypeScript, ESLint, type-checking. Catches typos, invalid calls, and syntax errors at build time.  
* **Unit Tests:** Verifies pure functions, complex algorithms, and isolated domain entities.  
* **Integration Tests:** **The Primary Focus.** Tests how modules work together, including interactions with databases and external boundaries. Offers the highest ROI (return on investment) regarding confidence vs speed.  
* **End-to-End (E2E) Tests:** Validates critical core user paths end-to-end. Kept lean to prevent CI bottlenecking and test flakiness.

## **Operational Mandate: Integration over Mocking**

Unit testing implementation details (e.g., asserting internal method invocations or private class state) is strictly prohibited. Tests must interact with the application strictly through public API contracts or user interactions.

# **3\. Database Testing Strategy: Mocks vs. Real Postgres**

Mocks and in-memory substitutes (such as SQLite) mask dialect incompatibilities, trigger bugs, transaction race conditions, and query performance anomalies.

## **Why Database Mocks Fail**

1. **Dialect Drift:** In-memory databases do not support PostgreSQL-specific features like JSONB operators (`@>`, `->>`), CTEs, window functions, generated columns, custom types, or Row-Level Security.  
2. **False Confidence:** Mocks record assumptions about SQL behavior, not actual database execution.

## **Policy Matrix for Database Testing**

| Requirement | Mocked Driver / ORM | In-Memory SQLite | Ephemeral Real Postgres (Docker/Testcontainers) |
| :---- | :---- | :---- | :---- |
| Dialect Fidelity | None | Low | Complete (100%) |
| Tests RLS Policies | No | No | Yes |
| Constraint Check Validation | No | Partial | Yes |
| Execution Speed | Sub-millisecond | Millisecond | Fast (via transactional rollback or RAM-disk) |
| Recommended Use | Never for DB logic | Never for Postgres apps | Required standard for DB integration |

## **Isolation Standard: Transaction Rollbacks**

Integration tests against real PostgreSQL instances must wrap each test execution in a single SQL transaction and issue a `ROLLBACK` at completion, preserving test speed without residual state contamination.

# **4\. PostgreSQL Native Testing with pgTAP & RLS**

When business logic or security assertions live inside PostgreSQL (functions, triggers, views, and Row-Level Security policies), tests must run directly within the database engine using pgTAP.

## **Row-Level Security (RLS) Verification**

Security rules enforced via CREATE POLICY must be exhaustively tested against various role permissions and tenant contexts.

```
BEGIN;

SELECT plan(4);

-- 1. Setup Test Fixtures & Tenant Roles
SET LOCAL ROLE tenant_user_a;
SET LOCAL "request.jwt.claim.sub" = 'usr_01H8XB123';

-- 2. Verify Insert Rights within Tenant Scope
SELECT lives_ok(
    $$ INSERT INTO orders (id, user_id, amount) VALUES ('ord_1', 'usr_01H8XB123', 99.50) $$,
    'User can insert orders under their own ID'
);

-- 3. Verify Isolation across Tenant Boundaries
SET LOCAL ROLE tenant_user_b;
SET LOCAL "request.jwt.claim.sub" = 'usr_02Y9ZC456';

SELECT is_empty(
    $$ SELECT * FROM orders WHERE id = 'ord_1' $$,
    'Tenant B cannot view orders owned by Tenant A'
);

-- 4. Verify Administrative Bypass Policies
SET LOCAL ROLE system_admin;

SELECT results_eq(
    $$ SELECT COUNT(*)::INTEGER FROM orders WHERE id = 'ord_1' $$,
    ARRAY[1],
    'Admin role bypasses RLS filters correctly'
);

SELECT * FROM finish();
ROLLBACK;
```

# **5\. Property-Based Testing Paradigm**

Example-based testing only validates scenarios that developers explicitly anticipate. Property-Based Testing (PBT) generates hundreds of randomized inputs against fixed structural invariants to discover edge cases, parser crashes, and state corruption.

## **Core Principles of Property Testing**

1. **Invariants:** Properties that must remain true for every valid input (e.g., `decode(encode(data)) == data`).  
2. **Generators:** Arbitrary data generators tailored to domain bounds (e.g., non-empty strings, positive decimals, valid UUIDs).  
3. **Shrinking:** When a failure occurs, the engine automatically shrinks the failing input to the smallest reproducible minimal example.

## **Application Rules**

* **Domain Models:** Required for pricing calculations, discount engines, currency conversions, state transitions, and data sanitization routines.  
* **Database Invariants:** Use PBT to test constraint resilience, ensuring arbitrary payloads cannot breach domain constraints or throw unhandled DB errors.

# **6\. Summary of Compliance Requirements**

* **Coverage Target:** Require high branch coverage on core domain models via unit tests and PBT; require high integration coverage on all database queries using real Postgres.  
* **Database Tests:** Zero tolerance for SQL mocking drivers. All DB interaction tests must execute against actual PostgreSQL instances using Testcontainers or dedicated ephemeral test schemas.  
* **Security Enforcement:** Every modified or newly introduced RLS policy must include a corresponding `.sql` pgTAP test suite verifying read, write, update, and deletion isolation across roles.

