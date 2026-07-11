# Read Iceberg shortcut and Write Delta to ADLS Gen2
# This script is run inside a Fabric Notebook. It acts as the Sync Agent:
# It reads Snowflake's Iceberg data via OneLake, and writes it in Delta format directly to ADLS Gen2.

from pyspark.sql import SparkSession

# 1. CONFIGURE ADLS ACCESS (REPLACE THESE PLACEHOLDERS WITH VALUES FROM YOUR .ENV FILE)
AZURE_STORAGE_ACCOUNT = "<YOUR_STORAGE_ACCOUNT>"
AZURE_STORAGE_CONTAINER = "lakehouse"
AZURE_TENANT_ID = "<YOUR_TENANT_ID>"
AZURE_SP_CLIENT_ID = "<YOUR_CLIENT_ID>"
AZURE_SP_CLIENT_SECRET = "<YOUR_CLIENT_SECRET>"

# Initialize Spark Session
spark = SparkSession.builder.appName("IcebergToDeltaSync").getOrCreate()

# Configure credentials for writing directly back to ADLS Gen2 container
print("Configuring Spark session credentials for ADLS Gen2 access...")
dfs_endpoint = f"fs.azure.account.oauth.provider.type.{AZURE_STORAGE_ACCOUNT}.dfs.core.windows.net"
client_id_key = f"fs.azure.account.oauth2.client.id.{AZURE_STORAGE_ACCOUNT}.dfs.core.windows.net"
client_secret_key = f"fs.azure.account.oauth2.client.secret.{AZURE_STORAGE_ACCOUNT}.dfs.core.windows.net"
endpoint_key = f"fs.azure.account.oauth2.client.endpoint.{AZURE_STORAGE_ACCOUNT}.dfs.core.windows.net"
auth_type_key = f"fs.azure.account.auth.type.{AZURE_STORAGE_ACCOUNT}.dfs.core.windows.net"

spark.conf.set(auth_type_key, "OAuth")
spark.conf.set(dfs_endpoint, "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider")
spark.conf.set(client_id_key, AZURE_SP_CLIENT_ID)
spark.conf.set(client_secret_key, AZURE_SP_CLIENT_SECRET)
spark.conf.set(endpoint_key, f"https://login.microsoftonline.com/{AZURE_TENANT_ID}/oauth2/v2.0/token")

# 2. READ ICEBERG DATA FROM ONELAKE SHORTCUT
iceberg_shortcut_name = "revenue_by_country_iceberg"
print(f"Reading Iceberg shortcut table: {iceberg_shortcut_name}")
df_iceberg = spark.read.table(iceberg_shortcut_name)

# 3. WRITE DELTA DATA TO ADLS GEN2
delta_dest_path = f"abfss://{AZURE_STORAGE_CONTAINER}@{AZURE_STORAGE_ACCOUNT}.dfs.core.windows.net/gold/revenue_by_country_delta"
print(f"Syncing Iceberg data to Delta format at: {delta_dest_path}")

df_iceberg.write \
  .format("delta") \
  .mode("overwrite") \
  .save(delta_dest_path)

print("Delta sync completed successfully!")

# Verify by reading the Delta data back
print("Reading Delta data back to verify:")
df_delta = spark.read.format("delta").load(delta_dest_path)
df_delta.show(truncate=False)
