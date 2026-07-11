# spec-07-powerbi-direct-lake-dashboard — Runbook

This runbook outlines the steps to set up the Power BI semantic model, design the dashboard, and execute the end-to-end refresh test.

---

## Step 1: Create the Semantic Model (Manual Browser Steps)

1. Open the Microsoft Fabric Portal and navigate to your Lakehouse `interop_lakehouse`.
2. Follow the instructions in [Power BI Guide](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/fabric/powerbi/README.md) to create the semantic model `revenue_by_country_model` containing the `revenue_by_country_delta` table.

---

## Step 2: Build the Power BI Report (Manual Browser Steps)

1. In the semantic model page, click **New Report**.
2. Build the three visuals described in the [Power BI Guide](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/fabric/powerbi/README.md):
   - Column Chart: `TOTAL_REVENUE` by `COUNTRY`
   - Card: `TOTAL_ORDERS` (labeled: Total Orders)
   - Card: `LAST_UPDATED_AT` (labeled: Last Pipeline Run)
3. Save the report inside your Fabric workspace as `Sales Revenue Dashboard`.

---

## Step 3: Verify Real-Time Data Flow (Direct Lake Test) (CLI + Browser)

1. Check your current dashboard values (e.g. Note down the Total Orders and Revenue values).
2. **Execute Snowflake Update**: Run the pipeline in your terminal:
   ```bash
   ./scripts/run_pipeline.sh
   ```
3. **Execute Sync Notebook**: Go to Fabric in the browser, run the `02_read_delta_shortcut_and_sync` notebook.
4. **View Dashboard**: Open the `Sales Revenue Dashboard` report and click the **Refresh** button on the top menu bar.
5. **Verify**: Check that the numbers on the cards have increased and match the console validation script output from Step 4 of the [spec-05-live-interop-validation Runbook](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/planning/spec-05-live-interop-validation/runbook.md).
