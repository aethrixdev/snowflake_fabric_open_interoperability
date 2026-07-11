# spec-04-fabric-shortcut-and-notebook-read — Runbook

This runbook outlines the manual browser steps in Microsoft Fabric and execution of Spark notebooks to verify Iceberg reads and Delta writes.

---

## Step 1: Create OneLake Shortcuts (Manual Browser Steps)

1. Follow the step-by-step instructions in the [OneLake Shortcut Guide](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/fabric/shortcuts/shortcut_config.md) to set up:
   - Shortcut `revenue_by_country_iceberg` pointing to the actual ADLS Gen2 path including Snowflake's random suffix (e.g. `gold/revenue_by_country_iceberg.<random_suffix>/`). Do NOT use the literal `gold/revenue_by_country_iceberg/` path.
   - Shortcut `revenue_by_country_delta` pointing to the ADLS Gen2 path `gold/revenue_by_country_delta/` (which is written directly by Fabric and has no random suffix).
2. Confirm both shortcuts appear under the **Tables** folder in the Microsoft Fabric Lakehouse UI.

---

## Step 2: Create and Execute Iceberg Read Notebook (Manual Browser Steps)

1. In your Fabric Workspace, click **+ New** -> **Notebook**.
2. Rename the notebook to `01_read_iceberg_shortcut`.
3. In the first code cell, copy and paste the contents of [read_iceberg_shortcut.py](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/fabric/notebooks/read_iceberg_shortcut.py).
4. Select the Lakehouse `interop_lakehouse` on the left explorer to attach it.
5. Click **Run All** (or run the cell) and confirm:
   - Output includes the table schema: `country: string`, `total_revenue: decimal`, `total_orders: long`, etc.
   - Output lists the aggregated sales data (e.g. United States, Canada, France, Germany, Australia, Japan) and their matching counts.

---

## Step 3: Create and Execute Delta Sync Notebook (Manual Browser Steps)

1. In your Fabric Workspace, click **+ New** -> **Notebook**.
2. Rename the notebook to `02_read_delta_shortcut_and_sync`.
3. Copy and paste the contents of [read_delta_shortcut.py](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/fabric/notebooks/read_delta_shortcut.py) into the first cell.
4. **Update Configuration**: Edit the variables at the top of the cell:
   - `AZURE_STORAGE_ACCOUNT` (Your storage account name from `.env`)
   - `AZURE_STORAGE_CONTAINER` (Your container name, e.g. `lakehouse`)
   - `AZURE_TENANT_ID` (Your tenant ID)
   - `AZURE_SP_CLIENT_ID` (Your Service Principal Client ID)
   - `AZURE_SP_CLIENT_SECRET` (Your Service Principal Client Secret)
5. Attach the `interop_lakehouse` Lakehouse.
6. Click **Run All** and verify:
   - The cell executes successfully without credential failures.
   - The sync output reads the Iceberg data, writes it to Delta format, and reads it back successfully.

---

## Step 4: Verify Delta Lake Creation in ADLS Gen2 (CLI)

Run the following command in your terminal to verify that the Delta Lake files and transaction log folder were written to your storage container:
```bash
# Load env variables
export $(grep -v '^#' .env | xargs)

# Retrieve account key for direct query
ACCOUNT_KEY=$(az storage account keys list --resource-group "$AZURE_RESOURCE_GROUP" --account-name "$AZURE_STORAGE_ACCOUNT" --query "[0].value" -o tsv)

echo "Listing Gold Delta files..."
az storage blob list \
  --container-name "$AZURE_STORAGE_CONTAINER" \
  --account-name "$AZURE_STORAGE_ACCOUNT" \
  --account-key "$ACCOUNT_KEY" \
  --prefix "gold/revenue_by_country_delta/" \
  --query "[].name" \
  -o table
```

**Verification Criteria**:
- You must see a folder prefix named `gold/revenue_by_country_delta/_delta_log/` containing a json transaction log file (e.g., `00000000000000000000.json`).
- You must see Parquet data files (e.g., `part-00000-....snappy.parquet`) under `gold/revenue_by_country_delta/`.
