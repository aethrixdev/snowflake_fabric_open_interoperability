import os
import dotenv
import snowflake.connector
import pandas as pd
from deltalake import write_deltalake

dotenv.load_dotenv()

print("==============================================")
print("Running Local Iceberg -> Delta Sync (Spark Bypass)")
print("==============================================\n")

print("1. Connecting to Snowflake...")
conn = snowflake.connector.connect(
    account=os.getenv("SNOWFLAKE_ACCOUNT"),
    user=os.getenv("SNOWFLAKE_USER"),
    password=os.getenv("SNOWFLAKE_PASSWORD"),
    role=os.getenv("SNOWFLAKE_ROLE"),
    database=os.getenv("SNOWFLAKE_DATABASE")
)

print("2. Downloading Iceberg data from Snowflake...")
query = "SELECT * FROM gold.revenue_by_country_iceberg"
# Fetch directly into a Pandas DataFrame
df = pd.read_sql(query, conn)
conn.close()

print(f"-> Successfully downloaded {len(df)} rows.")

print("3. Writing Delta table directly to Azure Data Lake Gen2...")

account_name = os.getenv("AZURE_STORAGE_ACCOUNT")
container_name = os.getenv("AZURE_STORAGE_CONTAINER")

# Configure Azure Service Principal Auth for DeltaLake
storage_options = {
    "azure_storage_account_name": account_name,
    "azure_storage_client_id": os.getenv("AZURE_SP_CLIENT_ID"),
    "azure_storage_client_secret": os.getenv("AZURE_SP_CLIENT_SECRET"),
    "azure_storage_tenant_id": os.getenv("AZURE_TENANT_ID"),
}

# The ABFS path to the delta folder
delta_path = f"abfs://{container_name}@{account_name}.dfs.core.windows.net/gold/revenue_by_country_delta"

# Write the Pandas DataFrame as a Delta Table, overwriting existing
write_deltalake(
    delta_path,
    df,
    mode="overwrite",
    storage_options=storage_options
)

print(f"\nSUCCESS! Delta table overwritten at {delta_path}.")
print("Your Power BI Semantic Model in Fabric will now instantly reflect the new data!")
