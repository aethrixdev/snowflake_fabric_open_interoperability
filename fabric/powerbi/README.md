# Power BI Direct Lake Dashboard Guide

This guide details how to build a high-performance **Direct Lake** Power BI report using the aggregated Delta table inside Microsoft Fabric.

---

## What is Direct Lake?
Direct Lake mode is an exclusive feature of Microsoft Fabric and Power BI. It allows Power BI to load parquet data files directly from OneLake without querying a SQL endpoint or importing data into a traditional Analysis Services cache. It provides the performance of **Import Mode** with the real-time freshness of **DirectQuery**.

---

## Step 1: Create a Custom Semantic Model

1. Navigate to your **Microsoft Fabric Workspace** and open `interop_lakehouse`.
2. On the top menu bar, click on **New semantic model**.
3. Configure the model:
   - **Name**: `revenue_by_country_model`
   - **Tables**: Check the box for `revenue_by_country_delta`.
4. Click **Confirm**. This creates the semantic model and opens the modeling screen.

---

## Step 2: Build the Power BI Report

1. Inside the semantic model modeling screen, click **New report** in the top action bar. This opens the Power BI report builder in your browser.
2. In the **Data** pane on the right, expand `revenue_by_country_delta`.
3. Create the following visualizations:
   
   ### Visual 1: Total Revenue by Country (Map or Bar Chart)
   - Click the **Clustered column chart** icon in the Visualizations pane.
   - Drag `COUNTRY` to the **X-axis** (or Location).
   - Drag `TOTAL_REVENUE` to the **Y-axis** (or Tooltips).
   - Format the chart title to: **Revenue by Country** and enable data labels.

   ### Visual 2: Key Metrics Cards (KPIs)
   - Click the **Card** visual icon.
   - Drag `TOTAL_ORDERS` to the Field. Rename the field label to **Total Orders**.
   - Create a second **Card** visual.
   - Drag `TOTAL_REVENUE` to the Field. Format it as Currency.

   ### Visual 3: Pipeline Freshness (Timestamp Card)
   - Click the **Card** visual icon.
   - Drag `LAST_UPDATED_AT` to the Field. Name the label **Last Pipeline Run**.

4. Click **File** -> **Save** -> Name the report: `Sales Revenue Dashboard` -> Select your workspace -> Click **Save**.

---

## Step 3: Test Real-Time Data Flow (Direct Lake Refresh)

To prove end-to-end data flow without refreshing Power BI:
1. Run a new data load inside Snowflake (using `./scripts/run_pipeline.sh`). This writes new data into `gold.revenue_by_country_iceberg`.
2. Run the Fabric sync notebook `02_read_delta_shortcut_and_sync` to update the Delta files in ADLS.
3. Open your published **Sales Revenue Dashboard** report in the browser.
4. Click **Refresh** at the top menu bar of the Power BI report.
5. Notice that the charts, total orders card, and revenue card update **instantly** to show the new aggregated metrics from Snowflake, proving that Direct Lake reads live storage directly without manual schema schedule refreshes!
