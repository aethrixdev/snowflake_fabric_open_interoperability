#!/usr/bin/env bash
# Create Azure AD service principal for Snowflake/Fabric storage access
set -euo pipefail

# Resolve paths relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../../.env"

if [ -f "$ENV_FILE" ]; then
  echo "Loading environment variables from ${ENV_FILE}..."
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "ERROR: .env file not found at ${ENV_FILE}"
  echo "Please copy .env.example to .env and fill in the values."
  exit 1
fi

# Validate required variables
REQUIRED_VARS=(AZURE_SUBSCRIPTION_ID AZURE_RESOURCE_GROUP AZURE_STORAGE_ACCOUNT AZURE_STORAGE_CONTAINER)
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "ERROR: Required environment variable $var is not set in .env"
    exit 1
  fi
done

SP_NAME="${AZURE_SP_NAME:-sp-snowflake-fabric-interop}"
SCOPE="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${AZURE_RESOURCE_GROUP}/providers/Microsoft.Storage/storageAccounts/${AZURE_STORAGE_ACCOUNT}/blobServices/default/containers/${AZURE_STORAGE_CONTAINER}"

echo "=== Azure Service Principal Setup ==="
echo "Service Principal Name: $SP_NAME"
echo "Scope:                  $SCOPE"
echo "Role:                   Storage Blob Data Contributor"
echo "======================================"

# Create the service principal and assign role in one step
echo "Creating Azure service principal and assigning role..."
SP_OUTPUT=$(az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role "Storage Blob Data Contributor" \
  --scopes "$SCOPE" \
  --output json)

# Extract credentials using Python to avoid external dependencies (like jq)
APP_ID=$(echo "$SP_OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin)['appId'])")
PASSWORD=$(echo "$SP_OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin)['password'])")
TENANT_ID=$(echo "$SP_OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin)['tenant'])")

echo "Service principal created successfully!"
echo "App/Client ID: $APP_ID"
echo "Tenant ID:     $TENANT_ID"

# Update the .env file with the newly created Service Principal credentials
if [ -f "$ENV_FILE" ]; then
  echo "Updating .env file with the new service principal credentials..."
  python3 -c "
import os
env_file = '$ENV_FILE'
app_id = '$APP_ID'
password = '$PASSWORD'
tenant_id = '$TENANT_ID'

with open(env_file, 'r') as f:
    content = f.read()

# Replace variables
new_content = []
for line in content.splitlines():
    if line.startswith('AZURE_SP_CLIENT_ID='):
        new_content.append(f'AZURE_SP_CLIENT_ID={app_id}')
    elif line.startswith('AZURE_SP_CLIENT_SECRET='):
        new_content.append(f'AZURE_SP_CLIENT_SECRET={password}')
    elif line.startswith('AZURE_TENANT_ID=') and '00000000' in line:
        new_content.append(f'AZURE_TENANT_ID={tenant_id}')
    else:
        new_content.append(line)

with open(env_file, 'w') as f:
    f.write('\n'.join(new_content) + '\n')
"
  echo ".env file updated successfully."
  chmod 600 "$ENV_FILE"
  echo "Permissions for .env locked down (chmod 600)."
else
  echo "WARNING: .env file not found at $ENV_FILE. Could not auto-update."
fi

echo "=================================================================="
echo "IMPORTANT: Please verify that .env now contains the updated values"
echo "for AZURE_SP_CLIENT_ID and AZURE_SP_CLIENT_SECRET."
echo "=================================================================="
