#!/usr/bin/env python3
# Automated cross-engine validation
# Connects to Snowflake to query both Iceberg and Delta tables, comparing row count and revenue sums.

import os
import sys
from tabulate import tabulate
import snowflake.connector
from dotenv import load_dotenv

# Load environments
load_dotenv()

# Validate env variables
required = ["SNOWFLAKE_ACCOUNT", "SNOWFLAKE_USER", "SNOWFLAKE_PASSWORD", "SNOWFLAKE_DATABASE", "SNOWFLAKE_ROLE", "SNOWFLAKE_WAREHOUSE"]
for var in required:
    if not os.getenv(var):
        print(f"ERROR: Missing environment variable {var} in .env")
        sys.exit(1)

print("Connecting to Snowflake for validation...")
conn = snowflake.connector.connect(
    account=os.getenv("SNOWFLAKE_ACCOUNT"),
    user=os.getenv("SNOWFLAKE_USER"),
    password=os.getenv("SNOWFLAKE_PASSWORD"),
    role=os.getenv("SNOWFLAKE_ROLE"),
    warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
    database=os.getenv("SNOWFLAKE_DATABASE")
)

cursor = conn.cursor()

# 1. Query Iceberg Table
print("Querying gold.revenue_by_country_iceberg...")
cursor.execute("""
    SELECT 
        country, 
        SUM(total_revenue) AS rev, 
        SUM(total_orders) AS ords
    FROM gold.revenue_by_country_iceberg
    GROUP BY country
    ORDER BY country
""")
iceberg_data = cursor.fetchall()
iceberg_dict = {row[0]: (float(row[1]), int(row[2])) for row in iceberg_data}

# 2. Refresh Delta Table first to ensure it's up to date
print("Refreshing gold.revenue_by_country_delta external table...")
cursor.execute("ALTER EXTERNAL TABLE gold.revenue_by_country_delta REFRESH")

# 3. Query Delta External Table
print("Querying gold.revenue_by_country_delta...")
cursor.execute("""
    SELECT 
        VALUE:COUNTRY::VARCHAR AS country,
        SUM(VALUE:TOTAL_REVENUE::NUMBER(38,2)) AS rev,
        SUM(VALUE:TOTAL_ORDERS::INT) AS ords
    FROM gold.revenue_by_country_delta
    GROUP BY country
    ORDER BY country
""")
delta_data = cursor.fetchall()
delta_dict = {row[0]: (float(row[1]), int(row[2])) for row in delta_data}

# 4. Compare and display results
print("\n=== CROSS-FORMAT INTEROPERABILITY COMPONENT COMPARISON ===")

all_countries = sorted(list(set(list(iceberg_dict.keys()) + list(delta_dict.keys()))))
comparison_rows = []
mismatch_detected = False

for country in all_countries:
    ice_rev, ice_ords = iceberg_dict.get(country, (0.0, 0))
    del_rev, del_ords = delta_dict.get(country, (0.0, 0))
    
    match = "MATCH ✅"
    if abs(ice_rev - del_rev) > 0.01 or ice_ords != del_ords:
        match = "MISMATCH ❌"
        mismatch_detected = True
        
    comparison_rows.append([
        country,
        f"${ice_rev:,.2f}", f"${del_rev:,.2f}",
        ice_ords, del_ords,
        match
    ])

headers = ["Country", "Iceberg Rev", "Delta Rev", "Iceberg Orders", "Delta Orders", "Status"]
print(tabulate(comparison_rows, headers=headers, tablefmt="grid"))

print("\n=== SUMMARY ===")
iceberg_total_ords = sum([x[1] for x in iceberg_dict.values()])
delta_total_ords = sum([x[1] for x in delta_dict.values()])
print(f"Total Iceberg Orders: {iceberg_total_ords}")
print(f"Total Delta Orders:   {delta_total_ords}")

if mismatch_detected:
    print("\n❌ VALIDATION FAILURE: Mismatch detected between Iceberg and Delta formats.")
    sys.exit(1)
elif len(all_countries) == 0:
    print("\n⚠️ WARNING: No data records found to compare.")
    sys.exit(0)
else:
    print("\n🎉 SUCCESS: Iceberg and Delta tables are in perfect sync!")
    sys.exit(0)
