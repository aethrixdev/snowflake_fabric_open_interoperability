-- Verify Snowflake <-> ADLS connectivity
-- Run this using the target developer role (e.g. SYSADMIN) to ensure grants are correct.

USE ROLE ${SNOWFLAKE_ROLE};
USE WAREHOUSE ${SNOWFLAKE_WAREHOUSE};
USE DATABASE ${SNOWFLAKE_DATABASE};
USE SCHEMA public;

-- ============================================================================
-- VERIFICATION 1: Storage Integration (Stage & COPY INTO Write)
-- ============================================================================

-- 1. Create a temporary stage referencing our storage integration
CREATE OR REPLACE STAGE verify_azure_stage
  URL = 'azure://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_STORAGE_CONTAINER}/verify_stage/'
  STORAGE_INTEGRATION = ${SNOWFLAKE_STORAGE_INTEGRATION};

-- 2. Perform a test write to the stage by copying dummy data into a CSV file
COPY INTO @verify_azure_stage/test_connection_write.csv FROM (
  SELECT 'storage_integration_ok' AS col1, CURRENT_TIMESTAMP() AS col2
)
FILE_FORMAT = (TYPE = CSV)
SINGLE = TRUE
OVERWRITE = TRUE;

-- 3. List the stage to verify that the file can be read back by Snowflake
LIST @verify_azure_stage;

-- ============================================================================
-- VERIFICATION 2: External Volume (Iceberg Table Write)
-- ============================================================================

-- 1. Create a temporary Iceberg table referencing our external volume
CREATE OR REPLACE ICEBERG TABLE _verify_iceberg_ext_vol (
  id INT,
  test_val VARCHAR,
  inserted_at TIMESTAMP_NTZ
)
CATALOG = 'SNOWFLAKE'
EXTERNAL_VOLUME = '${SNOWFLAKE_EXTERNAL_VOLUME}'
BASE_LOCATION = 'verify_iceberg/';

-- 2. Insert a test row into the Iceberg table
INSERT INTO _verify_iceberg_ext_vol (id, test_val, inserted_at)
VALUES (1, 'iceberg_external_volume_ok', TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP()));

-- 3. Query the Iceberg table to verify local metadata reads work
SELECT * FROM _verify_iceberg_ext_vol;

-- ============================================================================
-- CLEANUP
-- ============================================================================
-- [CRITICAL NOTE] Check Azure blob storage BEFORE running these drops to confirm 
-- that the folders and files actually appeared in ADLS Gen2!
--
-- RUN THIS TO CLEAN UP:
-- DROP TABLE IF EXISTS _verify_iceberg_ext_vol;
-- DROP STAGE IF EXISTS verify_azure_stage;
