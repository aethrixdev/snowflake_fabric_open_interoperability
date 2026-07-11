-- Transform: Raw to Silver Orders Merge
-- Run this using the role specified in SNOWFLAKE_ROLE

USE DATABASE ${SNOWFLAKE_DATABASE};
USE SCHEMA silver;

-- Perform Merge to upsert data incrementally and ensure idempotency
MERGE INTO silver_orders AS target
USING (
  -- Deduplicate raw entries by order_id, taking the latest ingested row
  WITH cleaned_deduplicated AS (
    SELECT
      TRY_CAST(order_id AS INT) AS order_id,
      TRY_CAST(customer_id AS INT) AS customer_id,
      TRY_CAST(order_date AS DATE) AS order_date,
      TRIM(country) AS country,
      TRY_CAST(amount AS NUMBER(18,2)) AS amount,
      TRIM(status) AS status,
      TRIM(LOWER(email)) AS email,
      ROW_NUMBER() OVER (PARTITION BY TRY_CAST(order_id AS INT) ORDER BY _ingested_at DESC) AS rn
    FROM raw.raw_orders
    WHERE order_id IS NOT NULL
  )
  SELECT 
    order_id, 
    customer_id, 
    order_date, 
    country, 
    amount, 
    status, 
    email
  FROM cleaned_deduplicated
  WHERE rn = 1
    AND order_id IS NOT NULL
    AND customer_id IS NOT NULL
    AND order_date IS NOT NULL
    AND amount IS NOT NULL
    AND country != ''
    AND status != ''
) AS source
ON target.order_id = source.order_id
WHEN MATCHED THEN
  UPDATE SET
    target.customer_id = source.customer_id,
    target.order_date = source.order_date,
    target.country = source.country,
    target.amount = source.amount,
    target.status = source.status,
    target.email = source.email,
    target._updated_at = TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP())
WHEN NOT MATCHED THEN
  INSERT (order_id, customer_id, order_date, country, amount, status, email, _inserted_at, _updated_at)
  VALUES (
    source.order_id, 
    source.customer_id, 
    source.order_date, 
    source.country, 
    source.amount, 
    source.status, 
    source.email, 
    TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP()), 
    TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP())
  );

-- Select silver row count
SELECT COUNT(*) AS total_silver_records_after_merge FROM silver_orders;
