# spec-07-powerbi-direct-lake-dashboard — Spec

## Overview
This milestone establishes the business intelligence (BI) consumption layer. It leverages Microsoft Fabric's Direct Lake mode to build a real-time Power BI dashboard directly over the synced Delta table, showing end-to-end data flow from raw entry to visual insights without traditional extract, transform, load (ETL) data movement or scheduled refreshes.

## What This Milestone Builds
1. **OneLake Direct Lake Semantic Model**:
   - Instructions to provision a custom Power BI semantic model (`revenue_by_country_semantic_model`) inside the Fabric workspace that directly reads Delta Lake parquet files from OneLake.
2. **Power BI Report Dashboard**:
   - Guidelines for constructing a Power BI dashboard with visual components:
     - **Revenue by Country** (Clustered Column Chart or Map Visual).
     - **Total Order Volume** (KPI Card).
     - **Data Freshness Timestamp** (Card showing `last_updated_at`).
3. **End-to-End Refresh Verification**:
   - Verification procedures showing that inserting new rows in Snowflake and running the sync pipeline automatically updates the Power BI dashboard visualizations instantly via Direct Lake mode, without needing a Power BI import model refresh.

## What "Done" Looks Like
- A semantic model is configured in the Fabric Lakehouse using the `revenue_by_country_delta` table.
- A Power BI report is created and published in the workspace.
- The dashboard successfully renders country-level aggregated sales data.
- Row counts in the dashboard visuals match the validation script results.

## Target Files to Implement
- [spec.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/planning/spec-07-powerbi-direct-lake-dashboard/spec.md): This file, defining the spec.
- [README.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/fabric/powerbi/README.md): Step-by-step setup guide for the Direct Lake semantic model and Power BI report.
- [runbook.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/planning/spec-07-powerbi-direct-lake-dashboard/runbook.md): Runbook detailing manual steps to configure the semantic model, design the dashboard, and test real-time data flow.
