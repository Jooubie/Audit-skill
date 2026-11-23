# **Knip Dead Code Configuration Guide**

# **Setup Metadata**

| Metadata Field | Project Configuration Details |
| :---- | :---- |
| Target Framework | Next.js 16 (App Router) |
| Primary Language | TypeScript 5+ |
| Document Maintainer | Person |
| Last Reviewed Date | Date |

# **Executive Summary**

Knip is an automated analysis tool designed to detect unused files, exports, types, and dependencies across JavaScript and TypeScript projects. In Next.js 16 applications using the App Router, implicit file routing, server actions, route handlers, and specialized metadata exports can easily lead to false positives if not configured correctly.

This guide outlines the optimal configuration for running Knip cleanly against a Next.js 16 codebase.

# **Installation**

Install Knip as a dev dependency using your package manager of choice:

```
# npm
npm install -D knip typescript

# pnpm
pnpm add -D knip typescript

# yarn
yarn add -D knip typescript
```

# **Recommended Configuration (knip.json / knip.ts)**

Knip natively supports standard Next.js plugins, but explicit configuration prevents false positives related to Next.js 16 features like Server Actions, custom instrumentation, and parallel routes.

## **Type-Safe Configuration (knip.ts)**

```
import type { KnipConfig } from 'knip';

const config: KnipConfig = {
  // Next.js plugin automatically handles standard App Router & Pages Router entries
  next: {
    entry: [
      'next.config.{js,ts,mjs,cjs}',
      'app/**/page.{js,jsx,ts,tsx}',
      'app/**/layout.{js,jsx,ts,tsx}',
      'app/**/loading.{js,jsx,ts,tsx}',
      'app/**/error.{js,jsx,ts,tsx}',
      'app/**/not-found.{js,jsx,ts,tsx}',
      'app/**/route.{js,ts}',
      'app/**/template.{js,jsx,ts,tsx}',
      'app/**/default.{js,jsx,ts,tsx}',
      'app/**/opengraph-image.{js,jsx,ts,tsx}',
      'app/**/twitter-image.{js,jsx,ts,tsx}',
      'app/**/icon.{js,jsx,ts,tsx}',
      'app/**/apple-icon.{js,jsx,ts,tsx}',
      'app/sitemap.{js,ts}',
      'app/robots.{js,ts}',
      'app/manifest.{js,ts}',
      'middleware.{js,ts}',
      'instrumentation.{js,ts}',
    ],
  },
  project: ['src/**/*.{js,ts,jsx,tsx}', 'app/**/*.{js,ts,jsx,tsx}'],
  ignore: [
    '**/*.d.ts',
    '.next/**',
    'out/**',
    'public/**',
  ],
  ignoreDependencies: [
    'sharp', // Recommended optional runtime dependency for Next.js Image Optimization
    '@next/bundle-analyzer',
    'encoding',
  ],
  ignoreExportsUsedInFile: true,
};

export default config;
```

## **JSON Alternative (knip.json)**

If you prefer JSON format without TypeScript execution:n  
{  
"\$schema": "https\://unpkg.com/knip@5/schema.json",  
"entry": \[  
"src/index.{js,ts,jsx,tsx}"  
\],  
"project": \[  
"src/**/\*.{js,ts,jsx,tsx}",**  
**"app/**/*.{js,ts,jsx,tsx}"*  
*\],*  
*"next": {*  
*"entry": \[*  
*"next.config.{js,ts,mjs,cjs}",*  
*"app/**/page.{js,jsx,ts,tsx}",***  
***"app/**/layout.{js,jsx,ts,tsx}",*  
*"app/**/loading.{js,jsx,ts,tsx}",***  
***"app/**/error.{js,jsx,ts,tsx}",*  
*"app/**/not-found.{js,jsx,ts,tsx}",***  
***"app/**/route.{js,ts}",*  
*"middleware.{js,ts}",*  
*"instrumentation.{js,ts}"*  
*\]*  
*},*  
*"ignore": \[*  
*"\*\*/*.d.ts",  
".next/\*\*"  
\],  
"ignoreDependencies": \[  
"sharp"  
\]  
}

````

## Handling Next.js 16 Specific Conventions

Next.js 16 uses conventional file names and exports that Knip needs to recognize as entry points to avoid marking them as unused code.

| Entry Category | Conventional File Patterns | Tracked Exports / Purpose |
| --- | --- | --- |
| Dynamic Metadata | `sitemap.ts`, `robots.ts`, `manifest.ts` | Default export functions returning metadata structures |
| Image Generation | `opengraph-image.tsx`, `twitter-image.tsx` | Exported `alt`, `size`, `contentType`, and default Component |
| Root Hooks | `instrumentation.ts`, `middleware.ts` | Exported `register`, `onRequestError`, and `middleware` functions |
| Server Actions | Code files using `'use server'` directive | Exported functions invoked remotely via client interfaces |

## Package Scripts Integration

Add the following helper scripts to your `package.json`:

```json
{
  "scripts": {
    "lint:knip": "knip",
    "lint:knip:production": "knip --production",
    "lint:knip:fix": "knip --fix"
  }
}
````

# **Recommended CI Workflow Integration**

To enforce dead code checks during Pull Requests, add a step to your GitHub Actions workflow file (e.g., .github/workflows/ci.yml):

```
name: Code Quality Check

on:
  push:
    branches: [main]
  pull_request:

jobs:
  knip:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'pnpm'

      - name: Install Dependencies
        run: pnpm install --frozen-lockfile

      - name: Run Knip Dead Code Audit
        run: pnpm lint:knip
```

# **Best Practices & Troubleshooting**

## **Handling Server Actions**

When Server Actions are isolated in dedicated utility modules (e.g., actions/user.ts), Knip might report them as unused if they are only referenced dynamically. Ensure your project scope includes all file directories containing server actions.

## **Global CSS & Asset Imports**

If Knip flags CSS files or global stylesheets imported within app/layout.tsx, ensure the standard style loaders are recognized by verifying the next plugin is active in your configuration.

## **Monorepo Workspaces**

If running Next.js inside a monorepo (Turborepo or Nx), place the knip.json or knip.ts file at the root of the individual Next.js application package rather than the global monorepo root.