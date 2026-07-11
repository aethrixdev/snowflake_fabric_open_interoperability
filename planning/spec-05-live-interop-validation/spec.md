# spec-05-live-interop-validation — Spec

## Overview
This milestone builds the automated execution pipeline and cross-engine validation layers. It simulates real-time business activities by generating live transaction updates, pushing them through Snowflake, syncing them through Fabric, and verifying data consistency across both engines.

## What This Milestone Builds
1. **Live Row Generator**:
   - A Python script `generate_live_update.py` to dynamically generate new transaction data and write to `data/live_orders_update.csv`.
2. **Snowflake Pipeline Automator**:
   - A shell script `run_pipeline.sh` that generates the live updates, uploads the file to ADLS Gen2 `raw/` prefix, and executes the Snowflake SQL commands to ingest the updates, merge them into Silver, and overwrite the Gold Iceberg table.
3. **Cross-Engine Verification (Snowflake)**:
   - A Python script `validate_interop.py` that queries both the Snowflake-managed Gold Iceberg table and the external Delta table to verify that their record counts and aggregated order sums align perfectly.
4. **Cross-Engine Verification (Fabric)**:
   - A Python Spark script `compare_row_counts.py` that reads both the Iceberg shortcut table and Delta tables in Fabric to confirm data alignment.

## What "Done" Looks Like
- `run_pipeline.sh` runs successfully, feeding new records into Snowflake.
- Fabric notebook executes, syncing the new Iceberg data to Delta format.
- Snowflake's external table `revenue_by_country_delta` is refreshed.
- `validate_interop.py` successfully completes, printing row counts and verifying that the Iceberg table and Delta external table match row-for-row.

## Target Files to Implement
- [spec.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/planning/spec-05-live-interop-validation/spec.md): This file, defining the spec.
- [run_pipeline.sh](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/scripts/run_pipeline.sh): Shell script orchestrating the Snowflake pipeline.
- [generate_live_update.py](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/data/generate_live_update.py): Python script creating live row updates.
- [validate_interop.py](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/scripts/validate_interop.py): Python script validating counts in Snowflake.
- [compare_row_counts.py](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/fabric/notebooks/compare_row_counts.py): Spark script comparing counts in Fabric.
- [runbook.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/planning/spec-05-live-interop-validation/runbook.md): Reproducible steps to validate interop.
