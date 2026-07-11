import os, dotenv, snowflake.connector
dotenv.load_dotenv()

conn = snowflake.connector.connect(
    account=os.getenv('SNOWFLAKE_ACCOUNT'),
    user=os.getenv('SNOWFLAKE_USER'),
    password=os.getenv('SNOWFLAKE_PASSWORD'),
    role=os.getenv('SNOWFLAKE_ROLE'),
    database=os.getenv('SNOWFLAKE_DATABASE')
)

def run_sql_file(file_path):
    print(f"\n======================================")
    print(f"Running SQL File: {file_path}")
    print(f"======================================")
    with open(file_path) as f:
        sql = f.read()
    
    # Replace parameters
    for var in ['SNOWFLAKE_DATABASE', 'SNOWFLAKE_ROLE']:
        sql = sql.replace('${' + var + '}', os.getenv(var) or '')
        
    for query in sql.split(';'):
        query = query.strip()
        if not query:
            continue
        print(f"Executing: {query[:80].strip()}...")
        cursor = conn.cursor()
        try:
            cursor.execute(query)
            if query.upper().startswith('SELECT') or query.upper().startswith('SHOW'):
                results = cursor.fetchall()
                print("Results:")
                for row in results:
                    print(f"  {row}")
        except Exception as e:
            if "Unsupported feature 'MASKING POLICY'" in str(e):
                print(f"  [EXPECTED WARNING] Dynamic Data Masking is not supported on this Snowflake Edition (Standard Edition). Skipping.")
            else:
                print(f"Error executing query: {e}")

# Run Schema Evolution SQL
run_sql_file('snowflake/transforms/schema_evolution_demo.sql')

# Run Masking Policy SQL
run_sql_file('snowflake/governance/masking_policy_email.sql')
