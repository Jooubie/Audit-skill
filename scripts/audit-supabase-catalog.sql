-- ==============================================================================
-- PostgreSQL Live Catalog Audit Script
-- Diagnostic SQL queries for inspecting RLS, rules, search_path, MVs & currency.
-- ==============================================================================

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
    pg_get_expr(p.polqual, p.polrelid) AS policy_qualifier,
    pg_get_expr(p.polwithcheck, p.polrelid) AS with_check_clause
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_policy p ON p.polrelid = c.oid
WHERE c.relkind = 'r'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
ORDER BY rls_enabled ASC, schema_name, table_name;

-- 2. Splinter Rules Audit (pg_rewrite)
SELECT '--- AUDIT: POSTGRES RULES (REWRITE) ---' AS section_header;
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

-- 3. Unsecured Security Definer Routines
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
  )
ORDER BY schema_name, function_name;

-- 4. Exposed Materialized Views
SELECT '--- AUDIT: MATERIALIZED VIEWS ---' AS section_header;
SELECT
    schemaname AS schema_name,
    matviewname AS materialized_view_name,
    matviewowner AS owner,
    hasindexes AS has_indexes,
    ispopulated AS is_populated,
    pg_size_pretty(pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(matviewname))) AS total_size
FROM pg_matviews
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY schemaname, materialized_view_name;

-- 5. Floating Point Currency Columns
SELECT '--- AUDIT: FLOATING POINT MONEY COLUMNS ---' AS section_header;
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

COMMIT;
