-- Transform: Refresh Delta external table
-- Run this using the role specified in SNOWFLAKE_ROLE

USE DATABASE ${SNOWFLAKE_DATABASE};
USE SCHEMA gold;

-- Trigger Delta transaction log scan to pull any updates written by Microsoft Fabric
-- NOTE: This command will fail with 'Failed to find the metadata of Delta table'
-- in Snowflake worksheets until Microsoft Fabric writes the first transaction log files
-- to the ADLS container at gold/revenue_by_country_delta/_delta_log/. This is expected.
ALTER EXTERNAL TABLE revenue_by_country_delta REFRESH;

-- Select output rows to verify (will return empty if Fabric has not written yet)
SELECT * FROM revenue_by_country_delta;
