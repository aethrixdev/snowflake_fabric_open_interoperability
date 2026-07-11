-- DDL for Gold Plain SQL Tables (Standard Snowflake Tables)
-- Run this using the role specified in SNOWFLAKE_ROLE

USE DATABASE ${SNOWFLAKE_DATABASE};
USE SCHEMA gold;

CREATE OR REPLACE TABLE revenue_by_country_by_month (
  country VARCHAR(100) NOT NULL,
  calendar_month DATE NOT NULL,
  total_revenue NUMBER(18,2) NOT NULL,
  total_orders INT NOT NULL,
  last_updated_at TIMESTAMP_NTZ DEFAULT TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP())
);

SELECT 'Table gold.revenue_by_country_by_month successfully created' AS status;
