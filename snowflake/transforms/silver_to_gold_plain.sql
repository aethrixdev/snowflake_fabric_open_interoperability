-- Transform: Silver to Gold Plain Aggregation (by Country and Month)
-- Run this using the role specified in SNOWFLAKE_ROLE

USE DATABASE ${SNOWFLAKE_DATABASE};
USE SCHEMA gold;

INSERT OVERWRITE INTO revenue_by_country_by_month (country, calendar_month, total_revenue, total_orders, last_updated_at)
SELECT
  country,
  DATE_TRUNC('MONTH', order_date) AS calendar_month,
  SUM(amount) AS total_revenue,
  COUNT(*) AS total_orders,
  TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP()) AS last_updated_at
FROM silver.silver_orders
WHERE status = 'COMPLETED'
GROUP BY country, DATE_TRUNC('MONTH', order_date);

SELECT COUNT(*) AS total_gold_records_after_load FROM revenue_by_country_by_month;
