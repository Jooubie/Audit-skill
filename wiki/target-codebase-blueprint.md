# **Section 5: Canonical Target Codebase Blueprint**

This section establishes the architectural target state for the Next.js 16 application platform. It defines file system topology, server/client communication patterns, data flow mechanisms, and standardized npm script orchestrations.

# **5.1 Canonical Repository Layout**

The codebase follows a domain-driven, feature-grouped structure optimized for Next.js 16 App Router specifications. Server and Client boundaries are explicitly isolated to prevent accidental hydration leaks and ensure strict security practices.

```
/
├── .github/                    # CI/CD Workflows, issue templates, and action definitions
├── public/                     # Static assets (fonts, SVGs, manifest, favicon)
├── src/
│   ├── app/                    # Next.js App Router (Routes, Layouts, Pages, Handlers)
│   │   ├── (auth)/             # Route group: Authentication (Login, Register, Reset)
│   │   ├── (dashboard)/        # Route group: Authenticated Application Console
│   │   │   ├── analytics/      # Sub-route: Analytics dashboard
│   │   │   ├── settings/       # Sub-route: Organization & User settings
│   │   │   └── layout.tsx      # Dashboard shell layout with dynamic sidebar
│   │   ├── api/                # Route Handlers for external REST/Webhook endpoints
│   │   │   ├── v1/             # Versioned API routes
│   │   │   └── webhooks/       # Third-party webhook receivers (e.g., Stripe)
│   │   ├── error.tsx           # Global fallback error boundary
│   │   ├── global-error.tsx    # Root layout error boundary
│   │   ├── layout.tsx          # Root Application Layout (Providers, Fonts)
│   │   ├── loading.tsx         # Root Suspense streaming fallback
│   │   ├── not-found.tsx       # 404 handler page
│   │   └── page.tsx            # Application Marketing / Landing Root Page
│   ├── components/             # Reusable UI component ecosystem
│   │   ├── ui/                 # Primitive atomic components (Button, Modal, Input)
│   │   ├── forms/              # Form wrapper components with validation schemas
│   │   └── shared/             # Layout primitives (Navigation, Footer, Sidebar)
│   ├── server/                 # Exclusive Server-Side Layer (Isolated from Bundle)
│   │   ├── actions/            # Next.js Server Actions (Mutations & Secure Calls)
│   │   ├── db/                 # Database ORM client, schemas, and migrations
│   │   │   ├── index.ts        # Database connection pool setup
│   │   │   └── schema/         # Database schema definitions
│   │   └── services/           # Business logic domain layer & microservice SDKs
│   ├── lib/                    # Shared core utilities, helpers, and base logic
│   │   ├── auth.ts             # Auth session configurations and token helpers
│   │   ├── env.ts              # Type-safe environment variable parser (Zod)
│   │   └── utils.ts            # Class merging and string formatting utilities
│   ├── hooks/                  # Custom Client-side React Hooks
│   ├── store/                  # Client-side state managers (Zustand / Jotai)
│   ├── styles/                 # Global CSS stylesheet modules & Tailwind plugins
│   └── types/                  # Ambient TypeScript declarations and interface models
├── .env.example                # Schema template for environment variables
├── .eslintrc.json              # Strict ESLint configuration rule definitions
├── middleware.ts               # Next.js Edge Middleware for routing & auth guard
├── next.config.ts              # Next.js compiler & server options
├── package.json                # Project dependencies, scripts, and engine locks
├── tsconfig.json               # TypeScript compiler config with strict path aliases
└── vitest.config.ts            # Unit and integration test suite config
```

## **Key Structural Conventions**

* **Server/Client Isolation**: Server actions and database logic reside within `src/server/` to ensure zero database or server logic leaks into client JS bundles.  
* **Route Grouping**: Route groups denoted by parentheses `(auth)` logical boundaries without impacting URL path hierarchies.  
* **Type-Safe Environment Variables**: Validation enforced at build-time via `src/lib/env.ts`.

# **5.2 Next.js 16 Server Communication Matrix**

Next.js 16 provides multiple pathways for client-server communication. The following matrix defines standard usage patterns, security enforcement layers, execution environments, and caching policies across the platform.

| Communication Channel | Primary Use Case | Execution Context | Security & Auth Guard | Caching & Invalidation Strategy |
| :---- | :---- | :---- | :---- | :---- |
| Server Components (RSC) | Initial page rendering, layout hydration, server data fetching | Node.js / Edge Runtime | Middleware validation & layout-level auth checks | Default dynamic cache; tagged via `revalidateTag()` |
| Server Actions | Form submissions, resource mutations, state updates | Node.js Server | Action-level session token verification | Invalidates cache via `revalidatePath()` or `revalidateTag()` |
| Route Handlers (API) | Third-party integrations, public REST APIs, Webhooks | Node.js / Edge Runtime | Bearer tokens, HMAC verification, API Key headers | `Cache-Control` headers, `export const dynamic = 'force-dynamic'` |
| Client Data Fetching | Dynamic client updates, polling, user-triggered refetches | Client Browser | Cookie-based session credentials (`credentials: include`) | TanStack Query / SWR cache with optimistic updates |
| Server-Sent Events (SSE) | Real-time streams, progress updates, notification feeds | Edge Runtime | Query parameter auth token or session cookies | Streaming HTTP response; caching strictly disabled |

## **Architectural Data Flow Patterns**

* **Read Operations (Queries)**: Executed directly within React Server Components via domain services in `src/server/services`. Data is fetched in parallel using standard `Promise.all` patterns to eliminate request waterfalls.  
* **Write Operations (Mutations)**: Handled exclusively through Server Actions. Input payloads are validated against Zod schemas, session tokens are parsed, and invalidations are propagated instantly via `revalidateTag`.  
* **External Event Processing**: Inbound webhooks process through isolated Route Handlers (`src/app/api/webhooks/`), where signature verification occurs before delegating processing to background tasks.

# **5.3 package.json Scripts & Workspace Configuration**

The following script suite provides standardized commands for development, building, testing, database lifecycle management, and static code analysis.

```
{
  "name": "@enterprise/platform-app",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev --turbo",
    "build": "next build",
    "start": "next start",
    "lint": "next lint --max-warnings 0",
    "lint:fix": "eslint --fix .",
    "format:check": "prettier --check \"**/*.{ts,tsx,md,json}\"",
    "format:write": "prettier --write \"**/*.{ts,tsx,md,json}\"",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:e2e": "playwright test",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate",
    "db:studio": "drizzle-kit studio",
    "db:push": "drizzle-kit push",
    "validate": "pnpm run typecheck && pnpm run lint && pnpm run format:check && pnpm run test",
    "clean": "rimraf .next node_modules .turbo"
  }
}
```

## **Script Execution Definitions**

* **dev**: Boots local development server with Turbopack enabled for high-speed module compilation.  
* **validate**: Continuous Integration pipeline script ensuring static type safety, style conformance, and unit test pass rates prior to deployment.  
* **db:\***: Schema orchestration and migration management using Drizzle Kit.  
* **test & test:e2e**: Dual-tier testing architecture covering unit components with Vitest and end-to-end user journeys with Playwright.

