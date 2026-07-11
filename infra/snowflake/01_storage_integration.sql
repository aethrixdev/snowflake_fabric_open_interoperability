-- Storage integration + external volume
-- Run this as ACCOUNTADMIN or a role with CREATE STORAGE INTEGRATION and CREATE EXTERNAL VOLUME privileges.

-- 1. Create the Storage Integration for Delta and standard loading/unloading
CREATE OR REPLACE STORAGE INTEGRATION ${SNOWFLAKE_STORAGE_INTEGRATION}
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'AZURE'
  ENABLED = TRUE
  AZURE_TENANT_ID = '${AZURE_TENANT_ID}'
  STORAGE_ALLOWED_LOCATIONS = ('azure://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_STORAGE_CONTAINER}/');

-- 2. Describe the storage integration to get consent credentials
DESCRIBE STORAGE INTEGRATION ${SNOWFLAKE_STORAGE_INTEGRATION};

-- 3. Create the External Volume for Iceberg tables
CREATE OR REPLACE EXTERNAL VOLUME ${SNOWFLAKE_EXTERNAL_VOLUME}
  STORAGE_LOCATIONS = (
    (
      NAME = 'adls_lakehouse_loc'
      STORAGE_PROVIDER = 'AZURE'
      STORAGE_BASE_URL = 'azure://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_STORAGE_CONTAINER}/'
      AZURE_TENANT_ID = '${AZURE_TENANT_ID}'
    )
  );

-- 4. Describe the external volume to get consent credentials (which may differ from storage integration)
DESCRIBE EXTERNAL VOLUME ${SNOWFLAKE_EXTERNAL_VOLUME};
