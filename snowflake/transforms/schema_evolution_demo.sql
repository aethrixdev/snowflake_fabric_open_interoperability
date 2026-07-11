-- Schema Evolution Demo: Adding Columns to Iceberg Tables
-- Run this using the role specified in SNOWFLAKE_ROLE

USE DATABASE ${SNOWFLAKE_DATABASE};
USE SCHEMA gold;

-- 1. Alter the Iceberg table to add a new column
ALTER ICEBERG TABLE revenue_by_country_iceberg ADD COLUMN tax_amount NUMBER(18,2);

-- 2. Populate the new column for existing records
UPDATE revenue_by_country_iceberg
SET tax_amount = total_revenue * 0.08;

-- 3. Query the Iceberg table to verify the new schema and values
SELECT 
  country, 
  total_revenue, 
  tax_amount, 
  total_orders 
FROM revenue_by_country_iceberg;
