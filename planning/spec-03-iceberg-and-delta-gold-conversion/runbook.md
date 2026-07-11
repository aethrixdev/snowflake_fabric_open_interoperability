# spec-03-iceberg-and-delta-gold-conversion — Runbook

This runbook outlines the steps to create the Gold Iceberg and Delta external tables in Snowflake, run the business aggregation, and verify files appear in the ADLS Gen2 container.

---

## Step 1: Provision Gold Tables (CLI)

Execute DDL to define the Iceberg and Delta External tables:
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
    'snowflake/ddl/04_gold_iceberg_tables.sql',
    'snowflake/ddl/05_gold_delta_tables.sql'
]

for file_path in files:
    print(f'Running: {file_path}...')
    with open(file_path) as f:
        sql = f.read()
    # Replace variables
    for var in ['SNOWFLAKE_DATABASE', 'SNOWFLAKE_ROLE', 'SNOWFLAKE_EXTERNAL_VOLUME', 'ICEBERG_GOLD_BASE_LOCATION', 'AZURE_STORAGE_ACCOUNT', 'AZURE_STORAGE_CONTAINER', 'SNOWFLAKE_STORAGE_INTEGRATION', 'DELTA_GOLD_BASE_LOCATION']:
        sql = sql.replace('\${' + var + '}', os.getenv(var))
    
    # Run queries
    for query in sql.split(';'):
        query = query.strip()
        if query:
            conn.cursor().execute(query)
print('Gold tables created successfully.')
"
```

---

## Step 2: Run Silver-to-Gold Iceberg Aggregation (CLI)

Populate the Iceberg table by running the aggregation transform:
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

file_path = 'snowflake/transforms/silver_to_gold_iceberg.sql'
print(f'Running: {file_path}...')
with open(file_path) as f:
    sql = f.read()
# Replace variables
for var in ['SNOWFLAKE_DATABASE', 'SNOWFLAKE_ROLE', 'SNOWFLAKE_EXTERNAL_VOLUME', 'ICEBERG_GOLD_BASE_LOCATION']:
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

## Step 3: Run Delta Refresh (CLI)

Perform a metadata cache refresh (which will succeed but return 0 records initially, since Microsoft Fabric has not written to `gold/revenue_by_country_delta/` yet):
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

file_path = 'snowflake/transforms/silver_to_gold_delta.sql'
print(f'Running: {file_path}...')
with open(file_path) as f:
    sql = f.read()
# Replace variables
for var in ['SNOWFLAKE_DATABASE', 'SNOWFLAKE_ROLE', 'DELTA_GOLD_BASE_LOCATION']:
    sql = sql.replace('\${' + var + '}', os.getenv(var))

# Run queries
for query in sql.split(';'):
    query = query.strip()
    if query:
        cursor = conn.cursor()
        try:
            cursor.execute(query)
        except Exception as e:
            if 'Failed to find the metadata of Delta table' in str(e):
                print(f'Expected Warning (Table is currently empty): {e}')
            else:
                raise e
"
```

---

## Step 4: Verification (CLI)

Verify that the Gold Iceberg data and metadata files appear in ADLS Gen2 under their actual physical path (which includes Snowflake's random suffix):

```bash
# Load env variables
export $(grep -v '^#' .env | xargs)

# Retrieve account key for direct query
ACCOUNT_KEY=$(az storage account keys list --resource-group "$AZURE_RESOURCE_GROUP" --account-name "$AZURE_STORAGE_ACCOUNT" --query "[0].value" -o tsv)

echo "Listing Gold files under 'gold/' prefix..."
az storage blob list \
  --container-name "$AZURE_STORAGE_CONTAINER" \
  --account-name "$AZURE_STORAGE_ACCOUNT" \
  --account-key "$ACCOUNT_KEY" \
  --prefix "gold/" \
  --query "[].name" \
  -o table
```

> [!IMPORTANT]
> Because Snowflake appends a random 8-character alphanumeric suffix to the specified base location (e.g., `gold/revenue_by_country_iceberg.HgOpISFG/`), the literal prefix `gold/revenue_by_country_iceberg/` will not list any files. 
> 
> **You must identify the exact folder name containing the suffix from this listing (e.g., `gold/revenue_by_country_iceberg.<random>/`) and copy it. This actual physical path must be used as the target location when creating the Microsoft Fabric OneLake shortcut in spec-04.**

**Verification Criteria**:
- Multiple `.parquet` files and metadata folders (`metadata/*.metadata.json`, `metadata/*-m0.avro`) must be present under the custom `gold/revenue_by_country_iceberg.<suffix>/` directory.
