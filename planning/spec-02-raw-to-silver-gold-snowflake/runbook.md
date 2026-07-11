# spec-02-raw-to-silver-gold-snowflake — Runbook

This runbook outlines the steps to upload the raw transaction data to Azure ADLS Gen2, set up the medallion layer schemas and tables (including a plain SQL Gold aggregate table), run the data load/transformations, and verify the record counts.

---

## Step 1: Upload Raw Data to Azure ADLS Gen2 (CLI)

Run the following Azure CLI commands to retrieve your storage key and upload the raw orders CSV file to your ADLS Gen2 container:

```bash
# Load env variables
export $(grep -v '^#' .env | xargs)

# Retrieve account key for direct query
ACCOUNT_KEY=$(az storage account keys list --resource-group "$AZURE_RESOURCE_GROUP" --account-name "$AZURE_STORAGE_ACCOUNT" --query "[0].value" -o tsv)

# Upload the CSV to the raw/ path in the container
az storage blob upload \
  --container-name "$AZURE_STORAGE_CONTAINER" \
  --account-name "$AZURE_STORAGE_ACCOUNT" \
  --account-key "$ACCOUNT_KEY" \
  --name "raw/sample_orders.csv" \
  --file "data/sample_orders.csv" \
  --overwrite
```

---

## Step 2: Provision Schemas and Tables (CLI)

Execute the logical schemas creation, the raw staging table DDL, the type-enforced silver table DDL, and the plain SQL gold aggregation table DDL:

```bash
./.venv/bin/python -c "
import os, dotenv, snowflake.connector
dotenv.load_dotenv()
conn = snowflake.connector.connect(
    account=os.getenv('SNOWFLAKE_ACCOUNT'),
    user=os.getenv('SNOWFLAKE_USER'),
    password=os.getenv('SNOWFLAKE_PASSWORD'),
    role=os.getenv('SNOWFLAKE_ROLE')
)

files = [
    'snowflake/ddl/01_database_schema.sql',
    'snowflake/ddl/02_raw_tables.sql',
    'snowflake/ddl/03_silver_tables.sql',
    'snowflake/ddl/06_gold_plain_tables.sql'
]

for file_path in files:
    print(f'Running: {file_path}...')
    with open(file_path) as f:
        sql = f.read()
    # Replace variables
    for var in ['SNOWFLAKE_DATABASE', 'SNOWFLAKE_ROLE']:
        sql = sql.replace('\${' + var + '}', os.getenv(var))
    
    # Run queries
    for query in sql.split(';'):
        query = query.strip()
        if query:
            conn.cursor().execute(query)
print('Schemas and tables created successfully.')
"
```

---

## Step 3: Configure External Stage and Ingest Data (CLI)

Define the CSV file format and external stage inside the `staging` schema (which separates stage metadata from data storage tables), then run the `COPY INTO` load command to ingest staged files into the raw table:

```bash
./.venv/bin/python -c "
import os, dotenv, snowflake.connector
dotenv.load_dotenv()
conn = snowflake.connector.connect(
    account=os.getenv('SNOWFLAKE_ACCOUNT'),
    user=os.getenv('SNOWFLAKE_USER'),
    password=os.getenv('SNOWFLAKE_PASSWORD'),
    role=os.getenv('SNOWFLAKE_ROLE')
)

files = [
    'snowflake/loads/stage_setup.sql',
    'snowflake/loads/load_raw_orders.sql'
]

for file_path in files:
    print(f'Running: {file_path}...')
    with open(file_path) as f:
        sql = f.read()
    # Replace variables
    for var in ['SNOWFLAKE_DATABASE', 'AZURE_STORAGE_ACCOUNT', 'AZURE_STORAGE_CONTAINER', 'SNOWFLAKE_STORAGE_INTEGRATION']:
        sql = sql.replace('\${' + var + '}', os.getenv(var))
    
    # Run queries
    for query in sql.split(';'):
        query = query.strip()
        if query:
            cursor = conn.cursor()
            cursor.execute(query)
            if 'total' in query.lower() or 'count' in query.lower():
                print(f'Result: {cursor.fetchone()}')
"
```

---

## Step 4: Run Raw-to-Silver Merge Transformation (CLI)

Execute the transformation logic to lowercase and trim emails, format types, filter corrupt rows, and merge raw data into the silver table:

```bash
./.venv/bin/python -c "
import os, dotenv, snowflake.connector
dotenv.load_dotenv()
conn = snowflake.connector.connect(
    account=os.getenv('SNOWFLAKE_ACCOUNT'),
    user=os.getenv('SNOWFLAKE_USER'),
    password=os.getenv('SNOWFLAKE_PASSWORD'),
    role=os.getenv('SNOWFLAKE_ROLE')
)

file_path = 'snowflake/transforms/raw_to_silver.sql'
print(f'Running: {file_path}...')
with open(file_path) as f:
    sql = f.read()
# Replace variables
for var in ['SNOWFLAKE_DATABASE', 'SNOWFLAKE_ROLE']:
    sql = sql.replace('\${' + var + '}', os.getenv(var))

# Run queries
for query in sql.split(';'):
    query = query.strip()
    if query:
        cursor = conn.cursor()
        cursor.execute(query)
        if 'total' in query.lower():
            print(f'Result: {cursor.fetchone()}')
"
```

---

## Step 5: Run Silver-to-Gold Plain SQL Aggregation (CLI)

Populate the plain Snowflake SQL gold aggregation table by running the sales metrics aggregation (grouped by country and calendar month):

```bash
./.venv/bin/python -c "
import os, dotenv, snowflake.connector
dotenv.load_dotenv()
conn = snowflake.connector.connect(
    account=os.getenv('SNOWFLAKE_ACCOUNT'),
    user=os.getenv('SNOWFLAKE_USER'),
    password=os.getenv('SNOWFLAKE_PASSWORD'),
    role=os.getenv('SNOWFLAKE_ROLE')
)

file_path = 'snowflake/transforms/silver_to_gold_plain.sql'
print(f'Running: {file_path}...')
with open(file_path) as f:
    sql = f.read()
# Replace variables
for var in ['SNOWFLAKE_DATABASE', 'SNOWFLAKE_ROLE']:
    sql = sql.replace('\${' + var + '}', os.getenv(var))

# Run queries
for query in sql.split(';'):
    query = query.strip()
    if query:
        cursor = conn.cursor()
        cursor.execute(query)
        if 'total' in query.lower():
            print(f'Result: {cursor.fetchone()}')
"
```

---

## Step 6: Verification (CLI)

Run a count validation script to confirm:
*   `raw_orders` has exactly **20** ingested records.
*   `silver_orders` has exactly **15** cleaned, deduplicated records.
*   `revenue_by_country_by_month` has been populated with consolidated business aggregations (grouped by country and month).

```bash
./.venv/bin/python -c "
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
cursor.execute('SELECT COUNT(*) FROM raw.raw_orders')
raw_cnt = cursor.fetchone()[0]
cursor.execute('SELECT COUNT(*) FROM silver.silver_orders')
sil_cnt = cursor.fetchone()[0]
cursor.execute('SELECT COUNT(*) FROM gold.revenue_by_country_by_month')
gold_cnt = cursor.fetchone()[0]

print('=== VERIFICATION RESULTS ===')
print(f'Raw Orders Count:    {raw_cnt} (Expected: 20)')
print(f'Silver Orders Count: {sil_cnt} (Expected: 15)')
print(f'Gold Orders Count:   {gold_cnt} (Expected: >0)')
if raw_cnt == 20 and sil_cnt == 15 and gold_cnt > 0:
    print('SUCCESS: Plain SQL medallion pipeline verified.')
else:
    print('FAILURE: Table row counts do not match expectations.')
print('=============================')
"
```
