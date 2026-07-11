# Compare Iceberg and Delta Table row counts in Fabric
# This notebook compares row counts and aggregated revenue sums between the formats in Fabric.

from pyspark.sql import SparkSession

# Initialize Spark Session
spark = SparkSession.builder.appName("CompareRowCounts").getOrCreate()

print("==================================================================")
print("Comparing Iceberg and Delta formats in Microsoft Fabric OneLake...")
print("==================================================================")

try:
    # Disable vectorized reader to allow conversions on the fly
    spark.conf.set("spark.sql.parquet.enableVectorizedReader", "false")

    # 1. Read Iceberg Shortcut
    try:
        df_iceberg = spark.read.table("revenue_by_country_iceberg")
    except Exception:
        # Fallback to direct folder path read
        df_iceberg = spark.read.format("parquet").load("Tables/Unidentified/revenue_by_country_iceberg.2RWQOBPl/data")
    
    # 2. Read Delta Table (via shortcut, or directly)
    try:
        df_delta = spark.read.table("revenue_by_country_delta")
    except Exception:
        # Fallback to direct path read
        df_delta = spark.read.format("delta").load("Tables/revenue_by_country_delta")

    # 3. Calculate Aggregates
    iceberg_metrics = df_iceberg.groupBy().sum("total_orders", "total_revenue").collect()[0]
    delta_metrics = df_delta.groupBy().sum("total_orders", "total_revenue").collect()[0]

    iceberg_ords = iceberg_metrics[0] or 0
    iceberg_rev = float(iceberg_metrics[1] or 0.0)
    delta_ords = delta_metrics[0] or 0
    delta_rev = float(delta_metrics[1] or 0.0)

    print("=== FABRIC COMPONENT METRIC VALIDATION ===")
    print(f"Iceberg Total Orders:  {iceberg_ords}")
    print(f"Delta Total Orders:    {delta_ords}")
    print(f"Iceberg Total Revenue: ${iceberg_rev:,.2f}")
    print(f"Delta Total Revenue:   ${delta_rev:,.2f}")
    print("==========================================")

    if iceberg_ords == delta_ords and abs(iceberg_rev - delta_rev) < 0.01:
         print("\n🎉 SUCCESS: OneLake Iceberg shortcut and Delta table counts match perfectly!")
    else:
         print("\n❌ MISMATCH FAILURE: Counts or revenue totals do not align.")
         
except Exception as e:
    print(f"ERROR: Failed to run cross-format metric comparison: {str(e)}")
print("==================================================================")
