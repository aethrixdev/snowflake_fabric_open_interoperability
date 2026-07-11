# spec-03-iceberg-and-delta-gold-conversion — Spec

## Overview
This milestone transitions the pipeline from standard Snowflake tables to open table formats. We create the Gold aggregation layers in both Apache Iceberg (managed by Snowflake) and Delta Lake (external to Snowflake, managed by Microsoft Fabric) formats. This enables bi-directional read-write access to open data formats across engines.

## What This Milestone Builds
1.  **Gold Apache Iceberg Table (Snowflake-Managed)**:
    *   An Iceberg table `gold.revenue_by_country_iceberg` created using the Snowflake-managed catalog, an Azure External Volume, and a base directory location.
    *   A transform script `silver_to_gold_iceberg.sql` to aggregate COMPLETED orders from Silver (total revenue and order count grouped by country) and write them directly into the Iceberg table in ADLS Gen2.
2.  **Gold Delta Table Integration (Fabric-Managed / Snowflake External)**:
    *   A general container-level external stage `gold.azure_lakehouse_stage` inside Snowflake.
    *   An external table `gold.revenue_by_country_delta` referencing Delta table files in ADLS Gen2 (`gold/revenue_by_country_delta/`).
    *   A refresh script `silver_to_gold_delta.sql` to sync the Delta transaction log and update Snowflake's external table metadata cache.
3.  **Physical Path Discovery**:
    *   A verification step using the Azure CLI and storage account keys to list the container and capture Snowflake's random 8-character suffix appended to the Iceberg table's physical directory path (e.g., `gold/revenue_by_country_iceberg.HgOpISFG/`).

## What "Done" Looks Like
*   `gold.revenue_by_country_iceberg` is successfully defined and populated with 6 aggregate records (representing sales by country) inside Snowflake.
*   Physical Parquet files and metadata files (`.metadata.json`, `.avro`) are verified to exist in the ADLS Gen2 container under the dynamically generated `gold/revenue_by_country_iceberg.<random_suffix>/` folder.
*   `gold.revenue_by_country_delta` is defined in Snowflake pointing to the Delta location (which will initially read 0 rows since Fabric has not written to it yet).
*   The runbook executes successfully with zero errors.

## Target Files to Implement
*   [spec.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/planning/spec-03-iceberg-and-delta-gold-conversion/spec.md): This spec file.
*   [04_gold_iceberg_tables.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/snowflake/ddl/04_gold_iceberg_tables.sql): DDL for creating the Gold Iceberg table.
*   [05_gold_delta_tables.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/snowflake/ddl/05_gold_delta_tables.sql): DDL for stage and Delta Lake external table.
*   [silver_to_gold_iceberg.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/snowflake/transforms/silver_to_gold_iceberg.sql): SQL query to aggregate Silver data and overwrite Iceberg.
*   [silver_to_gold_delta.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/snowflake/transforms/silver_to_gold_delta.sql): SQL query to refresh Delta table metadata cache.
*   [runbook.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/planning/spec-03-iceberg-and-delta-gold-conversion/runbook.md): Steps to deploy and verify this milestone.
