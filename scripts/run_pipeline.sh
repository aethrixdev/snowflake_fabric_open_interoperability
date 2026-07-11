#!/usr/bin/env bash
# Run the Snowflake Ingestion and Aggregation Pipeline
set -euo pipefail

# Resolve paths relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
ENV_FILE="${ROOT_DIR}/.env"

if [ -f "$ENV_FILE" ]; then
  echo "Loading environment variables..."
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "ERROR: .env file not found at ${ENV_FILE}"
  exit 1
fi

echo "======================================================"
echo "Starting Snowflake Pipeline Execution"
echo "======================================================"

# 1. Generate live row updates
echo "Step 1: Generating live update CSV file..."
python3 "${ROOT_DIR}/data/generate_live_update.py"

# 2. Upload the live update file to ADLS Gen2 raw/
echo "Step 2: Uploading live update to ADLS Gen2..."
az storage blob upload \
  --container-name "$AZURE_STORAGE_CONTAINER" \
  --account-name "$AZURE_STORAGE_ACCOUNT" \
  --name "raw/live_orders_update.csv" \
  --file "${ROOT_DIR}/data/live_orders_update.csv" \
  --auth-mode login \
  --overwrite

# 3. Trigger Snowflake Ingestion, Cleaning and Aggregation
echo "Step 3: Triggering Snowflake ingestion & transformations..."
python3 -c "
import os, dotenv, snowflake.connector
dotenv.load_dotenv()
conn = snowflake.connector.connect(
    account=os.getenv('SNOWFLAKE_ACCOUNT'),
    user=os.getenv('SNOWFLAKE_USER'),
    password=os.getenv('SNOWFLAKE_PASSWORD'),
    role=os.getenv('SNOWFLAKE_ROLE')
)

files = [
    'snowflake/loads/load_raw_orders.sql',
    'snowflake/transforms/raw_to_silver.sql',
    'snowflake/transforms/silver_to_gold_iceberg.sql'
]

for file_path in files:
    print(f'  Executing SQL: {file_path}...')
    with open(file_path) as f:
        sql = f.read()
    
    # Replace parameters
    for var in ['SNOWFLAKE_DATABASE', 'SNOWFLAKE_ROLE', 'SNOWFLAKE_EXTERNAL_VOLUME', 'ICEBERG_GOLD_BASE_LOCATION']:
        sql = sql.replace('\${' + var + '}', os.getenv(var) or '')

    # Run queries
    for query in sql.split(';'):
        query = query.strip()
        if query:
            cursor = conn.cursor()
            cursor.execute(query)
            if 'total' in query.lower():
                print(f'    Result: {cursor.fetchone()}')
"

echo "======================================================"
echo "Snowflake Pipeline completed successfully!"
echo "Next Steps: Run the Fabric Sync notebook to generate Delta files,"
echo "then execute scripts/validate_interop.py to confirm consistency."
echo "======================================================"
