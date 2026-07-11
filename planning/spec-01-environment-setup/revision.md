# spec-01-environment-setup — Revision Log

This log documents the actual deployment steps and results of the Environment Setup milestone.

## Deployment Log

*   **Azure Resource Group**: Created `rg-lakehouse-demo` in `eastus2`.
*   **Azure ADLS Gen2 Storage Account**: Created `lakehousetr202607` with Hierarchical Namespace enabled.
*   **Azure Storage Container**: Created `lakehouse`.
*   **Entra ID Service Principal**: Created `sp-snowflake-fabric-interop` (App ID `1a871b9d-5f98-4852-ab4c-6a55938f9399`) and granted it `Storage Blob Data Contributor` scoped to the container.
*   **Snowflake Storage Integration**: Created `azure_lakehouse_int` and granted it usage to `SYSADMIN`.
*   **Snowflake External Volume**: Created `iceberg_ext_vol` and granted it usage to `SYSADMIN`.
*   **Snowflake App Consent**: Completed.
*   **Snowflake Role Assignment**: Programmatically assigned `Storage Blob Data Contributor` to the Snowflake multi-tenant application `vc7lxdsnowflakepacint` (Object ID `f6c51acb-caa3-47ca-b581-36e79e86b0d5`) at the Storage Account level.

## Verification Results

### 1. Storage Integration Verification
*   Successfully created stage `verify_azure_stage`.
*   Successfully executed `COPY INTO` to write `verify_stage/test_connection_write.csv`.
*   Successfully verified file existence in ADLS Gen2 container.

### 2. External Volume Verification
*   Successfully created Iceberg table `_verify_iceberg_ext_vol`.
*   Successfully inserted a row and read it back: `[(1, 'iceberg_external_volume_ok', datetime.datetime(2026, 7, 9, 6, 2, 49, 92000))]`.
*   Successfully verified that Snowflake created the Iceberg data directory `verify_iceberg.<random_suffix>/data/` and metadata files `verify_iceberg.<random_suffix>/metadata/` in the ADLS Gen2 container.

## Revisions and Lessons Learned
*   **Provider Registration**: The storage account creation failed initially because the `Microsoft.Storage` provider was `NotRegistered` in the target subscription. This was programmatically registered and monitored until completion.
*   **Snowflake Grants**: The default schema usage was insufficient. We had to grant explicit `CREATE STAGE`, `CREATE TABLE`, and `CREATE ICEBERG TABLE` privileges to `SYSADMIN` on `ecommerce_demo.public` before verification could run.
*   **Snowflake App IAM Role**: Snowflake app name search is slow/inconsistent in the Azure Portal IAM UI. Performing the role assignment programmatically using the Azure CLI via `az role assignment create` using the principal object ID is faster, more reliable, and bypasses portal indexing delays.
*   **Iceberg Random Suffix**: Snowflake-managed Iceberg tables append a random 8-character alphanumeric suffix to the specified `BASE_LOCATION` in ADLS Gen2 (observed: `verify_iceberg/` became `verify_iceberg.HgOpISFG/`). This means the literal `BASE_LOCATION` string in the `CREATE ICEBERG TABLE` statement is not the real physical path. For future milestones (e.g., spec-03, spec-04), we must dynamically discover the physical path (e.g., via `az storage blob list`) after table creation before setting up any Microsoft Fabric OneLake shortcuts, rather than assuming it matches the `BASE_LOCATION` verbatim.
