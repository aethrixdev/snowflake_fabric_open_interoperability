# Architectural Blueprint

This document details the data flow, security model, and format conversion patterns implemented in the **Snowflake ↔ Microsoft Fabric Open Table Format Interoperability** project.

---

## 📐 Data Flow Architecture

The following diagram illustrates how transaction data is ingested, refined, formatted, and shared bi-directionally across Snowflake and Microsoft Fabric:

```mermaid
graph TD
    %% Source & Ingestion
    CSV["data/sample_orders.csv"] -->|Uploaded via CLI| ADLS_Raw["ADLS Gen2 Container: raw/"]
    ADLS_Raw -->|COPY INTO via Storage Integration| SF_Raw["Snowflake Table: raw.raw_orders"]
    
    %% Snowflake Processing
    SF_Raw -->|Deduplicate & Clean MERGE| SF_Silver["Snowflake Table: silver.silver_orders"]
    SF_Silver -->|Insert Overwrite Aggregation| SF_Gold_Iceberg["Snowflake Iceberg Table: gold.revenue_by_country_iceberg"]
    
    %% Storage Plane
    SF_Gold_Iceberg -->|Writes Parquet & Metadata| ADLS_Iceberg["ADLS Gen2 Container: gold/revenue_by_country_iceberg/"]
    
    %% Fabric Ingestion & Sync
    ADLS_Iceberg -->|OneLake Shortcut| Fabric_Shortcut["Fabric Table Shortcut"]
    Fabric_Shortcut -->|Read via PySpark Notebook| Fabric_Spark["Fabric Synapse Spark Engine"]
    Fabric_Spark -->|Write Delta Lake Format| ADLS_Delta["ADLS Gen2 Container: gold/revenue_by_country_delta/"]
    
    %% Bi-Directional Consumption
    ADLS_Delta -->|Metadata Log Scan| SF_Gold_Delta["Snowflake External Table: gold.revenue_by_country_delta"]
    ADLS_Delta -->|Direct Lake Access| PowerBI["Power BI Report: Sales Revenue Dashboard"]

    %% Styling
    style CSV fill:#f9f,stroke:#333,stroke-width:2px
    style ADLS_Raw fill:#bbf,stroke:#333,stroke-width:1px
    style ADLS_Iceberg fill:#bbf,stroke:#333,stroke-width:2px
    style ADLS_Delta fill:#bbf,stroke:#333,stroke-width:2px
    style SF_Gold_Iceberg fill:#fbf,stroke:#333,stroke-width:2px
    style SF_Gold_Delta fill:#fbf,stroke:#333,stroke-width:2px
    style PowerBI fill:#bfb,stroke:#333,stroke-width:3px
```

---

## 🔒 Security and Access Control Model

A key pillar of this architecture is **secure delegated access** without hardcoded keys:
- **Snowflake to ADLS Gen2**: Snowflake uses a multi-tenant application registration in Entra ID. We retrieve the application name and consent to it in the customer's tenant, granting it the **Storage Blob Data Contributor** role on the storage account.
- **Fabric Spark to ADLS Gen2**: Fabric Spark notebooks authenticate using an Entra ID **Service Principal**. The Service Principal is granted **Storage Blob Data Contributor** role restricted specifically to the ADLS Gen2 Container level (least privilege principle).
- **Column-Level Governance**: In Snowflake, a dynamic **Masking Policy** is applied to the `email` column, restricting unprivileged roles (like `PUBLIC` or `analyst_role`) from viewing raw customer PII.

---

## 📂 Format Translation & Interoperability

This project highlights how data sharing is achieved using open table metadata standards:

### Apache Iceberg Format (Snowflake-Managed)
- Snowflake acts as the Iceberg Catalog.
- When Snowflake writes data, it outputs standard Apache Parquet data files alongside a `metadata/` directory containing Iceberg metadata (snapshots, manifests, and manifest lists).
- Microsoft Fabric reads this directly because its Spark engine parses the Iceberg metadata folders via OneLake ADLS Gen2 shortcuts.

### Delta Lake Format (Fabric-Managed)
- Microsoft Fabric Spark writes standard Apache Parquet data files alongside a `_delta_log/` transaction directory (JSON commits).
- Snowflake reads this data by specifying `TABLE_FORMAT = DELTA`. When we run a `REFRESH`, Snowflake scans the transaction log (`_delta_log/*.json`) to instantly detect new parquet files and drop obsolete ones, providing ACID-compliant snapshot isolation queries.
