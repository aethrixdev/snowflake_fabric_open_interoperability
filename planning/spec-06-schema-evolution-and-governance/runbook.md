# spec-06-schema-evolution-and-governance — Runbook

This runbook outlines the steps to verify Iceberg schema evolution and Snowflake's dynamic data masking.

---

## Step 1: Execute Iceberg Schema Evolution (CLI)

Run the schema evolution script inside Snowflake:
```bash
python3 -c "
import os, dotenv, snowflake.connector
dotenv.load_dotenv()
conn = snowflake.connector.connect(
    account=os.getenv('SNOWFLAKE_ACCOUNT'),
    user=os.getenv('SNOWFLAKE_USER'),
    password=os.getenv('SNOWFLAKE_PASSWORD'),
    role=os.getenv('SNOWFLAKE_ROLE')
)
with open('snowflake/transforms/schema_evolution_demo.sql') as f:
    sql = f.read()
for var in ['SNOWFLAKE_DATABASE', 'SNOWFLAKE_ROLE']:
    sql = sql.replace('\${' + var + '}', os.getenv(var))

for query in sql.split(';'):
    query = query.strip()
    if query:
        print(f'Running: {query[:80]}...')
        cursor = conn.cursor()
        cursor.execute(query)
        if query.upper().startswith('SELECT'):
            print('Schema Evolution Output:')
            for row in cursor.fetchall():
                print(f'  {row}')
"
```

---

## Step 2: Configure & Verify Data Masking (CLI)

1. Create and apply the email masking policy:
   ```bash
   python3 -c "
   import os, dotenv, snowflake.connector
   dotenv.load_dotenv()
   conn = snowflake.connector.connect(
       account=os.getenv('SNOWFLAKE_ACCOUNT'),
       user=os.getenv('SNOWFLAKE_USER'),
       password=os.getenv('SNOWFLAKE_PASSWORD'),
       role=os.getenv('SNOWFLAKE_ROLE')
   )
   with open('snowflake/governance/masking_policy_email.sql') as f:
       sql = f.read()
   for var in ['SNOWFLAKE_DATABASE', 'SNOWFLAKE_ROLE']:
       sql = sql.replace('\${' + var + '}', os.getenv(var))
   
   for query in sql.split(';'):
       query = query.strip()
       if query:
           print(f'Running: {query[:80]}...')
           cursor = conn.cursor()
           cursor.execute(query)
           if query.upper().startswith('SELECT'):
               print('Masking Verification (Privileged Role):')
               for row in cursor.fetchall():
                   print(f'  {row}')
   "
   ```

2. Create a restricted test role and verify masking (Manual SQL / Python):
   Execute the following SQL block as `ACCOUNTADMIN` in your Snowflake console (or python wrapper) to test restricted access:
   ```sql
   -- Use ACCOUNTADMIN to set up test privileges
   USE ROLE ACCOUNTADMIN;
   CREATE ROLE IF NOT EXISTS analyst_role;
   
   -- Grant usage to the analyst role
   GRANT USAGE ON DATABASE ${SNOWFLAKE_DATABASE} TO ROLE analyst_role;
   GRANT USAGE ON SCHEMA ${SNOWFLAKE_DATABASE}.silver TO ROLE analyst_role;
   GRANT SELECT ON TABLE ${SNOWFLAKE_DATABASE}.silver.silver_orders TO ROLE analyst_role;
   GRANT USAGE ON WAREHOUSE ${SNOWFLAKE_WAREHOUSE} TO ROLE analyst_role;
   
   -- Grant the role to your login user (Replace <USER> with your SNOWFLAKE_USER)
   GRANT ROLE analyst_role TO USER ${SNOWFLAKE_USER};
   
   -- Test Query as analyst_role
   USE ROLE analyst_role;
   USE WAREHOUSE ${SNOWFLAKE_WAREHOUSE};
   SELECT email FROM ${SNOWFLAKE_DATABASE}.silver.silver_orders LIMIT 5;
   ```
   **Expected Verification Output**:
   Emails returned must be masked like `*********@example.com`, proving column-level governance is working!

3. Clean up the test role:
   ```sql
   USE ROLE ACCOUNTADMIN;
   DROP ROLE IF EXISTS analyst_role;
   ```
