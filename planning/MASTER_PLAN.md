# Master Plan

This project implements a secure, bi-directional data sharing architecture between Snowflake (Apache Iceberg tables) and Microsoft Fabric (OneLake / Delta Lake tables).

| Milestone | Description | Status |
|---|---|---|
| **spec-01-environment-setup** | ADLS Gen2, Service Principal, Snowflake Storage Integration, External Volume | **Done** |
| **spec-02-raw-to-silver-gold-snowflake** | Raw CSV ingestion, cleaning, Silver schema, Gold business aggregation | **Done** |
| **spec-03-iceberg-and-delta-gold-conversion** | Iceberg table conversion, Delta conversion, manifest generation | **Done** |
| **spec-04-fabric-shortcut-and-notebook-read** | Fabric ADLS shortcuts, PySpark notebook validation | **Done** |
| **spec-05-live-interop-validation** | Automated pipeline sync and cross-engine read/write verification | **Done** |
| **spec-06-schema-evolution-and-governance** | Schema evolution handling, column addition, IAM/RBAC policy check | **Done** |
| **spec-07-powerbi-direct-lake-dashboard** | Power BI Direct Lake configuration and report testing | **Done** |
| **spec-08-teardown-and-writeup** | Infrastructure teardown, final project documentation, writeup | **Done (Ready for Execution later)** |
