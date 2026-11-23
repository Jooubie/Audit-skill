# **Reference 13: Technical Deep Dive into PostgreSQL Query Performance Architecture**

This reference guide synthesizes core principles of PostgreSQL indexing, composite column ordering, covering indexes via the `INCLUDE` clause, and execution mechanics of Row-Level Security (RLS) InitPlan patterns.

# **1\. Foundational Insights: Winand & Dombrovskaya**

Modern PostgreSQL query optimization relies heavily on understanding how data structures map to physical storage and execution plans.

* **Markus Winand ("Use The Index, Luke\!")**: Focuses on the physical mechanics of B-Tree indexes. Winand emphasizes that indexing is an algorithmic optimization rather than a administrative feature. Crucial tenets include preserving sargability (ensuring predicates do not transform indexed columns), understanding index-only scans, and designing multi-column indexes aligned with B-Tree traversal mechanics.  
* **Henrike Dombrovskaya**: Focuses on relational database tuning within complex application architectures and modern Object-Relational Mapping (ORM) frameworks. Her work highlights how abstract data mapping patterns often generate suboptimal SQL, underscoring the necessity of structural index design to compensate for ORM-generated query structures.

# **2\. Composite Index Ordering Dynamics: Equality – Range – Sort**

Designing multi-column B-Tree indexes requires strict adherence to predicate evaluation mechanics to minimize disk I/O and prevent explicit sort operations in the planner.

## **Index Ordering Rules**

1. **Equality Columns First (`=`, `IS NULL`, `IN (single value)`)**: Columns filtered with exact equality must occupy the leading positions of the index. This narrows the B-Tree search path directly to a contiguous block of index pages.  
2. **Sort Columns Second (`ORDER BY`)**: If a query includes explicit sorting, placing sort columns immediately after equality columns allows PostgreSQL to read index entries in pre-sorted order. This eliminates the need for an in-memory or disk-based `Sort` / `Incremental Sort` plan step.  
3. **Range Columns Last (`<`, `>`, `BETWEEN`, `LIKE 'prefix%'`)**: Range predicates break contiguous B-Tree leaf node traversal. Any column placed *after* a range column in an index cannot be used for index-ordered sorting or efficient leaf-node filtering across multiple branches.

## **Composite Index Ordering Matrix**

| Query Pattern | Optimal Index Definition | Plan Execution Behavior |
| :---- | :---- | :---- |
| `WHERE tenant_id = 10 AND status = 'ACTIVE' ORDER BY created_at DESC` | `(tenant_id, status, created_at DESC)` | **Index Scan / IOS**: Direct lookup, zero sorting required. |
| `WHERE tenant_id = 10 AND created_at > '2024-01-01' ORDER BY status` | `(tenant_id, status, created_at)` | **Index Scan \+ Filter**: Equality \+ Sort processed via index order; range filtered inline. |
| `WHERE tenant_id = 10 AND created_at > '2024-01-01' ORDER BY created_at` | `(tenant_id, created_at)` | **Index Scan**: Traverses range directly in sorted physical B-Tree order. |
| Suboptimal: Range before Sort | `(tenant_id, created_at, status)` | **Explicit Sort Required**: Range breaks ordered index walk for `status`. |

# **3\. Covering Indexes and the `INCLUDE` Clause**

Introduced in PostgreSQL 11, the `INCLUDE` clause separates key columns used for index tree structure from payload columns retrieved solely during query execution.

## **Architectural Difference**

* **Key Columns**: Stored in both internal navigation nodes and leaf pages. Used to build B-Tree comparison paths and enforce constraints (such as `UNIQUE`).  
* **Included Columns**: Stored *only* in leaf pages. They do not participate in B-Tree upper-node navigation or uniqueness enforcement.

## **Key Use Cases**

* **Enabling Index-Only Scans (IOS)**: Including extra select list attributes (payloads) in the index allows PostgreSQL to fulfill queries entirely from the index page without hitting table heap pages, provided the Visibility Map (VM) confirms page visibility.  
* **Unique Constraints with Payload**: Enables enforcing uniqueness on key columns while carrying additional non-unique columns for query coverage.

```
-- Example: Unique constraint on user_id while allowing index-only scan for email and status
CREATE UNIQUE INDEX idx_users_account 
ON users (user_id) 
INCLUDE (email, status);
```

## **Benefits Over Standard Multi-Column Indexes**

* **Reduced Index Tree Depth**: Internal non-leaf nodes remain smaller, allowing more index structure to fit into PostgreSQL `shared_buffers`.  
* **Reduced Bloat Risk**: Index modification overhead is reduced because non-key leaf updates do not alter index node ordering.

# **4\. Row-Level Security (RLS) & `InitPlan` Optimization**

Row-Level Security (RLS) automatically rewrites incoming queries by appending security expressions (`USING` policies) into the query tree. Suboptimal policy definitions can lead to severe performance degradation.

## **`InitPlan` vs `SubPlan` Mechanics**

* **`InitPlan` (Optimized Execution)**: When an RLS policy references a static value, session variable (e.g., `current_setting('app.current_tenant')`), or a deterministic/`STABLE` function, the query planner evaluates the expression **once** prior to executing the main query loop. The result is cached for the execution duration.  
* **`SubPlan` (Performance Bottleneck)**: If an RLS policy uses a volatile function or a correlated subquery against another table (e.g., `WHERE tenant_id IN (SELECT tenant_id FROM user_permissions WHERE ...)`), the engine may re-evaluate the security subquery **per candidate row** in the main query, creating an \$N+1\$ execution penalty.

## **RLS Optimization Guidelines**

1. **Use `STABLE` Helper Functions**: Wrap subqueries or complex security logic inside functions marked as `STABLE` or `IMMUTABLE` with `SECURITY DEFINER` privileges. This signals to the planner that the function result is constant for the duration of the query statement, promoting evaluation to an `InitPlan`.  
2. **Session Variable Caching**: Prefer setting application context via local transaction settings (e.g., `SET LOCAL app.current_user_id = '123'`) and reading them in policies using `current_setting()`.  
3. **Ensure Supporting Indexes**: Any column referenced inside an RLS predicate must have matching single or composite indexes to prevent full table scans during policy evaluation.

