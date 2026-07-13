# spec-08-teardown-and-writeup — Revision Log

This log documents the teardown of all cloud infrastructure and Fabric artifacts.

## Execution Log

1.  **Automated Teardown**: Executed `infra/teardown.sh` to clean up the Snowflake external volume, storage integration, databases, and the Azure Resource Group (which cascadingly deleted the storage account and container).
2.  **Fabric Artifact Cleanup**: Manually deleted the Power BI dashboard, semantic model, notebooks, and Lakehouse from the Microsoft Fabric workspace via the browser UI.

## Verification Results

*   **Azure Cleanup**: Executed the validation script `az group show --name "$AZURE_RESOURCE_GROUP"` and confirmed the output: `SUCCESS: Resource Group is gone.`
*   **Snowflake Cleanup**: Confirmed via Snowflake UI that the `ecommerce_demo` database, external volume, and storage integration were successfully dropped.

## Revisions and Lessons Learned

*   **Fabric Limitations**: Microsoft Fabric workspace resources currently cannot be easily deleted via CLI natively, requiring manual browser cleanup. If isolating project assets, it is highly recommended to create a dedicated Fabric workspace that can be deleted entirely rather than picking off individual artifacts.
