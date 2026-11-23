# **Reference 09: Architectural Patterns & Modern Web Development**

Technical Specifications, Design Patterns & Enterprise Application Structure

| Parameter | Specification Details |
| :---- | :---- |
| **Document ID** | REF-2026-09 |
| **Target Framework** | Next.js 16 (App Router) & React 19 |
| **Primary Patterns** | Clean Architecture, DAL, Humble Object, Bulletproof React |
| **Author / Lead Architect** | Person |
| **Last Updated** | Date |

# **Clean Architecture Principles**

Clean Architecture organizes software systems into concentric layers of isolation, ensuring business logic remains independent of frameworks, databases, and UI implementations.

# **The Core Layers**

* **Entities (Enterprise Business Rules):** Encapsulate fundamental domain models, validation logic, and business invariants. Entities remain untouched by external API changes or database migrations.  
* **Use Cases (Application Business Rules):** Define specific workflows and application capabilities. They orchestrate data flow between entities and application-level requirements without exposing technical infrastructure.  
* **Interface Adapters (Controllers & Presenters):** Transform data between internal use-case formats and external representations (e.g., HTTP request bodies, database queries, DTOs).  
* **Frameworks & Drivers (Infrastructure):** Outer layer containing UI elements, database ORMs, external service integration libraries, and HTTP routing mechanics.

# **The Dependency Rule**

Dependencies must point inward exclusively. Inner layers have no knowledge of functions, classes, or variables declared in outer layers.

```
+-------------------------------------------------------------+
| Frameworks & Drivers (Next.js, Postgres, External APIs)     |
|   +-----------------------------------------------------+   |
|   | Interface Adapters (DAL, DTOs, Action Handlers)     |   |
|   |   +---------------------------------------------+   |   |
|   |   | Use Cases (Application Workflow Services)   |   |   |
|   |   |   +-------------------------------------+   |   |   |
|   |   |   | Entities (Core Domain Logic)        |   |   |   |
|   |   |   +-------------------------------------+   |   |   |
|   |   +---------------------------------------------+   |   |
|   +-----------------------------------------------------+   |
+-------------------------------------------------------------+
```

# **Next.js 16 App Router Paradigm**

Next.js 16 leverage Server-First execution, leveraging React Server Components (RSC) to construct decoupled server and client runtime environments.

# **Component Boundary Allocation**

* **React Server Components (RSC):** Render exclusively on the server. Directly access backend resources (databases, microservices, secure file systems) without sending runtime code to the browser bundle.  
* **Client Components (`'use client'`):** Manage interactive states, client event listeners, browser APIs, and UI animations.

# **Data Mutations & Server Actions**

Mutations execute via type-safe RPC boundaries called Server Actions.

* Server Actions encapsulate backend execution logic and revalidate cached paths or tags using native primitives.  
* Cache control and targeted data invalidation rely on explicit path revalidation and tag-based invalidation strategies.

# **Data Access Layer (DAL) Architecture**

The Data Access Layer establishes a secure boundary between client request handling and underlying data persistent storage.

# **Key DAL Responsibilities**

* **Data Isolation:** Prevents raw database access inside React components.  
* **Authorization Verification:** Executes session validation and RBAC checks prior to data queries.  
* **Data Sanitization & DTO Mapping:** Formats database output into minimal Data Transfer Objects (DTOs), preventing internal model leaking.

# **Compile-Time Boundary Enforcement**

To prevent accidental execution of sensitive data queries within client bundles, import protection must be declared explicitly:

```
import 'server-only';
```

# **Security & Access Control Flow**

```
[Client / Server Component] 
       │
       ▼
[Data Access Layer (DAL)] ──(Validate Session & RBAC)──► Auth Check Fail ──► Throw Unauthorized
       │
       ├─► (Sanitize Input & Apply DTO Format)
       │
       ▼
[Database / Infrastructure]
```

# **Network Intermediary Layer (`proxy.ts`)**

The `proxy.ts` module standardizes outbound and internal network traffic, intercepting server-side requests to handle routing, authentication token passing, and logging.

# **Core Capabilities**

* **Token Delegation:** Automatically attaches bearer tokens, API keys, or session identifiers to outbound service calls.  
* **Request Redirection & Rewriting:** Seamlessly proxies client requests to internal microservices without exposing infrastructure topographies.  
* **Error Normalization:** Standardizes upstream error codes into application-level domain errors.

# **Implementation Standard**

```
export async function fetchWithProxy(endpoint: string, options: RequestInit = {}) {
  const token = await getAuthToken();
  const headers = {
    'Content-Type': 'application/json',
    ...(token && { Authorization: `Bearer ${token}` }),
    ...options.headers,
  };

  const response = await fetch(`${process.env.INTERNAL_API_URL}${endpoint}`, {
    ...options,
    headers,
  });

  if (!response.ok) {
    throw new Error(`Proxy error: ${response.statusText}`);
  }

  return response.json();
}
```

# **Bulletproof React Architecture**

Bulletproof React provides a scalable modular layout, grouping code by domain functionality rather than technical file types.

# **Feature-Based Folder Structure**

Application logic is organized into isolated feature modules residing within `src/features/*`.

```
src/
├── app/                  # Route handlers & page layouts (Next.js App Router)
├── components/           # Shared global UI components (Buttons, Inputs, Modals)
├── features/             # Domain modules
│   └── user-profile/
│     ├── api/            # Feature-specific DAL hooks & fetchers
│     ├── components/     # Feature-isolated React components
│     ├── types/          # Feature domain types & schemas
│     └── utils/          # Feature helper functions
├── lib/                  # Application-wide client configuration & instances
└── utils/                # Shared utility functions
```

# **Module Boundaries**

Features export public capabilities through a central `index.ts` file. Deep imports across feature boundaries (e.g., importing directly from `features/user-profile/components/InternalSubComponent`) are strictly prohibited to preserve module encapsulation.

# **The Humble Object Pattern**

The Humble Object pattern separates hard-to-test execution environments (e.g., UI components, framework route handlers, external SDK wrappers) from core application business logic.

# **Strategy & Implementation**

1. Extract conditional statements, data conversions, and calculation logic out of components and handlers.  
2. Place this logic into pure, framework-agnostic functions or domain classes.  
3. Keep the outer object "humble" by restricting its responsibility to passing inputs to the pure core logic and delegating side effects.

# **Pattern Comparison**

| Component Aspect | Humble Shell (UI / Action / Route) | Pure Core Logic (Domain / Util) |
| :---- | :---- | :---- |
| **Framework Dependency** | High (Next.js, React Hooks, UI state) | Zero (Plain TypeScript functions) |
| **Testing Mechanism** | Integration / End-to-End | Fast, deterministic Unit Tests |
| **Primary Duty** | I/O, routing, DOM updates, event handling | Algorithmic logic, domain validation, rules |

