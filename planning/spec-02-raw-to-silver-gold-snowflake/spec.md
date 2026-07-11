# spec-02-raw-to-silver-gold-snowflake — Spec

## Overview
This milestone builds the core medallion database pipeline inside Snowflake using plain SQL. It stages raw order transaction data in ADLS Gen2, loads it into a Snowflake raw table, cleans and deduplicates the data into a Silver table, and aggregates the cleaned data into a plain SQL Gold table (by country and month)—without involving Iceberg formats yet.

## What This Milestone Builds
1.  **Raw CSV Data Asset**:
    *   A sample dataset of 20 transaction records (`sample_orders.csv`) featuring raw formatting, duplicates, and corrupt rows.
2.  **Ingestion Layer (Raw/Staging)**:
    *   Creation of schemas: `staging`, `raw`, `silver`, and `gold`.
    *   An external file format `staging.raw_csv_format` and stage `staging.raw_orders_stage` pointing to ADLS Gen2 `raw/` directory.
    *   A row-oriented staging table `raw.raw_orders` with string data types.
    *   An ingestion script `load_raw_orders.sql` copy-loading data from the stage.
3.  **Refinement Layer (Silver)**:
    *   A type-enforced table `silver.silver_orders` with primary keys and audit fields.
    *   A merge transformation script `raw_to_silver.sql` performing lowercase trims on emails, parsing dates, filtering nulls/corrupt rows, and deduplicating by order ID.
4.  **Aggregation Layer (Gold - Plain SQL)**:
    *   A plain Snowflake SQL table `gold.revenue_by_country_by_month` (not an Iceberg table).
    *   A transform script `silver_to_gold_plain.sql` to aggregate COMPLETED orders from Silver, calculating total revenue and order counts grouped by country and calendar month (using date truncation).

## What "Done" Looks Like
*   Logical schemas `staging`, `raw`, `silver`, and `gold` exist.
*   The raw CSV file `sample_orders.csv` is uploaded to ADLS Gen2.
*   `raw.raw_orders` is loaded with exactly **20** raw records.
*   `silver.silver_orders` contains exactly **15** cleaned, deduplicated records.
*   `gold.revenue_by_country_by_month` is successfully populated with business aggregations by country and month, verified via a counts query.
*   The runbook runs end-to-end with zero errors.

## Target Files to Implement
*   [spec.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/planning/spec-02-raw-to-silver-gold-snowflake/spec.md): This spec file.
*   [01_database_schema.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/snowflake/ddl/01_database_schema.sql): Creates logical schemas.
*   [02_raw_tables.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/snowflake/ddl/02_raw_tables.sql): Creates the raw orders table.
*   [03_silver_tables.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/snowflake/ddl/03_silver_tables.sql): Creates the silver orders table.
*   [06_gold_plain_tables.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/snowflake/ddl/06_gold_plain_tables.sql): [NEW] Creates the plain SQL gold table.
*   [stage_setup.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/snowflake/loads/stage_setup.sql): Configures stage and formats.
*   [load_raw_orders.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/snowflake/loads/load_raw_orders.sql): Loads raw orders from the stage.
*   [raw_to_silver.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/snowflake/transforms/raw_to_silver.sql): Cleans and deduplicates data.
*   [silver_to_gold_plain.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/snowflake/transforms/silver_to_gold_plain.sql): [NEW] Overwrites gold aggregation from silver.
*   [runbook.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/planning/spec-02-raw-to-silver-gold-snowflake/runbook.md): Steps to deploy and verify this milestone.
