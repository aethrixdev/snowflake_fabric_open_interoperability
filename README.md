# Snowflake ↔ Microsoft Fabric Open Table Format Interoperability

This repository contains a complete data engineering portfolio project implementing a secure, bi-directional data sharing architecture between **Snowflake (Apache Iceberg tables)** and **Microsoft Fabric (OneLake / Delta Lake tables)**. 

By leveraging native support for open table formats and cloud virtualization, this design eliminates the need for expensive, redundant data copy (ETL) pipelines, enabling direct cross-engine querying and real-time business intelligence (BI) consumption.

---

## 🏗️ Architecture Overview

The system establishes a closed-loop data sharing architecture using **Azure Data Lake Storage (ADLS) Gen2** as the shared storage plane:
1. **Ingestion & Processing (Snowflake)**: Ingests raw sales transaction data, refines it to Silver, and writes Gold aggregations in **Apache Iceberg** format directly to ADLS Gen2.
2. **Virtualization & Reading (Microsoft Fabric)**: Connects to the Iceberg table folder in ADLS Gen2 via a **OneLake shortcut** (zero-copy read) and processes it using PySpark notebooks.
3. **Writing & Sync (Microsoft Fabric)**: Synthesizes and writes the data in **Delta Lake** format back to ADLS Gen2 using an Azure Service Principal.
4. **Bi-Directional Consumption (Snowflake & Power BI)**:
   - Snowflake reads the Delta Lake table in place using a **Delta External Table**.
   - Power BI queries the Delta Lake table in real time using high-performance **Direct Lake mode** (zero import/schedule refreshes).

For a detailed data flow diagram and format breakdown, see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## 🛠️ Technology Stack
- **Data Warehousing & Catalog**: Snowflake (Enterprise Edition with Iceberg support)
- **Data Lake Storage**: Microsoft Azure ADLS Gen2
- **Analytics & BI Engine**: Microsoft Fabric (Synapse Spark notebooks & Power BI Direct Lake)
- **Security & Access Control**: Azure Entra ID (Service Principals & RBAC), Snowflake Masking Policies
- **Language & Orchestration**: Python 3.9+, Bash, SQL, PySpark

---

## 📂 Directory Structure

```directory
.
├── ARCHITECTURE.md          # Data flow and architectural patterns
├── LESSONS_LEARNED.md       # Technical challenges and resolution details
├── README.md                # Project home page and quick start guide
├── requirements.txt         # Local python dependencies
├── data/
│   ├── sample_orders.csv            # Static raw transaction sample
│   ├── generate_live_update.py      # Script to simulate live transactions
│   └── live_orders_update.csv       # Dynamically generated records
├── infra/
│   ├── teardown.sh                  # Full environment cleanup script
│   ├── azure/
│   │   ├── create_storage_account.sh    # ADLS Gen2 storage setup
│   │   └── create_service_principal.sh  # SP creation and credential capture
│   └── snowflake/
│       ├── 01_storage_integration.sql   # Storage integrations & ext volume
│       ├── 02_grants.sql                # Databases, warehouses, and RBAC
│       └── 03_verify_integration.sql    # Connectivity test stage & tables
├── snowflake/
│   ├── ddl/                         # Database table DDL structures
│   ├── loads/                       # COPY commands and staging setups
│   ├── transforms/                  # Merge aggregations & schema evolution
│   └── governance/                  # Data masking and column privacy
├── fabric/
│   ├── notebooks/                   # PySpark verification & sync notebooks
│   ├── shortcuts/                   # OneLake shortcut guides
│   └── powerbi/                     # Direct Lake semantic model guides
└── planning/                        # Spec and runbook files by milestone
```

---

## 🚀 Quick Start Guide

### Step 1: Environment Configuration
1. Clone this repository to your local workspace.
2. Copy `.env.example` to `.env` and fill in your Azure and Snowflake admin credentials:
   ```bash
   cp .env.example .env
   ```

### Step 2: Deploy Infrastructure
Follow the step-by-step runbooks for each milestone in order:
1. **[Milestone 1: Environment Setup](planning/spec-01-environment-setup/runbook.md)**: Deploy Azure storage resources, service principal, Snowflake storage integrations, and external volumes.
2. **[Milestone 2: Raw Ingestion & Cleansing](planning/spec-02-raw-to-silver-gold-snowflake/runbook.md)**: Load sample transactions, clean and merge them into Snowflake Silver tables.
3. **[Milestone 3: Gold Conversions](planning/spec-03-iceberg-and-delta-gold-conversion/runbook.md)**: Compile business aggregations and write them to Apache Iceberg format. Set up the Delta external table.
4. **[Milestone 4: Fabric Integration](planning/spec-04-fabric-shortcut-and-notebook-read/runbook.md)**: Set up OneLake shortcuts and execute the PySpark notebooks in Fabric to sync Iceberg to Delta.
5. **[Milestone 5: Live Interop Validation](planning/spec-05-live-interop-validation/runbook.md)**: Run the dynamic transaction update script and run the cross-engine validation checks.
6. **[Milestone 6: Schema Evolution & Governance](planning/spec-06-schema-evolution-and-governance/runbook.md)**: Verify column-level masking and trigger schema updates that propagate downstream.
7. **[Milestone 7: Power BI Direct Lake](planning/spec-07-powerbi-direct-lake-dashboard/runbook.md)**: Construct the semantic model and view real-time report updates without schedule refreshes.
8. **[Milestone 8: Teardown](planning/spec-08-teardown-and-writeup/runbook.md)**: Run the teardown script to destroy all cloud resources.
