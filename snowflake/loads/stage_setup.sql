-- External Stage and File Format Setup
-- Run this using the role specified in SNOWFLAKE_ROLE

USE DATABASE ${SNOWFLAKE_DATABASE};
USE SCHEMA staging;

-- 1. Create file format for CSV parsing
CREATE OR REPLACE FILE FORMAT raw_csv_format
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('NULL', 'null', '')
  EMPTY_FIELD_AS_NULL = TRUE;

-- 2. Create external stage pointing to the raw/ directory in ADLS Gen2
CREATE OR REPLACE STAGE raw_orders_stage
  URL = 'azure://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_STORAGE_CONTAINER}/raw/'
  STORAGE_INTEGRATION = ${SNOWFLAKE_STORAGE_INTEGRATION}
  FILE_FORMAT = raw_csv_format;

SELECT 'Stage staging.raw_orders_stage and file format raw_csv_format successfully created' AS status;
