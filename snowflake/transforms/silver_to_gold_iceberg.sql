-- Transform: Silver to Gold Iceberg (Deduplicated Aggregations)
-- Run this using the role specified in SNOWFLAKE_ROLE

USE DATABASE ${SNOWFLAKE_DATABASE};
USE SCHEMA gold;

-- Insert aggregated revenue and orders stats by country for completed orders into the Iceberg table
INSERT OVERWRITE INTO revenue_by_country_iceberg (country, total_revenue, total_orders, last_updated_at)
SELECT
  country,
  SUM(amount) AS total_revenue,
  COUNT(*) AS total_orders,
  TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP()) AS last_updated_at
FROM silver.silver_orders
WHERE status = 'COMPLETED'
GROUP BY country;

-- Show output row count
SELECT COUNT(*) AS total_iceberg_records_after_aggregation FROM revenue_by_country_iceberg;
