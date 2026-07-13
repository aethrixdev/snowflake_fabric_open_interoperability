# spec-07-powerbi-direct-lake-dashboard — Revision Log

This log documents the configuration and real-time testing of the Power BI Direct Lake integration.

## Execution Log

1.  **Semantic Model Creation**: Created `revenue_by_country_model` in Fabric using the Delta shortcut table.
2.  **Dashboard Construction**: Built the "Sales Revenue Dashboard" report containing a revenue column chart, total orders card, and a last pipeline run KPI card.
3.  **Real-Time Data Test**: 
    *   Noted baseline metrics on the dashboard.
    *   Ran the `./scripts/run_pipeline.sh` script to generate and ingest new data.
    *   Executed the Delta sync notebook in Fabric to update the Delta tables.
    *   Refreshed the Power BI dashboard in the browser.

## Verification Results

*   **Instant Freshness**: The Power BI dashboard immediately reflected the new metrics (increased Total Orders and Revenue) without requiring a heavy data import refresh. Direct Lake successfully read the updated Delta transaction logs directly from ADLS.

## Revisions and Lessons Learned

*   **Direct Lake Caching**: To ensure the dashboard shows the freshest data immediately after the Fabric sync notebook runs, triggering a semantic model refresh is required. This updates the model metadata to read the latest Delta transaction log, achieving instant freshness without executing SQL queries or importing rows.
