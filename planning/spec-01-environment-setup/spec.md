# spec-01-environment-setup — Spec

## Overview
This milestone establishes the base infrastructure in Microsoft Azure and Snowflake required for open table format interoperability. It sets up the cloud storage (ADLS Gen2), identity management (Service Principal), and Snowflake storage integrations/external volumes.

## What This Milestone Builds
1. **Azure Storage Infrastructure**:
   - Azure Resource Group.
   - Azure Data Lake Storage Gen2 (ADLS Gen2) Storage Account with hierarchical namespace enabled.
   - A storage container acting as our data lakehouse root.
2. **Azure Identity & Access Management**:
   - An Azure Active Directory (Entra ID) Service Principal (used by Microsoft Fabric to read/write the lakehouse container).
   - Role assignment: `Storage Blob Data Contributor` granted to the Service Principal for the storage container.
3. **Snowflake Infrastructure**:
   - Dedicated database, schema, and virtual warehouse.
   - A Snowflake **Storage Integration** mapped to the ADLS Gen2 container (for traditional copy/unload and Delta integration).
   - A Snowflake **External Volume** mapped to the ADLS Gen2 container (specifically for Apache Iceberg tables).
   - Permissions setup to grant the target Snowflake role access to these resources.
4. **Snowflake Authentication & Consent**:
   - Instructions and mechanism for the administrator to consent to the Snowflake multi-tenant application in Azure.
   - Trust relationship established in Azure IAM by granting Snowflake's multi-tenant app registration `Storage Blob Data Contributor` permissions on the ADLS Gen2 storage account.

## What "Done" Looks Like
- All resources are deployed and active in Azure and Snowflake.
- Snowflake's trust relationship is established, and consent is granted.
- The verification queries run successfully:
  1. A test CSV file is written to ADLS Gen2 and listed back via the Storage Integration and Stage, proving storage integration write access.
  2. A temporary Iceberg table (`_verify_iceberg_ext_vol`) is created using the External Volume, one row is inserted, the presence of `data/` and `metadata/` folders under the container is confirmed (via Azure CLI storage blob listing in the runbook), and the table is dropped.
- No hardcoded secrets or credentials exist in the repository; all scripts dynamically read from `.env` using environment variables.

## Target Files to Implement
- [create_storage_account.sh](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/infra/azure/create_storage_account.sh): Shell script to provision Azure Resource Group, ADLS Gen2 Storage Account, and container.
- [create_service_principal.sh](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/infra/azure/create_service_principal.sh): Shell script to provision the Azure Service Principal and assign the storage contributor role.
- [01_storage_integration.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/infra/snowflake/01_storage_integration.sql): SQL script (run as `ACCOUNTADMIN`) to create the Storage Integration and External Volume.
- [02_grants.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/infra/snowflake/02_grants.sql): SQL script to set up database, schemas, warehouse, and grant privileges to the target developer role.
- [03_verify_integration.sql](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/infra/snowflake/03_verify_integration.sql): SQL script to execute a test write (`COPY INTO`) to the Azure storage location via the Storage Integration to verify end-to-end write permissions.
