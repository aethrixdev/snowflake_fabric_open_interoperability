# spec-02-raw-to-silver-gold-snowflake — Revision Log

This log documents the deployment steps, validation runs, and adjustments made during the Ingestion and Processing milestone.

## Ingestion Log

1.  **Staged Data Upload**: Successfully uploaded `data/sample_orders.csv` to `raw/sample_orders.csv` in the Azure storage container using the Azure CLI.
2.  **Schema Provisioning**: Created the logical schemas (`staging`, `raw`, `silver`, `gold`) in the Snowflake database `ecommerce_demo`.
3.  **Table Provisioning**:
    *   Created row-oriented table `raw.raw_orders` with string data types to allow robust, crash-free loading of raw formats.
    *   Created type-enforced table `silver.silver_orders` with constraints (dates, numbers, lowercase trims, primary keys).
    *   Created plain SQL aggregate table `gold.revenue_by_country_by_month`.
4.  **Ingestion Execution**: Created the stage `staging.raw_orders_stage` and CSV file format `staging.raw_csv_format`. Ran the `COPY INTO` script, loading exactly 20 records.
5.  **Refinement Execution**: Ran the incremental `MERGE` transformation script `snowflake/transforms/raw_to_silver.sql` (resulting in exactly 15 rows).
6.  **Gold Aggregation**: Ran the transform script `snowflake/transforms/silver_to_gold_plain.sql` to populate the plain SQL Gold table (resulting in exactly 7 rows).

## Verification Results

*   **Raw Table Verification**: Confirmed that `raw.raw_orders` contains exactly **20** rows.
*   **Silver Table Verification**: Confirmed that `silver.silver_orders` contains exactly **15** rows after deduplicating the data and cleaning nulls or bad values.
*   **Gold Table Verification**: Confirmed that `gold.revenue_by_country_by_month` contains exactly **7** rows after aggregating the completed silver orders by country and calendar month.

## Revisions and Lessons Learned

*   **File Format Parameter error**: The file format script originally contained the option `ERROR_ON_COLUMN_MISMATCH = FALSE`. This is invalid in Snowflake for standard CSV formats (only supported for semi-structured formats). It was removed from [stage_setup.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/snowflake/loads/stage_setup.sql) to prevent compilation failures.
*   **Database Schema permissions**: Creating a schema requires the `CREATE SCHEMA` database-level privilege. Since the database was owned by `ACCOUNTADMIN`, we had to explicitly grant `CREATE SCHEMA ON DATABASE ecommerce_demo TO ROLE SYSADMIN` inside [02_grants.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/infra/snowflake/02_grants.sql) before executing schema provisioning.
*   **Python Virtual Environment**: Since python libraries on macOS are managed by Homebrew, all DDL/grants/verification commands were run using the virtual environment's python interpreter (`./.venv/bin/python`) instead of the system-wide `python3` to avoid environment isolation crashes.
