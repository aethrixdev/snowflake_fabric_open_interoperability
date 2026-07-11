-- DDL for Silver Tables
-- Run this using the role specified in SNOWFLAKE_ROLE

USE DATABASE ${SNOWFLAKE_DATABASE};
USE SCHEMA silver;

-- Create cleaned, type-enforced silver orders table
CREATE OR REPLACE TABLE silver_orders (
  order_id INT PRIMARY KEY,
  customer_id INT NOT NULL,
  order_date DATE NOT NULL,
  country VARCHAR(100) NOT NULL,
  amount NUMBER(18,2) NOT NULL,
  status VARCHAR(50) NOT NULL,
  email VARCHAR(255) NOT NULL,
  _inserted_at TIMESTAMP_NTZ DEFAULT TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP()),
  _updated_at TIMESTAMP_NTZ DEFAULT TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP())
);

SELECT 'Table silver.silver_orders successfully created' AS status;
