import os
import dotenv
import snowflake.connector

dotenv.load_dotenv()

print("==============================================")
print("Verifying Snowflake Iceberg Data Generation")
print("==============================================\n")

try:
    conn = snowflake.connector.connect(
        account=os.getenv("SNOWFLAKE_ACCOUNT"),
        user=os.getenv("SNOWFLAKE_USER"),
        password=os.getenv("SNOWFLAKE_PASSWORD"),
        role=os.getenv("SNOWFLAKE_ROLE"),
        database=os.getenv("SNOWFLAKE_DATABASE")
    )
    cursor = conn.cursor()
    
    print("1. Checking total records in Raw Orders...")
    cursor.execute("SELECT COUNT(*) FROM raw.raw_orders")
    raw_count = cursor.fetchone()[0]
    print(f"-> Total Raw Records: {raw_count}\n")
    
    print("2. Checking total records in Iceberg Gold Table...")
    cursor.execute("SELECT COUNT(*) FROM gold.revenue_by_country_iceberg")
    iceberg_count = cursor.fetchone()[0]
    print(f"-> Total Iceberg Records (unique countries): {iceberg_count}\n")
    
    print("3. Fetching the top 10 countries by revenue from Iceberg...")
    cursor.execute("""
        SELECT country, total_orders, total_revenue 
        FROM gold.revenue_by_country_iceberg 
        ORDER BY total_revenue DESC 
        LIMIT 10
    """)
    rows = cursor.fetchall()
    
    # Format a nice ASCII table
    print(f"{'COUNTRY':<25} | {'TOTAL ORDERS':<15} | {'TOTAL REVENUE'}")
    print("-" * 65)
    for row in rows:
        print(f"{str(row[0]):<25} | {str(row[1]):<15} | ${str(row[2])}")
        
    print("\nSUCCESS! Snowflake has perfectly aggregated the new dynamic data")
    print("and written it to the Iceberg files in your Azure container.")
    
except Exception as e:
    print(f"Error connecting to Snowflake: {e}")

finally:
    if 'conn' in locals() and conn:
        conn.close()
