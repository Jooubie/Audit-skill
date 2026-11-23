# **Reference 14: Technical Security Implementation Standards**

# **Secure Architecture, Next.js Hardening, Supabase RLS, Archive Protection, & Data Neutralization**

## **Document Metadata**

* **Document Version**: 14.0-RELEASE  
* **Effective Date**: Date  
* **Lead Architect**: Person  
* **Target Audience**: Application Security Engineers & Senior Developers

# **1\. OWASP ASVS 5.0 Standard Guidelines**

The OWASP Application Security Verification Standard (ASVS) Version 5.0 provides a functional baseline for designing, building, and testing modern web applications and APIs.

# **Verification Levels**

* **Level 1 (Opportunistic)**: Minimal baseline for all web applications. Focuses on security controls that are fully verifiable through automated analysis or low-overhead manual verification.  
* **Level 2 (Standard)**: Required baseline for applications handling sensitive business operations, personal data (PII), or financial transactions. Focuses on enforcing defense-in-depth and architectural isolation.  
* **Level 3 (Advanced)**: Mandated for high-assurance applications in critical infrastructure, medical technology, or high-value financial networks. Requires deep verification of architecture, state management, and cryptographic integrity.

# **Key Focus Areas**

* **Architecture & API Integration**: Enforce secure trust boundaries, explicit schema validation at service boundaries, and mutual TLS/token verification between microservices.  
* **Authentication & Session Management**: Mandate multi-factor authentication resilient to adversary-in-the-middle attacks, eliminate static session identifiers, and enforce strict binding of OAuth 2.0 dynamic tokens.  
* **Validation & Encoding**: Mandate context-aware output encoding at the browser boundary rather than relying exclusively on input filter sanitization.

# **2\. Next.js Security Cheat Sheet**

Modern React frameworks like Next.js require clear architectural boundaries between Server Components, Server Actions, Client Components, and Edge Middleware.

# **Server Actions & Server Components**

* **Public Endpoint Warning**: Every function tagged with `'use server'` is compiled into a publicly reachable HTTP POST endpoint. Never treat Server Actions as private internal functions.  
* **Input Schema Validation**: Validate every parameter passed into a Server Action using strong schema validation libraries (e.g., Zod) prior to database or file operations.  
* **In-Function Authorization Checks**: Perform session verification and role-based access checks directly inside the body of each Server Action. Do not rely solely on middleware or page-level routing guards.

# **Environment Variable Exposure**

* **Server-Only Credentials**: Keep secret keys (such as `DATABASE_URL` or `API_SECRET`) un-prefixed. Import the `server-only` package in modules handling sensitive credentials to trigger build-time errors if imported client-side.  
* **Public Identifiers**: Limit variables prefixed with `NEXT_PUBLIC_` strictly to non-sensitive values, such as public API hostnames or public feature flags.

# **HTTP Security Headers Configuration**

Configure baseline security headers in `next.config.js`:

* **Content-Security-Policy**: Enforce strict script sources (`script-src 'self'`) and disallow dynamic inline execution.  
* **X-Frame-Options**: Set to `DENY` or `SAMEORIGIN` to mitigate clickjacking.  
* **Strict-Transport-Security**: Enforce `max-age=63072000; includeSubDomains; preload`.  
* **X-Content-Type-Options**: Set to `nosniff`.  
* **Referrer-Policy**: Enforce `strict-origin-when-cross-origin`.

# **3\. Supabase Row Level Security (RLS)**

PostgreSQL Row Level Security (RLS) provides tenant data isolation at the database layer. Application-level filtering alone is insufficient to prevent cross-tenant data leaks.

# **Mandatory RLS Activation**

Activate RLS explicitly on all public schema tables during initial migration:

* Enforce statement: `ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;`  
* Force application statement: `ALTER TABLE table_name FORCE ROW LEVEL SECURITY;`

# **Policy Design & Execution Context**

* **Direct User Binding**: Bind table access directly to the authenticated user ID: `auth.uid() = user_id`.  
* **Tenant Claim Parsing**: Extract tenant scopes directly from the JWT context: `(auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid = tenant_id`.  
* **Operation Separation**: Define explicit, separate policies for `SELECT`, `INSERT`, `UPDATE`, and `DELETE` operations instead of using generic `ALL` rules.

# **Critical Caveats**

* **Service Role Key Hazards**: The Supabase `service_role` key completely bypasses RLS rules. Never expose this key in client-side code, public repositories, or client-accessible environment variables.  
* **SECURITY DEFINER Functions**: Database functions marked as `SECURITY DEFINER` run with full privileges of the function creator (typically `postgres`). Default to `SECURITY INVOKER` or manually enforce `auth.uid()` checks inside the function body.

# **4\. Zip-Bomb & Decompression Limits**

Uncontrolled archive extraction exposes application servers to Denial of Service (DoS) attacks via disk space exhaustion, high CPU utilization, or memory saturation.

# **Defensive Threshold Specifications**

| Metric Dimension | Maximum Allowed Threshold | Defensive Action |
| :---- | :---- | :---- |
| Compression Ratio | 100 : 1 | Abort extraction immediately if uncompressed/compressed ratio exceeds ceiling |
| Single File Size | 500 MB | Terminate stream if individual payload exceeds size limit |
| Total Aggregate Output | 2 GB | Terminate archive processing job across all extracted files |
| Nested Archive Depth | 2 Levels | Reject recursively nested archives (e.g., zip inside zip) |
| Total Entry Count | 10,000 Entries | Stop processing if entry header count exceeds maximum threshold |

# **Safe Streaming Implementation**

* **Chunked Stream Extraction**: Decompress data using chunked streams rather than buffering entire archives in RAM.  
* **Active Byte Tracking**: Maintain an active counter of bytes written during extraction. Abort stream processing immediately if any limit is reached.  
* **Avoid Header Reliance**: Do not trust central header data for file sizes, as headers can be easily spoofed by malicious archives.

# **5\. CSV Injection Neutralization**

CSV Injection (Formula Injection) occurs when untrusted user inputs are exported into tabular formats (e.g., `.csv`, `.tsv`) and subsequently executed as active code by spreadsheet software like Microsoft Excel, LibreOffice, or Google Sheets.

# **Vulnerable Formula Prefixes**

Any input field beginning with the following characters can trigger remote formula execution or data exfiltration:

* Equals sign (`=`)  
* Plus sign (`+`)  
* Minus sign (`-`)  
* At sign (`@`)  
* Tab character (`0x09` / `\t`)  
* Carriage return (`0x0D` / `\r`)

# **Neutralization Standard Rules**

1. **Prepend Single Quote**: Prepend a single quote (`'`) to any cell string that starts with a vulnerable prefix character. This forces spreadsheet engines to evaluate the string strictly as literal text.  
2. **Double Quote Wrapping**: Enclose all exported CSV cells in double quotation marks (`"`), escaping any existing double quotes by doubling them (`""`).  
3. **Strip Leading Control Characters**: Strip leading whitespace, tabs, and carriage returns prior to prefix verification.

# **CSV Sanitization Reference Table**

| Raw Input Payload | Attack Risk Vector | Neutralized CSV Output |
| :---- | :---- | :---- |
| `=HYPERLINK("http://attacker.com", "Exfil")` | Phishing / Data Exfiltration | `"'=HYPERLINK(""http://attacker.com"", ""Exfil"")"` |
| `@SUM(1+1)*cmd|' /C calc'!A0` | Dynamic Command Execution | `"'@SUM(1+1)*cmd|' /C calc'!A0"` |
| `+1000` | Unintended Formula Evaluation | `"'+1000"` |
| `\t=2+3` | Obfuscated Prefix Injection | `"'=2+3"` |

