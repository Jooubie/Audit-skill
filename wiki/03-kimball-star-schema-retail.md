# **Reference 03: Kimball Architectural Standards & Multi-Brand Retail Modeling**

Enterprise Data Warehouse Engineering & Dimensional Design Specification

*Document Details:*  
Author: Person  
Reviewer: Person  
Last Modified: Date

# **Executive Overview**

This reference specification establishes the core architectural standards for designing dimensional data warehouses in multi-brand retail environments following Ralph Kimball's dimensional modeling methodology. Adherence to these standards ensures enterprise-wide scalability, high query performance, exact financial reconciliation, and robust tracking of operational shifts over time.

# **The Four-Step Dimensional Design Process**

Every star schema across the retail enterprise must be designed following Kimball's four-step process:

1. **Select the Business Process**: Identify the operational activity to be modeled (e.g., Point of Sale Transactions, E-Commerce Orders, Inventory Snapshots, Retail Store Returns).  
2. **Declare the Grain**: Explicitly state the finest level of detail represented by a single row in the fact table. In modern retail analytics, grain must always be declared at the lowest possible atomic level.  
3. **Identify the Dimensions**: Contextualize the business process event by defining dimensions that answer *who, what, where, when, why, and how* (e.g., `dim_product`, `dim_customer`, `dim_store`, `dim_date`, `dim_promotion`).  
4. **Identify the Facts**: Select the numeric measures resulting from the business process event (e.g., `sales_quantity`, `gross_amount_cents`, `discount_amount_cents`, `tax_amount_cents`).

# **Granularity & Financial Precision Standards**

# **Atomic Line-Item Grain**

Fact tables representing transaction processes must be designed at the **individual line-item grain** (e.g., one row per scanned SKU on a physical receipt or e-commerce order line).

* **No Pre-Aggregation**: Aggregating transactions to order-level headers or daily store summaries during ETL limits drill-down capabilities and obscures critical item-level interactions (such as brand basket affinity or line-item level promotions).  
* **Dimensional Flexibility**: Atomic grain guarantees that facts can be sliced and diced by any dimension attribute across multi-brand hierarchies without loss of precision.

# **BIGINT Cents Standard**

To eliminate non-deterministic floating-point rounding errors (`FLOAT`, `DOUBLE`, `REAL`), all monetary fields must be stored as **64-bit integers (`BIGINT`) representing the lowest fractional currency unit** (e.g., cents, pence, yen).

* **Storage Format**: \$1,249.99 is stored as integer `124999`.  
* **Calculations**: Multiplications and allocations take place using integer arithmetic. Conversion to display formats with decimal formatting is deferred strictly to reporting tools and semantic layers.

# **Dual Currency Facts**

Multi-brand retail platforms operating across regional markets must record dual currency measures within every financial fact record:

1. **Local / Transaction Currency**: Measured in native local currency units (e.g., `local_gross_amount_cents`).  
2. **Base / Reporting Currency**: Converted at transaction time into the enterprise corporate currency (e.g., `base_gross_amount_cents`).  
3. **Foreign Exchange Keys**: Linked explicitly to `dim_currency` and `dim_exchange_rate` to record the exact rate applied at the moment of transaction.

# **Advanced Modeling & Allocation Algorithms**

# **Hare-Niemeyer Allocation Method**

Header-level measures (e.g., cart discounts, order-level shipping fees, global order taxes) must be distributed down to individual line items without fractional penny loss or rounding drift. Enterprise pipelines must apply the **Hare-Niemeyer (Largest Remainder) Method**:

1. **Calculate Proportional Share**: Compute each line item's exact fractional portion based on line value relative to total header value.  
2. **Floor Integer Allocation**: Assign each line item the integer floor of its share:  
   \$\$\\text{Base Allocation}\_i \= \\lfloor \\text{Header Total} \\times \\frac{\\text{Line Amount}\_i}{\\text{Total Order Amount}} \\rfloor\$\$  
3. **Distribute Unassigned Pennies**: Calculate the remaining unallocated cents. Sort line items by their fractional remainders in descending order, and distribute one cent to each line item sequentially until all remaining cents are assigned.

This guarantees that \$\\sum \\text{Allocated Line Amounts} \= \\text{Header Total}\$ down to the exact cent across all transactions.

# **Slowly Changing Dimensions (SCD Type 2 / Type 7\)**

To track historical structural changes across brands, store ownerships, and product catalog hierarchies, the architecture uses a hybrid SCD Type 2 and Type 7 strategy:

* **SCD Type 2 (Historical Context)**: Every attribute change creates a new dimension row with a new surrogate key (`product_sk`), accompanied by explicit lineage fields (`effective_timestamp`, `expiration_timestamp`, `is_current`).  
* **SCD Type 7 (Dual Key Integration)**: Fact tables store both:  
  * The **Type 2 Surrogate Key** (`product_sk`): Joins to the dimension record active at the time of the transaction for accurate point-in-time reporting.  
  * The **Durable Super Key / Natural Key** (`product_durable_key`): Joins to the current dimension record (`is_current = True`) to allow reporting across current brand hierarchies regardless of historical timing.

# **Governance & Data Quality Audit Rules**

All pipeline transformations, staging layers, and star schemas must comply with audit rules KIM-01 through KIM-06.

| Rule Code | Rule Name | Requirement & Audit Constraint | Enforcement Mechanism |
| :---- | :---- | :---- | :---- |
| KIM-01 | Atomic Grain Isolation | Fact tables must strictly enforce declared atomic line-item granularity. Mixed-grain facts (e.g., headers combined with line items) are strictly prohibited. | Automated schema checks & ETL pipeline assertions blocking mixed-grain ingestion. |
| KIM-02 | Non-Null Foreign Keys | All foreign keys in fact tables must resolve to valid dimension surrogate keys. `NULL` values are forbidden. Unmapped or missing keys must resolve to standard default rows (`-1` for Unknown, `-2` for Not Applicable). | Database Foreign Key constraints and automated null-check validation routines. |
| KIM-03 | BIGINT Financial Standard | All monetary measures must be stored as 64-bit integer cents (`BIGINT`). Floating-point data types are strictly disallowed for financial values. | DDL data type validation during CI/CD deployment checks. |
| KIM-04 | Dual Currency Completeness | Every financial fact table row must contain both native local currency measures and standardized base corporate currency measures, alongside valid currency dimension keys. | Data quality pipelines validating that `local_amount * conversion_rate = base_amount` within allowable margin. |
| KIM-05 | Exact Allocation Conservation | Header-to-line allocations must use the Hare-Niemeyer method. The sum of line-level allocated measures must equal the parent header value with zero variance. | Automated reconciliation audits verifying `SUM(line_allocated_amount) = header_total`. |
| KIM-06 | SCD Type 2/7 Integrity | Type 2 dimension historical rows must maintain contiguous, non-overlapping timestamp ranges. Type 7 durable super keys must resolve correctly to both current and historical states. | Daily temporal overlap queries and dual-key referential integrity validation runs. |

