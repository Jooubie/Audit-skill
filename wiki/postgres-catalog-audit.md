# **PostgreSQL Live Catalog Audit Script**

Diagnostic SQL queries for inspecting Row Level Security (RLS), custom rules, `search_path` configurations, exposed materialized views, and precision risk in currency storage.

| Audit Parameter | Metadata / Details |
| :---- | :---- |
| Target Environment | Live PostgreSQL Catalog Audit |
| Prepared By | Person |
| Audit Execution Date | Date |
| Target Database | Live Operational Catalog |

# **Audit Overview**

This diagnostic suite interrogates internal PostgreSQL system catalogs (pg\_class, pg\_rewrite, pg\_policy, pg\_proc, pg\_matviews, and information\_schema) to surface security vulnerabilities, configuration anomalies, and data integrity anti-patterns.

| Target Component | Inspection Goal | Risk Mitigation |
| :---- | :---- | :---- |
| **Row Level Security** | Missing RLS policies or tables with RLS disabled | Unintended tenant data leakage |
| **Rewrite Rules** | Non-standard or "splinter" `CREATE RULE` definitions | Hidden query side-effects and unintended mutation behavior |
| **Search Path** | Ambient `search_path` & unsecured `SECURITY DEFINER` routines | Schema-hijacking and privilege escalation vulnerabilities |
| **Materialized Views** | Unprotected MVs exposed across schemas | Stale or unauthorized exposure of aggregated sensitive data |
| **Floating Point Money** | Usage of `float4`/`float8` for financial data | Precision loss, rounding errors, and accounting discrepancies |

# **Section 1: Row Level Security (RLS) Inspection**

Row Level Security enforces granular access controls. This query highlights:

* Tables with RLS completely disabled in non-system schemas.  
* Tables with RLS enabled but possessing zero active policies.  
* Full enumeration of active RLS policies and applied expressions.

```
SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    c.relrowsecurity AS rls_enabled,
    c.relforcerowsecurity AS rls_forced,
    COALESCE(p.polname, '--- NO POLICY ---') AS policy_name,
    p.polcmd AS command_type,
    pg_get_expr(p.polqual, p.polrelid) AS policy_qualifier,
    pg_get_expr(p.polwithcheck, p.polrelid) AS with_check_clause
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_policy p ON p.polrelid = c.oid
WHERE c.relkind = 'r'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
ORDER BY rls_enabled ASC, schema_name, table_name;
```

# **Section 2: Splinter Rules Audit (`pg_rewrite`)**

Postgres rules (`CREATE RULE`) rewrite the query tree prior to execution. Custom rules (excluding default view `_RETURN` rules) can inject hidden behavior or lead to double-execution bugs ("splinter rules").

```
SELECT
    n.nspname AS schema_name,
    c.relname AS relation_name,
    r.rulename AS rule_name,
    CASE r.ev_type
        WHEN '1' THEN 'SELECT'
        WHEN '2' THEN 'UPDATE'
        WHEN '3' THEN 'INSERT'
        WHEN '4' THEN 'DELETE'
    END AS target_event,
    r.is_instead AS is_instead_rule,
    pg_get_ruledef(r.oid) AS rule_definition
FROM pg_rewrite r
JOIN pg_class c ON c.oid = r.ev_class
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND r.rulename <> '_RETURN'
ORDER BY schema_name, relation_name, rule_name;
```

# **Section 3: `search_path` Security & Privilege Escalation Audit**

Unbounded or mutable `search_path` configurations allow low-privileged users to shadow system functions or tables. This audit inspects:

1. Global and role-specific `search_path` configurations.  
2. `SECURITY DEFINER` functions lacking an explicit `SET search_path`.

```
-- Query 3A: Role and Database level search_path settings
SELECT
    'Database Default' AS scope,
    d.datname AS target_entity,
    s.setconfig AS configured_settings
FROM pg_db_role_setting s
JOIN pg_database d ON d.oid = s.setdatabase
WHERE s.setrole = 0 AND s.setconfig::text LIKE '%search_path%'

UNION ALL

SELECT
    'Role Setting' AS scope,
    r.rolname AS target_entity,
    s.setconfig AS configured_settings
FROM pg_db_role_setting s
JOIN pg_roles r ON r.oid = s.setrole
WHERE s.setconfig::text LIKE '%search_path%';

-- Query 3B: SECURITY DEFINER routines vulnerable to schema hijacking
SELECT
    n.nspname AS schema_name,
    p.proname AS function_name,
    pg_get_function_identity_arguments(p.oid) AS argument_signature,
    p.prosecdef AS is_security_definer,
    COALESCE(ARRAY_TO_STRING(p.proconfig, ', '), 'VULNERABLE: No setting applied') AS active_settings
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND p.prosecdef = TRUE
  AND (
    p.proconfig IS NULL
    OR NOT (ARRAY_TO_STRING(p.proconfig, ',') LIKE '%search_path=%')
  )
ORDER BY schema_name, function_name;
```

# **Section 4: Exposed Materialized Views Audit**

Materialized views cache query results physically. Unrestricted public schemas or missing permissions can expose stale or sensitive operational data.

```
SELECT
    schemaname AS schema_name,
    matviewname AS materialized_view_name,
    matviewowner AS owner_role,
    hasindexes AS has_indexes,
    ispopulated AS is_populated,
    pg_size_pretty(pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(matviewname))) AS total_size
FROM pg_matviews
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY schemaname, materialized_view_name;
```

# **Section 5: Floating Point Currency Inspection**

Storing monetary values using approximate floating-point data types (`real`, `double precision`, `float4`, `float8`) leads to cumulative IEEE 754 precision errors. Financial values must use exact numeric types (`numeric` / `decimal`) or integer cents.

```
SELECT
    table_schema,
    table_name,
    column_name,
    data_type,
    udt_name
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
  AND data_type IN ('real', 'double precision', 'float4', 'float8')
  AND column_name ~* '(price|cost|amount|balance|total|fee|money|cash|tax|val|salary|credit|debit|revenue|margin)'
ORDER BY table_schema, table_name, column_name;
```

# **Section 6: Unified Master Catalog Audit Script**

Run this consolidated SQL script in a single transaction to execute all audit modules sequentially and emit structured diagnostic result sets.

```
BEGIN;

-- 1. Row Level Security Audit
SELECT '--- AUDIT: ROW LEVEL SECURITY ---' AS section_header;
SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    c.relrowsecurity AS rls_enabled,
    c.relforcerowsecurity AS rls_forced,
    COALESCE(p.polname, '--- NO POLICY ---') AS policy_name,
    p.polcmd AS command_type,
    pg_get_expr(p.polqual, p.polrelid) AS policy_qualifier
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_policy p ON p.polrelid = c.oid
WHERE c.relkind = 'r'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
ORDER BY rls_enabled ASC, schema_name, table_name;

-- 2. Splinter Rules Audit
SELECT '--- AUDIT: POSTGRES RULES (REWRITE) ---' AS section_header;
SELECT
    n.nspname AS schema_name,
    c.relname AS relation_name,
    r.rulename AS rule_name,
    r.is_instead AS is_instead_rule,
    pg_get_ruledef(r.oid) AS rule_definition
FROM pg_rewrite r
JOIN pg_class c ON c.oid = r.ev_class
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND r.rulename <> '_RETURN'
ORDER BY schema_name, relation_name;

-- 3. Unsecured Security Definer Functions
SELECT '--- AUDIT: UNSECURED SECURITY DEFINER ROUTINES ---' AS section_header;
SELECT
    n.nspname AS schema_name,
    p.proname AS function_name,
    pg_get_function_identity_arguments(p.oid) AS arguments,
    COALESCE(ARRAY_TO_STRING(p.proconfig, ', '), 'VULNERABLE: Missing search_path') AS settings
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND p.prosecdef = TRUE
  AND (
    p.proconfig IS NULL
    OR NOT (ARRAY_TO_STRING(p.proconfig, ',') LIKE '%search_path=%')
  );

-- 4. Exposed Materialized Views
SELECT '--- AUDIT: MATERIALIZED VIEWS ---' AS section_header;
SELECT
    schemaname AS schema_name,
    matviewname AS materialized_view_name,
    matviewowner AS owner,
    ispopulated AS is_populated
FROM pg_matviews
WHERE schemaname NOT IN ('pg_catalog', 'information_schema');

-- 5. Floating Point Currency Columns
SELECT '--- AUDIT: FLOATING POINT MONEY COLUMNS ---' AS section_header;
SELECT
    table_schema,
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
  AND data_type IN ('real', 'double precision', 'float4', 'float8')
  AND column_name ~* '(price|cost|amount|balance|total|fee|money|cash|tax|val|salary|credit|debit|revenue|margin)';

COMMIT;
```

