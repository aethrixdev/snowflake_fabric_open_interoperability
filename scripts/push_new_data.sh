#!/usr/bin/env bash
set -euo pipefail
source .env

echo "2. Executing Snowflake truncate and reload..."
.venv/bin/python3 -c "
import os, dotenv, snowflake.connector
dotenv.load_dotenv()
conn = snowflake.connector.connect(
    account=os.getenv('SNOWFLAKE_ACCOUNT'),
    user=os.getenv('SNOWFLAKE_USER'),
    password=os.getenv('SNOWFLAKE_PASSWORD'),
    role=os.getenv('SNOWFLAKE_ROLE'),
    database=os.getenv('SNOWFLAKE_DATABASE')
)

cursor = conn.cursor()
print('Truncating tables...')
cursor.execute('TRUNCATE TABLE raw.raw_orders')
cursor.execute('TRUNCATE TABLE silver.silver_orders')
# Iceberg table is insert overwrite, no need to truncate

print('Running COPY INTO with FORCE = TRUE...')
cursor.execute(r'''
COPY INTO raw.raw_orders(order_id, customer_id, order_date, country, amount, status, email)
FROM (
  SELECT t.\$1, t.\$2, t.\$3, t.\$4, t.\$5, t.\$6, t.\$7
  FROM @staging.raw_orders_stage t
)
FILE_FORMAT = (FORMAT_NAME = 'staging.raw_csv_format')
PATTERN = '.*sample_orders.*\.csv'
FORCE = TRUE
ON_ERROR = 'CONTINUE'
''')
print('Data loaded into RAW.')

files = [
    'snowflake/transforms/raw_to_silver.sql',
    'snowflake/transforms/silver_to_gold_iceberg.sql'
]

for file_path in files:
    print(f'Executing {file_path}...')
    with open(file_path) as f:
        sql = f.read()
    for var in ['SNOWFLAKE_DATABASE', 'SNOWFLAKE_ROLE', 'SNOWFLAKE_EXTERNAL_VOLUME', 'ICEBERG_GOLD_BASE_LOCATION']:
        sql = sql.replace('\${' + var + '}', os.getenv(var) or '')
    for query in sql.split(';'):
        query = query.strip()
        if query:
            cursor.execute(query)

print('Snowflake push complete!')
"
