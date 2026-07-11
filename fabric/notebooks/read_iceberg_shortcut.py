# Read Iceberg shortcut in Fabric Spark
# This script is meant to be run inside a Microsoft Fabric Notebook attached to your Lakehouse.

from pyspark.sql import SparkSession

# Initialize Spark Session
spark = SparkSession.builder.appName("ReadIcebergShortcut").getOrCreate()

# Name of the Iceberg table shortcut created in the Lakehouse
TABLE_NAME = "revenue_by_country_iceberg"

print("==================================================================")
print(f"Attempting to read Iceberg shortcut table: {TABLE_NAME}")
print("==================================================================")

try:
    # 1. Read the table using Fabric Spark's default catalog
    df = spark.read.table(TABLE_NAME)
    
    print("Successfully read table. Printing schema:")
    df.printSchema()
    
    print("Showing top 20 records:")
    df.show(truncate=False)
    
    # Print record count
    print(f"Total Iceberg record count: {df.count()}")
    
except Exception as e:
    print("ERROR: Failed to query Iceberg shortcut table.")
    print(f"Details: {str(e)}")
    print("\nTroubleshooting tips:")
    print("1. Ensure the ADLS Gen2 container contains the metadata/ and data/ directories.")
    print("2. Check that the OneLake shortcut is placed under the 'Tables' folder and named exactly 'revenue_by_country_iceberg'.")
    print("3. Ensure the Fabric Spark session is running with a runtime that natively virtualizes Iceberg metadata.")
print("==================================================================")
