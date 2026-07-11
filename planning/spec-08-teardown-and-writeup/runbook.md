# spec-08-teardown-and-writeup — Runbook

This runbook guides you through cleaning up all cloud infrastructure assets and deleting Fabric artifacts to avoid charges.

---

## Step 1: Execute Automated Teardown Script (CLI)

Run the teardown script in your terminal to delete all Snowflake objects, the Azure service principal, and the Resource Group:
```bash
# Set execute permissions
chmod +x infra/teardown.sh

# Run teardown
./infra/teardown.sh
```

---

## Step 2: Delete Microsoft Fabric Objects (Manual Browser Steps)

Since Microsoft Fabric workspace resources cannot be easily deleted via CLI, you must clean them up in the browser:

1. Open your browser and navigate to the **Microsoft Fabric Workspace**.
2. Click on the **Workspace Settings** or go to the item list.
3. Delete the following items (click the ellipsis `...` next to each and select **Delete**):
   - Power BI Report: `Sales Revenue Dashboard`
   - Power BI Semantic Model: `revenue_by_country_model`
   - Sync Notebook: `02_read_delta_shortcut_and_sync`
   - Read Notebook: `01_read_iceberg_shortcut`
   - Compare Notebook: `03_compare_row_counts`
   - Lakehouse: `interop_lakehouse`
4. If you created a temporary Fabric workspace specifically for this project, you can delete the entire workspace under **Workspace settings** -> **Other** -> **Remove this workspace**.

---

## Step 3: Verify Cleanup (CLI)

Confirm that Azure has no remaining resources:
```bash
export $(grep -v '^#' .env | xargs)

echo "Checking if Azure Resource Group exists..."
if ! az group show --name "$AZURE_RESOURCE_GROUP" &>/dev/null; then
  echo "SUCCESS: Resource Group is gone."
else
  echo "WARNING: Resource Group still exists."
fi
```
