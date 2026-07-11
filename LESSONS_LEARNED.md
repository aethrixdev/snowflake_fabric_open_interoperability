# Technical Challenges & Lessons Learned

This document outlines the technical design decisions, challenges, and lessons learned during the implementation of the **Snowflake ↔ Microsoft Fabric Open Table Format Interoperability** project.

---

## 1. Format Translation & Write Limitations
- **Challenge**: Snowflake has excellent read and write support for Apache Iceberg but can only **read** Delta Lake tables via external tables (read-only integration). Programs cannot write Delta format from Snowflake natively.
- **Solution**: Designed a bi-directional format split where **Snowflake acts as the Iceberg writer** and **Fabric acts as the Delta writer**. This highlights how a heterogeneous engine environment can collaborate without format lock-in:
  - Snowflake writes Iceberg ➡️ Fabric reads Iceberg via Shortcut.
  - Fabric Spark reads Iceberg ➡️ Fabric writes Delta to ADLS ➡️ Snowflake reads Delta via External Table.

---

## 2. Snowflake External Volume vs. Storage Integration
- **Challenge**: Developers often confuse Snowflake Storage Integrations and External Volumes.
- **Lesson**:
  - **Storage Integrations** grant access to storage for traditional Snowflake tables (Stages, COPY, UNLOAD, and standard External Tables).
  - **External Volumes** are dedicated account-level objects required for Iceberg tables, acting as the catalog-to-storage interface.
  - In an Azure setup, creating both objects is required if you want to support both Iceberg tables (External Volume) and Delta Lake external tables (Storage Integration / Stage).

---

## 3. Microsoft Fabric Iceberg Shortcut Compatibility
- **Challenge**: Reading Iceberg format inside Fabric via shortcuts requires the Fabric workspace Spark engine to support Iceberg catalogs. Standard Spark configurations might fail to parse Iceberg metadata folders if not configured correctly.
- **Solution**: Developed a dual-mode PySpark script that attempts to read the table via the default Fabric Catalog translation, and falls back to configuring the Spark session with active Iceberg catalog support (`org.apache.iceberg.spark.SparkCatalog`) and loading direct abfss paths. This ensures high portability.

---

## 4. Column Governance & Downstream Propagation
- **Challenge**: Applying a masking policy in Snowflake restricts access to sensitive columns (like email). However, if masked data is written to an Iceberg file, the mask becomes hardcoded in the physical Parquet file, rendering it masked for all downstream readers (including Fabric).
- **Lesson**: Data masking must be applied at the consumption layer or handled via role-based access. In our architecture, the masking policy is applied to `silver.silver_orders` in Snowflake. The Gold table is an aggregation that does not contain raw customer emails, preventing PII leakage downstream. If raw columns are exported to Iceberg, security must be enforced at the Azure storage level (RBAC/ACLs) to ensure only authorized service principals can read those folders.

---

## 5. Direct Lake Freshness vs. Cache Latency
- **Challenge**: Power BI Direct Lake mode is designed to read OneLake files directly. However, after the sync notebook writes new Delta files, Power BI reports might still display old data due to Direct Lake caching.
- **Solution**: The solution is to trigger a semantic model refresh (in the Power BI Service or via API) which updates the model metadata to read the latest Delta transaction log, ensuring instant freshness without executing SQL queries or importing rows.

---

## 6. Snowflake Iceberg Physical Path Suffixing
- **Challenge**: When creating a Snowflake-managed Iceberg table, Snowflake appends a random 8-character alphanumeric suffix to the specified `BASE_LOCATION` (e.g., `verify_iceberg/` becomes `verify_iceberg.HgOpISFG/` in the ADLS Gen2 container). This means the literal `BASE_LOCATION` parameter provided in SQL does not match the actual physical storage path in ADLS Gen2.
- **Lesson**: Downstream systems—like Microsoft Fabric OneLake shortcuts—cannot construct shortcut targets blindly using the database schema paths. We must dynamically discover the physical path (e.g., via `az storage blob list` or querying the Iceberg metadata file location) after table creation to capture the random suffix before defining shortcuts.
