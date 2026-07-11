import os, dotenv, snowflake.connector
dotenv.load_dotenv()

# We need SNOWFLAKE_WAREHOUSE as well
warehouse = os.getenv('SNOWFLAKE_WAREHOUSE', 'COMPUTE_WH')

conn = snowflake.connector.connect(
    account=os.getenv('SNOWFLAKE_ACCOUNT'),
    user=os.getenv('SNOWFLAKE_USER'),
    password=os.getenv('SNOWFLAKE_PASSWORD'),
    role='ACCOUNTADMIN'
)
db = os.getenv('SNOWFLAKE_DATABASE')
user = os.getenv('SNOWFLAKE_USER')

queries = [
    "USE ROLE ACCOUNTADMIN",
    "CREATE ROLE IF NOT EXISTS analyst_role",
    f"GRANT USAGE ON DATABASE {db} TO ROLE analyst_role",
    f"GRANT USAGE ON SCHEMA {db}.silver TO ROLE analyst_role",
    f"GRANT SELECT ON VIEW {db}.silver.secure_orders TO ROLE analyst_role",
    f"GRANT USAGE ON WAREHOUSE {warehouse} TO ROLE analyst_role",
    f"GRANT ROLE analyst_role TO USER {user}",
    "USE ROLE analyst_role",
    f"USE WAREHOUSE {warehouse}",
    f"SELECT email FROM {db}.silver.secure_orders LIMIT 5"
]

cursor = conn.cursor()
for q in queries:
    print(f"Running: {q}")
    cursor.execute(q)
    if q.upper().startswith("SELECT"):
        for row in cursor.fetchall():
            print(f"  {row}")

# Clean up
cursor.execute("USE ROLE ACCOUNTADMIN")
cursor.execute("DROP ROLE IF EXISTS analyst_role")
print("Cleaned up.")
