# **Strict TypeScript Conventions: Core Type Safety Patterns**

# **Guidelines Derived from Effective TypeScript (2nd Edition)**

## **Overview**

This standard establishes strict TypeScript practices for core applications. By eliminating uncontrolled type escape hatches, validating external inputs at boundaries, preventing nominal primitive mix-ups, preserving literal types, and enforcing total union coverage, these conventions guarantee compile-time correctness and runtime resilience.

## **1\. Boundary Validation: `unknown` with Zod Schemas**

Using any or explicit unsafe type assertions (as MyType) at API, database, or network boundaries creates silent runtime vulnerabilities. The standard convention mandates accepting unvalidated data as `unknown` and verifying its structure at runtime using Zod.

### **Key Guidelines**

* Never use `any` or blind type assertions (`as T`) on API payload responses or external inputs.  
* Declare structural shapes using Zod schemas and derive TypeScript types using `z.infer`.  
* Parse untrusted inputs using `.parse()` or `.safeParse()` before passing data to core domain functions.

### **Code Pattern Implementation**

```
import { z } from "zod";

// 1. Define runtime validation schema
export const UserPayloadSchema = z.object({
  id: z.string().uuid(),
  username: z.string().min(3),
  email: z.string().email(),
  role: z.enum(["admin", "member", "guest"]),
  metadata: z.record(z.string(), z.unknown()).optional(),
});

// 2. Infer static type directly from the runtime schema
export type UserPayload = z.infer<typeof UserPayloadSchema>;

// 3. Secure boundary handler consuming unknown input
export function processIncomingUser(rawInput: unknown): UserPayload {
  // Validates payload at runtime and narrows type safely from unknown to UserPayload
  const validatedUser = UserPayloadSchema.parse(rawInput);
  return validatedUser;
}
```

## **2\. Nominal Typing: Branded Types**

TypeScript uses structural typing, meaning two types with identical structures are compatible. This can lead to bugs where distinct domain concepts (e.g., `UserId` and `OrderId`, or `UnsanitizedHtml` and `SanitizedHtml`) are accidentally interchanged because both are underlying `string` types. Branded types attach a unique nominal tag at compile-time to prevent cross-assignment.

### **Key Guidelines**

* Use branded types for primitive identifiers, raw currencies, and security-sensitive string states.  
* Ensure zero runtime overhead by declaring the brand tag as a unique symbol phantom property.  
* Provide clear factory functions or type guard predicates for brand construction.

### **Code Pattern Implementation**

```
// Base generic branding type using a unique symbol phantom key
declare const brandSymbol: unique symbol;

export type Brand<T, BrandTag extends string> = T & {
  readonly [brandSymbol]: BrandTag;
};

// Domain-specific nominal primitives
export type UserId = Brand<string, "UserId">;
export type OrderId = Brand<string, "OrderId">;
export type UsdAmount = Brand<number, "UsdAmount">;

// Constructor helper functions (explicit boundary constructors)
export function makeUserId(id: string): UserId {
  return id as UserId;
}

export function makeOrderId(id: string): OrderId {
  return id as OrderId;
}

// Practical usage enforcing safety
function chargeUser(userId: UserId, orderId: OrderId) {
  // Execution logic
}

const currentUser = makeUserId("usr_8921");
const currentOrder = makeOrderId("ord_4311");

// Safe invocation:
chargeUser(currentUser, currentOrder);

// The following would trigger a static compile error:
// chargeUser(currentOrder, currentUser); 
// Error: Type '"OrderId"' is not assignable to type '"UserId"'
```

## **3\. Non-Widening Structural Checks: `satisfies` Operator**

Standard type annotations (`const config: Config = { ... }`) force TypeScript to widen literal types into broader primitive types. The `satisfies` operator (introduced in TypeScript 4.9) checks that an object satisfies a specific type interface without modifying or widening the inferred literal types of its properties.

### **Key Guidelines**

* Prefer `satisfies` over explicit annotations when building lookup maps, configuration objects, or literal dictionary patterns.  
* Retain precise autocompletion and exact property types (such as tuple sizes or string literal unions).

### **Code Pattern Implementation**

```
type ElementConfig = Record<string, string | [number, number, number]>;

// Using standard annotation widens properties to string | [number, number, number]
// const legacyTheme: ElementConfig = { primary: "#1E293B", padding: [10, 20, 10] };

// Using satisfies validates compliance while preserving property-level precision:
const appTheme = {
  primary: "#1E293B",
  secondary: "#64748B",
  padding: [10, 20, 10],
} satisfies ElementConfig;

// Properties preserve exact inferred types:
const hexCode = appTheme.primary.toUpperCase(); // Validated as string
const topPadding = appTheme.padding[0].toFixed(1); // Validated as number
```

## **4\. Compile-Time Exhaustiveness: `assertNever`**

When working with discriminated unions, adding a new variant without updating all matching switch or conditional statements can lead to silent unhandled execution branches. The `assertNever` helper leverages TypeScript's `never` type to ensure at compile-time that every variant is explicitly handled.

### **Key Guidelines**

* End every switch or conditional chain processing a discriminated union with `assertNever(unhandledValue)`.  
* Provide a descriptive runtime fallback inside `assertNever` to guard against unexpected runtime values.

### **Code Pattern Implementation**

```
// Utility function for exhaustiveness checking
export function assertNever(value: never): never {
  throw new Error(`Unhandled discriminated union variant: ${JSON.stringify(value)}`);
}

// Discriminated union domain events
type NotificationEvent =
  | { type: "EMAIL"; recipient: string; subject: string }
  | { type: "SMS"; phoneNumber: string; body: string }
  | { type: "PUSH"; deviceToken: string; payload: Record<string, string> };

export function dispatchNotification(event: NotificationEvent): void {
  switch (event.type) {
    case "EMAIL":
      // Dispatch email notification logic
      break;
    case "SMS":
      // Dispatch SMS notification logic
      break;
    case "PUSH":
      // Dispatch push notification logic
      break;
    default:
      // If a new event variant is added to NotificationEvent without a case branch,
      // TypeScript will flag a compile error on event.
      assertNever(event);
  }
}
```

## **Pattern Reference Matrix**

| Convention Pattern | Problem Solved | TypeScript Mechanism | Core Benefit |
| :---- | :---- | :---- | :---- |
| `unknown` \+ Zod | Boundary unsafe assertions | Runtime Schema Parsing | Eliminates hidden runtime errors from bad API data |
| Branded Types | Structural equivalence of primitives | Nominal branding via `symbol` | Prevents mixing up domain IDs (e.g. `UserId` vs `OrderId`) |
| `satisfies` | Over-widening of object properties | Structural checking without mutation | Retains literal precision and exact autocompletion |
| `assertNever` | Unhandled branches in unions | Control flow analysis (`never`) | Guarantees compile-time exhaustiveness for unions |

## **Document Metadata & Sign-off**

* Specification Author: Standard Architecture Guild  
* Reference Source: Dan Vanderkam, Effective TypeScript (2nd Edition)  
* Compliance Target: Strict Mode (`strict: true`, `noImplicitAny: true`, `exactOptionalPropertyTypes: true`)  
* Reviewed By: Person  
* Approval Date: Date

