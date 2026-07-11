# spec-03-iceberg-and-delta-gold-conversion — Revision Log

This log documents the deployment steps, validation runs, and adjustments made during the Iceberg and Delta conversion milestone.

## Ingestion & Integration Log

1.  **Gold Iceberg DDL**: Created `gold.revenue_by_country_iceberg` bound to the ADLS Gen2 external volume.
2.  **Gold Iceberg Transformation**: Executed [silver_to_gold_iceberg.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/snowflake/transforms/silver_to_gold_iceberg.sql) inside Snowflake to aggregate completed sales from the Silver table.
3.  **Delta Lake Stage**: Created the staging location `gold.azure_lakehouse_stage` pointing to the storage container.
4.  **Delta Lake External Table DDL**: Created `gold.revenue_by_country_delta` referencing `gold/revenue_by_country_delta/` in ADLS Gen2.
5.  **Delta Table Refresh**: Ran the Delta scan sync. As the path is empty (Fabric has not written yet), the empty check was handled gracefully (caught warning in the python script) without failing execution.

## Verification Results

*   **Iceberg Data Aggregation**: Confirmed Snowflake successfully wrote exactly **7 records** into the Iceberg table.
*   **Iceberg Physical Storage Location**: Verified files appeared in ADLS Gen2. Snowflake appended the dynamic suffix **`EVL46xbr`** to the base location.
    *   *Dynamic Path*: `gold/revenue_by_country_iceberg.EVL46xbr/`
    *   *Files Generated*: Parquet files under `data/`, avro schemas, and `.metadata.json` files under `metadata/`.
*   **Delta Integration Binding**: Confirmed Delta external table was compiled successfully on Snowflake.

## Revisions and Lessons Learned

*   **Delta DDL Mandatory Format**: Snowflake requires an explicit format declaration `FILE_FORMAT = (TYPE = PARQUET)` when creating an external table with `TABLE_FORMAT = DELTA`.
*   **Implicit Property Conflicts**: Snowflake's default behavior is to apply `AUTO_REFRESH = TRUE` and `REFRESH_ON_CREATE = TRUE` to external tables. However, these are strictly forbidden for Delta format tables. We explicitly configured `AUTO_REFRESH = FALSE` and `REFRESH_ON_CREATE = FALSE` in [05_gold_delta_tables.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/snowflake/ddl/05_gold_delta_tables.sql) to satisfy compiler validation.
*   **Empty Directory Refresh Failure**: Snowflake's Delta scanner triggers a `ProgrammingError: Failed to find the metadata of Delta table` if the transaction log directory (`_delta_log/`) does not exist yet. This is expected until Fabric executes its notebooks. We modified Step 3 of the runbook to trap this specific error and print a warning, preventing pipeline execution failure.
