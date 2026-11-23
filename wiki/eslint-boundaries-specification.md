# **ESLint 9 Architectural Boundary Specification**

**Author:** Person  
**Last Updated:** Date  
**Status:** Approved Specification

This document defines the production ESLint 9 Flat Configuration (`eslint.config.js`) enforcing strict architectural boundaries. The rules integrate Clean Architecture dependency directions, Domain-Driven Design (DDD) Bounded Context encapsulation, and Bulletproof React modular folder organization using `eslint-plugin-boundaries`.

# **Architectural System Model**

The application architecture enforces three distinct dimensions of software isolation:

* **Clean Architecture Layers:** Unidirectional dependency flow where core domain logic is decoupled from frameworks, infrastructure, and UI.  
* **DDD Bounded Contexts (Features):** Independent domain modules that cannot access internal implementations of other domains directly. Cross-context communication must pass through an explicit Public API (`index.ts`).  
* **Bulletproof React Structure:** Standardized interior organization per feature (`api`, `components`, `domain`, `application`, `types`, `utils`).

## **Directory Layout Convention**

```
src/
├── app/                      # Application root, entry points, global providers
├── components/               # Global shared UI components (Bulletproof React)
├── config/                   # Global configuration and constants
├── shared/                   # Shared enterprise core
│   ├── domain/               # Enterprise-wide domain primitives
│   └── utils/                # Cross-cutting utilities
└── features/                 # DDD Bounded Contexts
    ├── auth/                 # Example Bounded Context
    │   ├── api/              # Data fetching, query hooks
    │   ├── application/      # Use cases, application hooks, state management
    │   ├── components/       # Feature-specific UI components
    │   ├── domain/           # Entities, value objects, domain logic
    │   ├── infrastructure/   # Services, API clients, persistence adapters
    │   ├── types/            # Type definitions
    │   └── index.ts          # Encapsulated Public API barrier
    └── payment/              # Another Bounded Context
```

# **ESLint 9 Flat Configuration (`eslint.config.js`)**

Below is the complete, self-contained ESLint 9 Flat Configuration file. It relies on standard ESM exports and native TypeScript support via `@typescript-eslint/parser`.

```js
import boundaries from "eslint-plugin-boundaries";
import tsParser from "@typescript-eslint/parser";

export default [
  {
    files: ["src/**/*.{js,mjs,cjs,ts,jsx,tsx}"],
    plugins: {
      boundaries,
    },
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        ecmaVersion: "latest",
        sourceType: "module",
      },
    },
    settings: {
      "boundaries/include": ["src/**/*"],
      "boundaries/ignore": ["src/**/*.test.*", "src/**/*.spec.*"],
      "boundaries/elements": [
        // App Layer
        {
          type: "app",
          pattern: "src/app/*",
          mode: "full",
        },
        // Shared Infrastructure & Primitives
        {
          type: "shared-ui",
          pattern: "src/components/*",
          mode: "full",
        },
        {
          type: "shared-core",
          pattern: "src/shared/*",
          mode: "full",
        },
        {
          type: "shared-config",
          pattern: "src/config/*",
          mode: "full",
        },
        // Feature Bounded Context Public APIs
        {
          type: "feature-public-api",
          pattern: "src/features/*/index.ts",
          mode: "full",
          capture: ["feature"],
        },
        // Feature Clean Architecture Layers (Interior)
        {
          type: "feature-domain",
          pattern: "src/features/*/{domain,types}/*",
          mode: "full",
          capture: ["feature"],
        },
        {
          type: "feature-application",
          pattern: "src/features/*/{application,api,hooks}/*",
          mode: "full",
          capture: ["feature"],
        },
        {
          type: "feature-infrastructure",
          pattern: "src/features/*/infrastructure/*",
          mode: "full",
          capture: ["feature"],
        },
        {
          type: "feature-ui",
          pattern: "src/features/*/components/*",
          mode: "full",
          capture: ["feature"],
        },
      ],
    },
    rules: {
      // 1. Enforce Element Boundaries (Clean Architecture + DDD Contexts)
      "boundaries/element-types": [
        "error",
        {
          default: "disallow",
          message: "Architecture Violation: `${from.type}` is not permitted to import `${target.type}`.",
          rules: [
            // Global App Entry can import everything
            {
              from: ["app"],
              allow: [
                "shared-ui",
                "shared-core",
                "shared-config",
                "feature-public-api",
              ],
            },

            // Shared Layer Dependencies
            {
              from: ["shared-ui"],
              allow: ["shared-core", "shared-config"],
            },
            {
              from: ["shared-core"],
              allow: ["shared-config"],
            },

            // DDD Context Rules: Domain Layer (Pure Business Logic)
            {
              from: ["feature-domain"],
              allow: [
                "shared-core",
                // Can only access own domain models
                ["feature-domain", { feature: "${from.feature}" }],
              ],
            },

            // DDD Context Rules: Application Layer (Use Cases, Hooks, Queries)
            {
              from: ["feature-application"],
              allow: [
                "shared-core",
                "shared-config",
                ["feature-domain", { feature: "${from.feature}" }],
                ["feature-application", { feature: "${from.feature}" }],
              ],
            },

            // DDD Context Rules: Infrastructure Layer (API Clients, Adapters)
            {
              from: ["feature-infrastructure"],
              allow: [
                "shared-core",
                "shared-config",
                ["feature-domain", { feature: "${from.feature}" }],
                ["feature-application", { feature: "${from.feature}" }],
                ["feature-infrastructure", { feature: "${from.feature}" }],
              ],
            },

            // DDD Context Rules: UI Layer (React Components, Presentation)
            {
              from: ["feature-ui"],
              allow: [
                "shared-ui",
                "shared-core",
                "shared-config",
                ["feature-domain", { feature: "${from.feature}" }],
                ["feature-application", { feature: "${from.feature}" }],
                ["feature-ui", { feature: "${from.feature}" }],
              ],
            },

            // Feature Public API Aggregator
            {
              from: ["feature-public-api"],
              allow: [
                ["feature-domain", { feature: "${from.feature}" }],
                ["feature-application", { feature: "${from.feature}" }],
                ["feature-infrastructure", { feature: "${from.feature}" }],
                ["feature-ui", { feature: "${from.feature}" }],
              ],
            },
          ],
        },
      ],

      // 2. Strict Entry Point Restriction (Bounded Context Isolation)
      "boundaries/entry-point": [
        "error",
        {
          default: "disallow",
          message: "DDD Violation: Direct access to internal module allowed only via Feature Public API index.ts.",
          rules: [
            {
              target: ["feature-domain", "feature-application", "feature-infrastructure", "feature-ui"],
              allow: "index.ts",
            },
          ],
        },
      ],

      // 3. External Package Restrictions for Pure Domain Core
      "boundaries/external": [
        "error",
        {
          default: "allow",
          rules: [
            {
              from: ["feature-domain"],
              disallow: ["react", "react-dom", "axios", "@tanstack/*"],
              message: "Clean Architecture Violation: Pure domain layer cannot import UI frameworks or external IO libraries.",
            },
          ],
        },
      ],
    },
  },
];
```

# **Matrix of Permitted Module Dependencies**

| Source Layer / Module | Can Import From (Same Feature) | Can Import From (Cross-Feature) | Can Import From (Shared) | Disallowed Imports |
| :---- | :---- | :---- | :---- | :---- |
| **`feature/domain`** | `domain`, `types` | *None* | `shared/core` | UI libraries, HTTP clients, `feature/ui`, `feature/application` |
| **`feature/application`** | `domain`, `application`, `api` | *None* | `shared/core, shared/config` | React UI components, external DOM APIs, direct context bypass |
| **`feature/infrastructure`** | `domain`, `application` | *None* | `shared/core, shared/config` | `feature/ui`, direct imports from foreign contexts |
| **`feature/ui`** | `domain`, `application`, `ui` | *None* | `shared/ui, shared/core` | Private internals of other features, raw network calls |
| **`feature/index.ts`** | All internal feature modules | *None* | *None* | Internal paths of other features |
| **`app/`** | N/A | Feature index.ts only | `shared/*` | Internal implementation files of features (`features/*/domain/...`) |

# **Verification and CI Enforcement**

To execute boundary validation locally or within continuous integration pipelines, run the standard lint command:h  
npx eslint . \--ext .ts,.tsx

````

### Common Rule Violation Examples

```typescript
// Location: src/features/payment/domain/payment-entity.ts

// ❌ ERROR: Clean Architecture Violation (Domain importing external UI/State library)
import React from 'react'; 

// ❌ ERROR: DDD Violation (Cross-context internal dependency)
import { UserProfile } from '../../auth/components/UserProfile'; 

// ✅ VALID: Importing domain primitives from shared core
import { Money } from '../../../shared/domain/Money'; 
````

```
// Location: src/app/routes.tsx

// ❌ ERROR: DDD Isolation Violation (Bypassing Public API)
import { UserCard } from '@/features/auth/components/UserCard'; 

// ✅ VALID: Importing via Public API barrier
import { UserCard } from '@/features/auth'; 
```

