-- Data Governance: Dynamic Masking Policy for Email Addresses
-- Run this using the role specified in SNOWFLAKE_ROLE (typically SYSADMIN or SECURITYADMIN)

USE DATABASE ${SNOWFLAKE_DATABASE};
USE SCHEMA silver;



-- ====================================================================
-- OPTION B: STANDARD EDITION WORKAROUND (SECURE VIEW)
-- ====================================================================
-- This is supported on ALL Snowflake editions, including Standard. It uses
-- a SECURE VIEW to mask the email column dynamically depending on the active role.

-- 1. Create the secure view
CREATE OR REPLACE SECURE VIEW secure_orders AS
SELECT 
  order_id,
  customer_id,
  order_date,
  country,
  amount,
  status,
  CASE 
    WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN') THEN email
    ELSE '*********@' || SPLIT_PART(email, '@', 2)
  END AS email
FROM silver_orders;

-- 2. Query as privileged role (SYSADMIN) to verify raw read
USE ROLE SYSADMIN;
SELECT 'SYSADMIN' AS query_role, email FROM secure_orders LIMIT 3;
