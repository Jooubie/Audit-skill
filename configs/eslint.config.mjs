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
      // Enforce Clean Architecture Unidirectional Flow
      "boundaries/element-types": [
        "error",
        {
          default: "disallow",
          rules: [
            {
              from: ["app"],
              allow: ["shared-ui", "shared-core", "shared-config", "feature-public-api"],
            },
            {
              from: ["feature-ui"],
              allow: ["shared-ui", "shared-core", "feature-application", "feature-domain"],
            },
            {
              from: ["feature-application"],
              allow: ["shared-core", "shared-config", "feature-domain", "feature-infrastructure"],
            },
            {
              from: ["feature-infrastructure"],
              allow: ["shared-core", "shared-config", "feature-domain"],
            },
            {
              from: ["feature-domain"],
              allow: ["shared-core"], // Domain cannot depend on outer layers
            },
            {
              from: ["shared-ui"],
              allow: ["shared-core", "shared-config"],
            },
          ],
        },
      ],
      // Enforce DDD Bounded Context Isolation (features can only talk via public API)
      "boundaries/entry-point": [
        "error",
        {
          default: "disallow",
          rules: [
            {
              target: ["feature-domain", "feature-application", "feature-infrastructure", "feature-ui"],
              allow: "index.ts",
            },
          ],
        },
      ],
    },
  },
];
