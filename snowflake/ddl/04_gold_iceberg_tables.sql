-- DDL for Gold Iceberg Tables (Snowflake-managed Catalog)
-- Run this using the role specified in SNOWFLAKE_ROLE

USE DATABASE ${SNOWFLAKE_DATABASE};
USE SCHEMA gold;

-- Create the Iceberg table using Snowflake catalog and pointing to the ADLS Gen2 external volume
CREATE OR REPLACE ICEBERG TABLE revenue_by_country_iceberg (
  country VARCHAR,
  total_revenue NUMBER(38,2),
  total_orders INT,
  last_updated_at TIMESTAMP_NTZ
)
CATALOG = 'SNOWFLAKE'
EXTERNAL_VOLUME = '${SNOWFLAKE_EXTERNAL_VOLUME}'
BASE_LOCATION = '${ICEBERG_GOLD_BASE_LOCATION}';

SELECT 'Table gold.revenue_by_country_iceberg successfully created' AS status;
