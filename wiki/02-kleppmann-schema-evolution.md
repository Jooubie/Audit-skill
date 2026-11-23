# **Reference 02: Kleppmann on Schema Evolution, Idempotency, Zero-Downtime Postgres DDL, and SSI/Locking**

Architectural Reference for Data Systems, Distributed State, and Database Internals

# **1\. Schema Evolution and Compatibility**

In distributed systems, application code deployment and database migrations rarely happen instantaneously across all nodes. Schema evolution requires maintaining dual compatibility between old and new versions of data formats.

## **Compatibility Modes**

| Compatibility Type | Definition | Deployment Order Requirement | Schema Modification Rules |
| :---- | :---- | :---- | :---- |
| **Backward Compatibility** | Newer code can read data written by older code. | Update readers first, then writers. | Can delete existing fields; new fields must have default values. |
| **Forward Compatibility** | Older code can read data written by newer code. | Update writers first, then readers. | Can add new fields; deleted fields must have fallback handling. |
| **Full Compatibility** | Code can bidirectionally read data across schema versions. | Any deployment order (rolling updates). | Only add optional fields; never remove required fields without multi-phase migration. |

## **Encoding Format Nuances**

* **Protocol Buffers / Thrift:** Rely on field tags (integers) rather than field names. Modifying a field tag breaks binary compatibility. Unrecognized tags are preserved during round-trip deserialization in newer specifications to prevent data loss.  
* **Apache Avro:** Uses distinct Writer Schemas and Reader Schemas resolved via schema resolution rules (matching by field name). Avro requires exact schema registration (e.g., via Schema Registry) and does not embed field tags or types inside every encoded record.

---

# **2\. Idempotency and Deterministic State Management**

Idempotency guarantees that executing an operation multiple times produces the exact state transition as executing it once. This is essential for handling network retries, timeouts, and duplicate event delivery in distributed event streams.

## **Key Implementation Patterns**

1. **Unique Idempotency Keys:**  
   * Clients generate a universally unique identifier (UUIDv4) per logical intent and pass it in the request metadata.  
   * Atomic operations insert the request payload into an `idempotency_keys` table inside the target transaction:

```
INSERT INTO idempotency_keys (key, response_payload, created_at)
VALUES ($1, $2, NOW())
ON CONFLICT (key) DO NOTHING;
```

2. **Deterministic Event Processing:**  
   * Pure state transitions where state \$S\_{t+1} \= f(S\_t, E)\$.  
   * Out-of-order and duplicate event handling using monotonically increasing sequence numbers or vector clocks rather than wall-clock timestamps.  
3. **Read-Modify-Write Guards:**  
   * Utilizing conditional writes or optimistic concurrency checks (`UPDATE ... WHERE version = current_version`) to ensure safe retries without side effects.

---

# **3\. Zero-Downtime PostgreSQL DDL Operations**

Executing Schema Definition Language (DDL) operations in PostgreSQL without service disruption requires understanding lock levels, locking queues, and execution mechanics.

## **PostgreSQL Lock Hierarchy Hazards**

PostgreSQL DDL operations acquire explicit table locks. The most restrictive lock, AccessExclusiveLock, blocks all read and write queries (SELECT, INSERT, UPDATE, DELETE).

| Lock Type | Conflicting Locks | Example Operations | Danger Level |
| :---- | :---- | :---- | :---- |
| `AccessShareLock` | `AccessExclusiveLock` | `SELECT` | Low |
| `RowExclusiveLock` | `ExclusiveLock`, `AccessExclusiveLock` | `INSERT`, `UPDATE`, `DELETE` | Low |
| `ShareLock` | `RowExclusive`, `AccessExclusive` | `CREATE INDEX` (non-concurrent) | High (Blocks writes) |
| `AccessExclusiveLock` | All Lock Types | `ALTER TABLE`, `DROP TABLE`, `VACUUM FULL` | Critical (Blocks all traffic) |

* **Lock Queue Blocking:** If a long-running query holds an `AccessShareLock`, an `ALTER TABLE` statement queued behind it will block subsequent `SELECT` queries, creating an immediate connection exhaustion cascade.

## **Safe Migration Patterns**

### **Index Creation**

Never run bare `CREATE INDEX`. Use `CONCURRENTLY` to acquire only `ShareUpdateExclusiveLock`, allowing concurrent reads and writes.l  
\-- SAFE: Non-blocking index creation  
CREATE INDEX CONCURRENTLY idx\_users\_email ON users(email);

````

#### Adding Columns with Default Values
* **PostgreSQL 11+:** Adding a column with a constant default value is an $O(1)$ operation that updates metadata only, without rewriting the table.
* **PostgreSQL < 11:** Adding a default rewrites the whole table while holding an `AccessExclusiveLock`. Break down into: add nullable column $\rightarrow$ backfill in batches $\rightarrow$ set default.

#### Constraints Enforcement
Adding a Foreign Key or Check Constraint requires scanning the whole table under an exclusive lock. Mitigate using `NOT VALID`:

```sql
-- Step 1: Acquire short lock, do not validate existing rows
ALTER TABLE orders 
  ADD CONSTRAINT fk_user 
  FOREIGN KEY (user_id) REFERENCES users(id) NOT VALID;

-- Step 2: Validate existing rows concurrently without blocking writes
ALTER TABLE orders 
  VALIDATE CONSTRAINT fk_user;
````

---

# **4\. Serializable Snapshot Isolation (SSI) and Concurrency Control**

Serializable Snapshot Isolation (SSI) provides true serializability without the performance overhead of traditional two-phase locking (2PL).

## **Isolation Comparison**

```
+-----------------------------------------------------------------------+
|                       Two-Phase Locking (2PL)                         |
|   Pessimistic: Readers block Writers, Writers block Readers/Writers   |
+-----------------------------------------------------------------------+
                                   vs
+-----------------------------------------------------------------------+
|             Serializable Snapshot Isolation (SSI)                     |
|   Optimistic: Reads and Writes do not block each other                |
|   Detects dangerous dependencies dynamically; aborts on conflict      |
+-----------------------------------------------------------------------+
```

## **Anomaly Prevention Dynamics**

1. **Write Skew Detection:**  
   * Write Skew occurs when two concurrent transactions read overlapping data sets, make decisions based on those readings, and update non-overlapping data sets that violate a cross-row invariant.  
   * **Example:** Two doctors on call both request leave simultaneously. The invariant states at least one doctor must remain. Under `REPEATABLE READ`, both observe count \$= 2\$ and both successfully update their status to inactive, leaving 0 doctors.  
   * SSI tracks read-write lock dependencies (`SIREAD` locks) in an in-memory dependency graph. When a cycle of rw-antidependencies is detected (\$T\_1 \\xrightarrow{rw} T\_2 \\xrightarrow{rw} T\_1\$), the database engine aborts one of the transactions with a `40001` serialization failure.  
2. **Phantom Reads:**  
   * Prevented in SSI by establishing predicate locks (or index-page tracking in Postgres) that track queries filtering over a range of tuples, ensuring concurrent inserts into that range trigger conflict aborts.  
3. **Performance Trade-offs:**  
   * **2PL:** High query latency, potential for deadlocks under heavy read-write concurrency.  
   * **SSI:** Zero read-lock overhead; higher rate of transaction aborts under intense write contention requiring client retry loops.

