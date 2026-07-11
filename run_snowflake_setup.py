import os, dotenv, snowflake.connector
dotenv.load_dotenv()
conn = snowflake.connector.connect(
    account=os.getenv('SNOWFLAKE_ACCOUNT'),
    user=os.getenv('SNOWFLAKE_USER'),
    password=os.getenv('SNOWFLAKE_PASSWORD'),
    role='ACCOUNTADMIN'
)
with open('infra/snowflake/02_grants.sql') as f:
    sql = f.read()
for var in ['SNOWFLAKE_DATABASE', 'SNOWFLAKE_WAREHOUSE', 'SNOWFLAKE_ROLE', 'SNOWFLAKE_STORAGE_INTEGRATION', 'SNOWFLAKE_EXTERNAL_VOLUME']:
    val = os.getenv(var)
    if val:
        sql = sql.replace('${' + var + '}', val)

for query in sql.split(';'):
    query = query.strip()
    if query:
        conn.cursor().execute(query)
print('Grants done.')

conn.cursor().execute('USE ROLE SYSADMIN')

files = [
    'snowflake/ddl/01_database_schema.sql',
    'snowflake/ddl/02_raw_tables.sql',
    'snowflake/ddl/03_silver_tables.sql',
    'snowflake/ddl/04_gold_iceberg_tables.sql',
    'snowflake/ddl/05_gold_delta_tables.sql',
    'snowflake/ddl/06_gold_plain_tables.sql',
    'snowflake/loads/stage_setup.sql'
]

for file_path in files:
    print(f'Running: {file_path}...')
    with open(file_path) as f:
        sql = f.read()
    for var in ['SNOWFLAKE_DATABASE', 'SNOWFLAKE_ROLE', 'SNOWFLAKE_EXTERNAL_VOLUME', 'ICEBERG_GOLD_BASE_LOCATION', 'AZURE_STORAGE_ACCOUNT', 'AZURE_STORAGE_CONTAINER', 'SNOWFLAKE_STORAGE_INTEGRATION', 'DELTA_GOLD_BASE_LOCATION']:
        val = os.getenv(var)
        if val is not None:
            sql = sql.replace('${' + var + '}', val)
    
    for query in sql.split(';'):
        query = query.strip()
        if query:
            conn.cursor().execute(query)
print('DDL and stage setup done.')
