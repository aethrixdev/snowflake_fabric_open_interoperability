-- DDL for Raw Tables
-- Run this using the role specified in SNOWFLAKE_ROLE

USE DATABASE ${SNOWFLAKE_DATABASE};
USE SCHEMA raw;

-- Create raw orders table with all string types to avoid ingestion crashes
CREATE OR REPLACE TABLE raw_orders (
  order_id VARCHAR,
  customer_id VARCHAR,
  order_date VARCHAR,
  country VARCHAR,
  amount VARCHAR,
  status VARCHAR,
  email VARCHAR,
  _ingested_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);

SELECT 'Table raw.raw_orders successfully created' AS status;
