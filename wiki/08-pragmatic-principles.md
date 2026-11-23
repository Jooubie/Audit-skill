# **Reference 08: Software Architecture & Pragmatic Engineering Principles**

A synthesis of foundational software engineering mental models from Andrew Hunt and David Thomas (*The Pragmatic Programmer*) alongside modern architectural governance standards using MADR 4.0.0.

Document Owner: Person  
Last Revision: Date  
Target System/Repository: File

# **Core Pragmatic Principles (Hunt & Thomas)**

Pragmatic software development focuses on practical, real-world techniques that balance technical excellence with continuous delivery. The following three principles address code quality, system duplication, and iterative architecture.

## **The Broken Windows Theory**

The "Broken Windows Theory" originates from urban criminology, which posits that a single unrepaired broken window leads to urban decay and anti-social behavior. In software development, software entropy (or technical debt) behaves identically.

* **Software Entropy**: Every unhandled exception, bad design choice, messy formatting, or ignored compiler warning represents a broken window.  
* **Psychological Impact**: Teams working in a repository with poor quality standards lose motivation to write clean code, accelerating systemic degradation.  
* **Actionable Rule**: Fix bad designs, wrong decisions, and poor code as soon as they are discovered. If immediate resolution is impossible, wrap or isolate the issue cleanly to prevent further decay.

## **Don't Repeat Yourself (DRY)**

The DRY principle is often misunderstood as merely avoiding identical lines of code. Hunt and Thomas define it as a structural philosophy regarding domain logic and systemic representation.

* **Core Definition**: "Every piece of knowledge must have a single, unambiguous, authoritative representation within a system."  
* **Duplication of Knowledge**: Code lines may appear identical while representing entirely different business concepts (coincidental duplication). Conversely, two entirely different modules might duplicate the same core logic.  
* **Maintenance Cost**: When domain knowledge is scattered across multiple locations, updating a single business rule requires synchronized changes in multiple places, dramatically raising the risk of bugs.

## **Tracer Bullets**

In uncertain or greenfield architectural environments, developers must navigate unknown user requirements, third-party APIs, and novel platforms.

* **Definition**: Small, visible, fully integrated end-to-end features deployed straight through all system layers (from UI to database).  
* **Tracer Bullets vs. Prototyping**:  
  * *Prototypes* are disposable spike code meant to test a single hypothesis or feasibility point. They are thrown away once answered.  
  * *Tracer Bullets* build lean, real architecture containing real logging, real interfaces, and production wiring. They remain in the codebase and are iteratively expanded.  
* **Feedback Loop**: Providing early visual feedback to users and structural feedback to architects ensures alignment before heavy engineering investments occur.

# **Architectural Decision Records (MADR 4.0.0)**

Architectural Decision Records (ADRs) capture important architectural choices made along with their context and consequences. MADR (Markdown Architectural Decision Records) version 4.0.0 standardizes this format for easy git integration and developer reading.

## **Key Components of MADR 4.0.0**

* **Title**: Contains the ADR number and a concise decision statement.  
* **Context and Problem Statement**: Explains the background and constraints compelling a choice.  
* **Decision Drivers**: Explicit forces, quality attributes, and business constraints shaping the evaluation.  
* **Considered Options**: The technical options evaluated during the discovery phase.  
* **Decision Outcome**: The selected option and a succinct summary of why it won.  
* **Pros and Cons of the Options**: Explicit, balanced advantages and trade-offs for all considered options.

## **Sample MADR 4.0.0 Template**

n

# **\[Short title of solved problem and decision\]**

* Status: \[draft \| proposed \| rejected \| accepted \| deprecated \| superseded by ADR-0000\]  
  \|---\|---\|---\|---\|  
* Date: \[YYYY-MM-DD\]

# **Context and Problem Statement**

\[Describe the context and problem statement, e.g., in 2-3 sentences. Feel free to link to relevant package or design docs.\]

# **Decision Drivers**

* \[driver 1, e.g., driver, constraint, or quality attribute\]  
* \[driver 2, e.g., driver, constraint, or quality attribute\]

# **Considered Options**

* \[Option 1\]  
* \[Option 2\]  
* \[Option 3\]

# **Decision Outcome**

Chosen option: "\[Option 1\]", because \[justification, e.g., only option, which meets decision driver 1\].

## **Positive Consequences**

* \[e.g., improvement of quality attribute\]  
* \[e.g., enables integration with service X\]

## **Negative Consequences**

* \[e.g., compromise on quality attribute\]  
* \[e.g., requires retraining of team\]

# **Pros and Cons of the Options**

## **\[Option 1\]**

\[Good \| Bad \| Neutral\], because \[argument\].

* Good, because \[argument\]  
* Bad, because \[argument\]

## **\[Option 2\]**

* Good, because \[argument\]  
* Bad, because \[argument\]

```

## Summary Comparison Matrix

| Principle / Artifact | Primary Purpose | Core Mindset | Major Anti-Pattern |
| --- | --- | --- | --- |
| **Broken Windows** | Maintain system quality and developer discipline | Fix entropy immediately upon discovery | "We will refactor this bad hack later" |
| **DRY** | Preserve single source of truth for business rules | Eliminate duplicate knowledge representations | Copy-pasting domain logic across services |
| **Tracer Bullets** | Reduce uncertainty in systemic architecture | Build thin, complete end-to-end production slices | Massive upfront design without execution |
| **MADR 4.0.0** | Record architectural history and trade-offs | Document context, forces, and choices alongside code | Tribal knowledge and unwritten decisions |
```

