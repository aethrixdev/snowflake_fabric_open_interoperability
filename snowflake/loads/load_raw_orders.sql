-- Load Raw Orders from ADLS Stage
-- Run this using the role specified in SNOWFLAKE_ROLE

USE DATABASE ${SNOWFLAKE_DATABASE};
USE SCHEMA raw;

-- Copy staged CSV orders files into raw_orders
COPY INTO raw_orders(order_id, customer_id, order_date, country, amount, status, email)
FROM (
  SELECT 
    t.$1, -- order_id
    t.$2, -- customer_id
    t.$3, -- order_date
    t.$4, -- country
    t.$5, -- amount
    t.$6, -- status
    t.$7  -- email
  FROM @staging.raw_orders_stage t
)
FILE_FORMAT = (FORMAT_NAME = 'staging.raw_csv_format')
PATTERN = '.*orders.*\.csv'
ON_ERROR = 'CONTINUE';

-- Select load statistics
SELECT COUNT(*) AS total_raw_records_after_load FROM raw_orders;
