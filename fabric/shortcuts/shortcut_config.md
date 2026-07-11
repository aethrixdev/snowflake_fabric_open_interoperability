# Microsoft Fabric OneLake Shortcut Configuration Guide

Follow these steps in the Microsoft Fabric Portal to establish shortcuts to the ADLS Gen2 storage container.

---

## Prerequisites
1. You have created a Fabric Workspace (e.g. `interop_workspace`).
2. You have created a Fabric Lakehouse (e.g. `interop_lakehouse`) inside the workspace.
3. You have the ADLS Gen2 storage account URL (`https://<account>.blob.core.windows.net`) and the service principal credentials (`AZURE_SP_CLIENT_ID`, `AZURE_SP_CLIENT_SECRET`, `AZURE_TENANT_ID`).

---

## Step 1: Create the Iceberg Table Shortcut

1. Open your **Fabric Lakehouse** in the browser.
2. In the **Explorer** pane on the left, hover over the **Tables** folder, click the ellipsis (`...`), and select **New shortcut**.
3. Select **Azure Data Lake Storage Gen2** as the shortcut source.
4. Configure the connection settings:
   - **URL**: `https://<AZURE_STORAGE_ACCOUNT>.dfs.core.windows.net` (Replace with your actual storage account name)
   - **Connection**: Create a new connection or use an existing one.
   - **Authentication Kind**: Select **Service Principal**.
   - **Tenant ID**: Paste your `AZURE_TENANT_ID`.
   - **Client ID**: Paste your `AZURE_SP_CLIENT_ID` (App ID of the service principal).
   - **Client Secret**: Paste your `AZURE_SP_CLIENT_SECRET`.
5. Click **Next**.
6. Set the shortcut path and name:
    - **Subpath**: Select or paste `<AZURE_STORAGE_CONTAINER>/gold/revenue_by_country_iceberg.<random_suffix>/` (Make sure to retrieve the actual folder name generated in ADLS Gen2 by running the Step 4 verification command in the spec-03 runbook, e.g., `gold/revenue_by_country_iceberg.HgOpISFG/`. Do NOT use the literal `gold/revenue_by_country_iceberg/` path as it will not exist verbatim).
   - **Shortcut Name**: `revenue_by_country_iceberg`
7. Click **Create**.

---

## Step 2: Create the Delta Table Shortcut

Even though Fabric Spark can write directly to ADLS Gen2 via abfss paths, creating a shortcut inside your Lakehouse allows you to query it via the Fabric SQL Endpoint and load it directly into Power BI.

1. Hover over the **Tables** folder in the left Explorer pane of the Lakehouse, click `...`, and select **New shortcut**.
2. Select **Azure Data Lake Storage Gen2** and use the same ADLS connection created in Step 1.
3. Set the shortcut path:
   - **Subpath**: Select or paste `<AZURE_STORAGE_CONTAINER>/gold/revenue_by_country_delta/`
   - **Shortcut Name**: `revenue_by_country_delta`
4. Click **Create**.

---

## Step 3: Verification
- After creation, you should see both `revenue_by_country_iceberg` and `revenue_by_country_delta` under the **Tables** folder in the Lakehouse Explorer.
- The `revenue_by_country_iceberg` table will display data rows immediately after Snowflake writes to it.
- The `revenue_by_country_delta` table will initially appear empty or as an unrecognized table schema until the Sync Notebook runs and generates the Delta log files.
