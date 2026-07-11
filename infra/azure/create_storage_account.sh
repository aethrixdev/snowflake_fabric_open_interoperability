#!/usr/bin/env bash
# Create ADLS Gen2 storage account + container
set -euo pipefail

# Resolve paths relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../../.env"

if [ -f "$ENV_FILE" ]; then
  echo "Loading environment variables from ${ENV_FILE}..."
  # Source the env file, ignoring comments and empty lines
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "ERROR: .env file not found at ${ENV_FILE}"
  echo "Please copy .env.example to .env and fill in the values."
  exit 1
fi

# Validate required variables
REQUIRED_VARS=(AZURE_RESOURCE_GROUP AZURE_LOCATION AZURE_STORAGE_ACCOUNT AZURE_STORAGE_CONTAINER)
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "ERROR: Required environment variable $var is not set in .env"
    exit 1
  fi
done

echo "=== Azure Infrastructure Setup ==="
echo "Resource Group:    $AZURE_RESOURCE_GROUP"
echo "Location:          $AZURE_LOCATION"
echo "Storage Account:   $AZURE_STORAGE_ACCOUNT"
echo "Storage Container: $AZURE_STORAGE_CONTAINER"
echo "=================================="

# 1. Create Resource Group if it doesn't exist
echo "Checking resource group '$AZURE_RESOURCE_GROUP'..."
if ! az group show --name "$AZURE_RESOURCE_GROUP" &>/dev/null; then
  echo "Creating resource group '$AZURE_RESOURCE_GROUP' in '$AZURE_LOCATION'..."
  az group create --name "$AZURE_RESOURCE_GROUP" --location "$AZURE_LOCATION"
else
  echo "Resource group '$AZURE_RESOURCE_GROUP' already exists."
fi

# 2. Create ADLS Gen2 Storage Account if it doesn't exist
echo "Checking storage account '$AZURE_STORAGE_ACCOUNT'..."
if ! az storage account show --name "$AZURE_STORAGE_ACCOUNT" --resource-group "$AZURE_RESOURCE_GROUP" &>/dev/null; then
  echo "Creating ADLS Gen2 Storage Account '$AZURE_STORAGE_ACCOUNT'..."
  az storage account create \
    --name "$AZURE_STORAGE_ACCOUNT" \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --location "$AZURE_LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --enable-hierarchical-namespace true
else
  echo "Storage account '$AZURE_STORAGE_ACCOUNT' already exists."
fi

# 3. Create Storage Container if it doesn't exist
echo "Checking container '$AZURE_STORAGE_CONTAINER'..."
# Check if container exists by listing containers and checking if our container name is present
CONTAINER_EXISTS=$(az storage container exists \
  --name "$AZURE_STORAGE_CONTAINER" \
  --account-name "$AZURE_STORAGE_ACCOUNT" \
  --auth-mode login \
  --query "exists" \
  -o tsv 2>/dev/null || echo "false")

if [ "$CONTAINER_EXISTS" != "true" ]; then
  echo "Creating storage container '$AZURE_STORAGE_CONTAINER'..."
  az storage container create \
    --name "$AZURE_STORAGE_CONTAINER" \
    --account-name "$AZURE_STORAGE_ACCOUNT" \
    --auth-mode login
else
  echo "Container '$AZURE_STORAGE_CONTAINER' already exists."
fi

echo "Azure storage infrastructure verified successfully."
