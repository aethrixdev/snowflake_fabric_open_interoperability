#!/usr/bin/env bash
# Teardown Snowflake objects + Azure resource group
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
echo "WARNING: Starting Full Cloud Infrastructure Teardown"
echo "======================================================"

# 1. Teardown Snowflake Resources
echo "Step 1: Deleting Snowflake objects..."
python3 -c "
import os, dotenv, snowflake.connector
dotenv.load_dotenv()

# We need to run this as ACCOUNTADMIN or a role with appropriate drop privileges
try:
    conn = snowflake.connector.connect(
        account=os.getenv('SNOWFLAKE_ACCOUNT'),
        user=os.getenv('SNOWFLAKE_USER'),
        password=os.getenv('SNOWFLAKE_PASSWORD'),
        role='ACCOUNTADMIN'
    )
    cursor = conn.cursor()
    
    db = os.getenv('SNOWFLAKE_DATABASE')
    wh = os.getenv('SNOWFLAKE_WAREHOUSE')
    si = os.getenv('SNOWFLAKE_STORAGE_INTEGRATION')
    ev = os.getenv('SNOWFLAKE_EXTERNAL_VOLUME')
    
    print(f'  Dropping Database {db}...')
    cursor.execute(f'DROP DATABASE IF EXISTS {db}')
    
    print(f'  Dropping Warehouse {wh}...')
    cursor.execute(f'DROP WAREHOUSE IF EXISTS {wh}')
    
    print(f'  Dropping Storage Integration {si}...')
    cursor.execute(f'DROP STORAGE INTEGRATION IF EXISTS {si}')
    
    print(f'  Dropping External Volume {ev}...')
    cursor.execute(f'DROP EXTERNAL VOLUME IF EXISTS {ev}')
    
    print('Snowflake objects dropped successfully.')
except Exception as e:
    print(f'ERROR dropping Snowflake objects: {str(e)}')
"

# 2. Deleting Azure Service Principal
if [ -n "${AZURE_SP_CLIENT_ID:-}" ] && [ "$AZURE_SP_CLIENT_ID" != "00000000-0000-0000-0000-000000000000" ]; then
  echo "Step 2: Deleting Azure service principal..."
  if az ad sp show --id "$AZURE_SP_CLIENT_ID" &>/dev/null; then
    az ad sp delete --id "$AZURE_SP_CLIENT_ID"
    echo "Azure service principal deleted successfully."
  else
    echo "Azure service principal does not exist."
  fi
else
  echo "Step 2: Skipping Service Principal deletion (default/empty ID)."
fi

# 3. Deleting Azure Resource Group
if [ -n "${AZURE_RESOURCE_GROUP:-}" ] && [ "$AZURE_RESOURCE_GROUP" != "rg-lakehouse-demo" ]; then
  echo "Step 3: Deleting Azure resource group '$AZURE_RESOURCE_GROUP'..."
  if az group show --name "$AZURE_RESOURCE_GROUP" &>/dev/null; then
    az group delete --name "$AZURE_RESOURCE_GROUP" --yes --no-wait
    echo "Resource group deletion triggered (non-blocking)."
  else
    echo "Resource group '$AZURE_RESOURCE_GROUP' does not exist."
  fi
else
  echo "Step 3: Skipping Resource Group deletion (using default name)."
fi

echo "======================================================"
echo "Teardown script completed!"
echo "Microsoft Fabric Workspace objects (Lakehouse, Notebooks, Power BI)"
echo "must be deleted manually in the browser."
echo "======================================================"
