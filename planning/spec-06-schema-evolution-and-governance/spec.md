# spec-06-schema-evolution-and-governance — Spec

## Overview
This milestone demonstrates advanced data engineering capabilities: Schema Evolution and Data Governance. It shows how Iceberg tables handle schema shifts (adding columns) and how Snowflake applies masking policies to sensitive customer columns (email) to enforce privacy without moving data.

## What This Milestone Builds
1. **Iceberg Schema Evolution**:
   - A SQL script `schema_evolution_demo.sql` that alters the `gold.revenue_by_country_iceberg` table to add a new metric column: `discount_amount NUMBER(18,2)`.
   - Populates this new column with simulated values (e.g. 5% of total revenue) and queries the results to verify that Iceberg metadata handles schema changes seamlessly without table re-creation.
2. **Data Governance & Privacy (Data Masking)**:
   - A SQL script `masking_policy_email.sql` that creates a dynamic masking policy `email_mask` inside Snowflake.
   - Applies the masking policy to the `email` column in the `silver.silver_orders` table.
   - The policy ensures that users in administrative roles (`ACCOUNTADMIN`, `SYSADMIN`) see the raw email addresses, while lower-privileged roles see only masked values (e.g., `*********@domain.com`).

## What "Done" Looks Like
- The `discount_amount` column is successfully added to the Iceberg table, populated, and queried.
- OneLake Iceberg shortcut detects this new column in Fabric (since Iceberg schema definitions are stored in metadata files).
- The masking policy is active in Snowflake: queries by `SYSADMIN` show cleartext emails, whereas queries by lower roles show masked emails.

## Target Files to Implement
- [spec.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/planning/spec-06-schema-evolution-and-governance/spec.md): This file, defining the spec.
- [schema_evolution_demo.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/snowflake/transforms/schema_evolution_demo.sql): SQL script implementing and testing Iceberg schema evolution.
- [masking_policy_email.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/snowflake/governance/masking_policy_email.sql): SQL script implementing and testing column-level email masking.
- [runbook.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/planning/spec-06-schema-evolution-and-governance/runbook.md): Runbook executing and verifying schema evolution and masking policies.
