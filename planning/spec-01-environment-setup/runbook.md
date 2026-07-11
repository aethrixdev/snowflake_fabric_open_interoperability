# spec-01-environment-setup — Runbook

This runbook outlines the exact, reproducible steps required to provision the Azure resources, configure Snowflake storage integrations and external volumes, grant required consents, and verify end-to-end connectivity.

---

## Step 1: Preparation (Manual Setup)

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```
2. Open `.env` in a text editor and fill in your actual credentials.
   > [!IMPORTANT]
   > Do NOT commit `.env` to source control. It is already included in `.gitignore`.
   > Ensure you have the following values ready:
   > - `AZURE_SUBSCRIPTION_ID`, `AZURE_RESOURCE_GROUP`, `AZURE_LOCATION`
   > - `AZURE_STORAGE_ACCOUNT` (must be unique globally), `AZURE_STORAGE_CONTAINER`
   > - `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`

---

## Step 2: Azure CLI Provisioning (CLI)

1. Log in to your Azure CLI (if not already authenticated):
   ```bash
   az login
   ```
2. Set your active subscription:
   ```bash
   az account set --subscription "<your-subscription-id>"
   ```
3. Run the storage provisioning script:
   ```bash
   chmod +x infra/azure/create_storage_account.sh
   ./infra/azure/create_storage_account.sh
   ```
4. Run the service principal provisioning script:
   ```bash
   chmod +x infra/azure/create_service_principal.sh
   ./infra/azure/create_service_principal.sh
   ```
   *Note: This script will automatically create the Service Principal, assign it Storage Blob Data Contributor access to your container, and update your `.env` file with the Client ID and Secret.*

---

## Step 3: Create Snowflake Integrations (CLI)

To execute the DDL queries in Snowflake while pulling dynamic variables from your `.env` file, run the following Python-based CLI wrapper.

1. Ensure Python dependencies are installed:
   ```bash
   pip install -r requirements.txt
   ```
2. Execute the storage integration and external volume setup:
   ```bash
   python3 -c "
   import os, dotenv, snowflake.connector, json
   dotenv.load_dotenv()
   conn = snowflake.connector.connect(
       account=os.getenv('SNOWFLAKE_ACCOUNT'),
       user=os.getenv('SNOWFLAKE_USER'),
       password=os.getenv('SNOWFLAKE_PASSWORD'),
       role='ACCOUNTADMIN'
   )
   with open('infra/snowflake/01_storage_integration.sql') as f:
       sql = f.read()
   for var in ['AZURE_TENANT_ID', 'AZURE_STORAGE_ACCOUNT', 'AZURE_STORAGE_CONTAINER', 'SNOWFLAKE_STORAGE_INTEGRATION', 'SNOWFLAKE_EXTERNAL_VOLUME']:
       sql = sql.replace('\${' + var + '}', os.getenv(var))
   
   for query in sql.split(';'):
       query = query.strip()
       if not query:
           continue
       # Strip comments to inspect query command type
       clean_lines = []
       for line in query.splitlines():
           line_clean = line.strip()
           if line_clean and not line_clean.startswith('--') and not line_clean.startswith('//'):
               clean_lines.append(line_clean)
       clean_query = ' '.join(clean_lines).strip()
       if not clean_query:
           continue
           
       print(f'Executing DDL: {clean_query[:80]}...')
       cursor = conn.cursor()
       cursor.execute(clean_query)
       
       # Print details of describe commands
       if clean_query.upper().startswith('DESCRIBE') or clean_query.upper().startswith('DESC '):
           results = cursor.fetchall()
           for row in results:
               # Storage Integration: 4 columns, AZURE_CONSENT_URL is row[0], value is row[2]
               if len(row) >= 4 and row[0] in ['AZURE_CONSENT_URL', 'AZURE_MULTI_TENANT_APP_NAME']:
                   print(f'  [STORAGE INTEGRATION] {row[0]}: {row[2]}')
               # External Volume: 5 columns, STORAGE_LOCATION_1 is row[1], JSON value is row[3]
               elif len(row) >= 5 and row[1].startswith('STORAGE_LOCATION_'):
                   prop_name = row[1]
                   prop_val = row[3]
                   try:
                       loc_data = json.loads(prop_val)
                       app_name = loc_data.get('AZURE_MULTI_TENANT_APP_NAME')
                       consent_url = loc_data.get('AZURE_CONSENT_URL')
                       if app_name or consent_url:
                           print(f'  [EXTERNAL VOLUME] {prop_name}:')
                           print(f'    AZURE_MULTI_TENANT_APP_NAME: {app_name}')
                           print(f'    AZURE_CONSENT_URL: {consent_url}')
                   except Exception as e:
                       print(f'    Failed to parse JSON for {prop_name}: {e}')
   "
   ```
   **Capture Output**: Save the `AZURE_CONSENT_URL` and `AZURE_MULTI_TENANT_APP_NAME` values printed for both the Storage Integration and External Volume.

---

## Step 4: Snowflake Azure Consent & Role Assignment (Manual Browser Steps)

> [!IMPORTANT]
> You must complete these steps in a web browser before Snowflake can access your Azure storage account.

1. **Grant Admin Consent**:
   - Copy the `AZURE_CONSENT_URL` returned by the script for the Storage Integration.
   - Paste it into your browser, log in as an **Azure Tenant Administrator**, and click **Accept**.
   - Repeat the process for the External Volume's `AZURE_CONSENT_URL` (if it differs from the integration consent URL).

2. **Assign Azure IAM Role to Snowflake**:
   - Log in to the [Azure Portal](https://portal.azure.com).
   - Navigate to your **Storage Account** (`AZURE_STORAGE_ACCOUNT`).
   - Click **Access Control (IAM)** -> **Add** -> **Add role assignment**.
   - Select the role: **Storage Blob Data Contributor**.
   - Under "Assign access to", choose **User, group, or service principal**.
   - Search for the **Snowflake Application Name** (use the `AZURE_MULTI_TENANT_APP_NAME` from Step 3, which typically looks like `Snowflake PacBld - Prod` or contains a unique identifier).
   - Click **Review + assign**.
   - *Note*: Ensure this is assigned at the Storage Account level.

---

## Step 5: Configure Snowflake Role/Grants (CLI)

Run the role and warehouse setup to delegate usage rights to your target developer role:
```bash
python3 -c "
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
    sql = sql.replace('\${' + var + '}', os.getenv(var))

for query in sql.split(';'):
    query = query.strip()
    if query:
        print(f'Executing Grant: {query[:80]}...')
        conn.cursor().execute(query)
"
```

---

## Step 6: Verify Bidirectional Connectivity (CLI)

1. Execute the verification script to write a test stage file and create a test Iceberg table:
   ```bash
   python3 -c "
   import os, dotenv, snowflake.connector
   dotenv.load_dotenv()
   conn = snowflake.connector.connect(
       account=os.getenv('SNOWFLAKE_ACCOUNT'),
       user=os.getenv('SNOWFLAKE_USER'),
       password=os.getenv('SNOWFLAKE_PASSWORD'),
       role=os.getenv('SNOWFLAKE_ROLE'),
       warehouse=os.getenv('SNOWFLAKE_WAREHOUSE')
   )
   with open('infra/snowflake/03_verify_integration.sql') as f:
       sql = f.read()
   for var in ['SNOWFLAKE_ROLE', 'SNOWFLAKE_WAREHOUSE', 'SNOWFLAKE_DATABASE', 'AZURE_STORAGE_ACCOUNT', 'AZURE_STORAGE_CONTAINER', 'SNOWFLAKE_STORAGE_INTEGRATION', 'SNOWFLAKE_EXTERNAL_VOLUME']:
       sql = sql.replace('\${' + var + '}', os.getenv(var))

   # Run only the first 2 sections (skip cleanup section for now)
   queries = [q.strip() for q in sql.split(';') if q.strip()]
   verification_queries = [q for q in queries if 'DROP' not in q.upper()]
   
   for query in verification_queries:
       print(f'Executing Verification: {query[:80]}...')
       cursor = conn.cursor()
       cursor.execute(query)
       if query.upper().startswith('LIST') or query.upper().startswith('SELECT'):
           print('Query Result:')
           for row in cursor.fetchall():
               print(f'  {row}')
   "
   ```

2. **Verify Storage Blobs via Azure CLI**:
   Run the following commands to check that the CSV file and Iceberg table folders were written to your storage container:
   ```bash
   # Load env variables for local shell run
   export $(grep -v '^#' .env | xargs)
   
   echo "Checking verify_stage (Storage Integration write)..."
   az storage blob list \
     --container-name "$AZURE_STORAGE_CONTAINER" \
     --account-name "$AZURE_STORAGE_ACCOUNT" \
     --prefix "verify_stage/" \
     --auth-mode login \
     --query "[].name" \
     -o table
   
   echo "Checking verify_iceberg (External Volume Iceberg write)..."
   az storage blob list \
     --container-name "$AZURE_STORAGE_CONTAINER" \
     --account-name "$AZURE_STORAGE_ACCOUNT" \
     --prefix "verify_iceberg/" \
     --auth-mode login \
     --query "[].name" \
     -o table
   ```
   **Verification Criteria**:
   - `verify_stage/test_connection_write.csv` must be listed.
   - Files matching `verify_iceberg/data/...` and `verify_iceberg/metadata/...` must be listed.

---

## Step 7: Clean Up (CLI)

Run the cleanup script block to delete the throwaway verification tables and stages:
```bash
python3 -c "
import os, dotenv, snowflake.connector
dotenv.load_dotenv()
conn = snowflake.connector.connect(
    account=os.getenv('SNOWFLAKE_ACCOUNT'),
    user=os.getenv('SNOWFLAKE_USER'),
    password=os.getenv('SNOWFLAKE_PASSWORD'),
    role=os.getenv('SNOWFLAKE_ROLE'),
    warehouse=os.getenv('SNOWFLAKE_WAREHOUSE'),
    database=os.getenv('SNOWFLAKE_DATABASE'),
    schema='PUBLIC'
)
print('Cleaning up verification stages and tables...')
conn.cursor().execute('DROP TABLE IF EXISTS _verify_iceberg_ext_vol')
conn.cursor().execute('DROP STAGE IF EXISTS verify_azure_stage')
print('Cleanup completed.')
"
```
