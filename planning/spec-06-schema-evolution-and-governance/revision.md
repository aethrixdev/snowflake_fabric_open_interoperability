# spec-06-schema-evolution-and-governance — Revision Log

This log documents the implementation and testing of Iceberg schema evolution and Snowflake dynamic data masking.

## Execution Log

1.  **Schema Evolution**: Ran `schema_evolution_demo.sql` in Snowflake to add the `discount_amount` column to the `gold.revenue_by_country_iceberg` table and populate it with historical data.
2.  **Fabric Schema Detection**: Queried the Iceberg shortcut in Fabric Spark. The new `discount_amount` column was automatically detected without any manual schema updates required in Fabric.
3.  **Dynamic Data Masking**: 
    *   Created and applied the masking policy to `silver.silver_orders.email`.
    *   Created the `analyst_role`, granted it read access to the silver schema, and assigned it to the test user.
    *   Ran a `SELECT email` query using the `analyst_role` to verify.

## Verification Results

*   **Evolution Success**: Iceberg schema evolution propagated instantly to downstream consumers (Fabric) without breaking the pipeline.
*   **Masking Success**: Queries executed as `SYSADMIN` returned the raw email, while queries executed as `analyst_role` successfully returned masked values (`*********@example.com`).

## Revisions and Lessons Learned

*   **Governance Boundaries**: Masking policies applied in Snowflake restrict access internally, but if those masked columns are written to an external Iceberg file, the mask becomes hardcoded. We ensured our architecture aggregates sensitive data (Silver -> Gold) rather than exposing raw PII to Iceberg, keeping governance intact across the ecosystem.
