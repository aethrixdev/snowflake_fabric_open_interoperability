-- DDL for Gold Delta External Tables
-- Run this using the role specified in SNOWFLAKE_ROLE

USE DATABASE ${SNOWFLAKE_DATABASE};
USE SCHEMA gold;

-- 1. Create a broader stage pointing to the container root to query any directory
CREATE OR REPLACE STAGE azure_lakehouse_stage
  URL = 'azure://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_STORAGE_CONTAINER}/'
  STORAGE_INTEGRATION = ${SNOWFLAKE_STORAGE_INTEGRATION};

-- 2. Create the external table referencing Delta format
-- (Microsoft Fabric will write to this ADLS location and Snowflake will read it)
CREATE OR REPLACE EXTERNAL TABLE revenue_by_country_delta
  LOCATION = @azure_lakehouse_stage/${DELTA_GOLD_BASE_LOCATION}
  FILE_FORMAT = (TYPE = PARQUET)
  AUTO_REFRESH = FALSE
  REFRESH_ON_CREATE = FALSE
  TABLE_FORMAT = DELTA;

SELECT 'Stage gold.azure_lakehouse_stage and External Table gold.revenue_by_country_delta successfully created' AS status;
