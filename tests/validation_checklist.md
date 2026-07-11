# Manual Validation Checklist

This checklist guides you through verifying the correctness of each layer in the Snowflake ↔ Microsoft Fabric interoperability project.

---

## 🟩 Phase 1: Environment Setup (`spec-01`)
- [ ] Run `create_storage_account.sh` ➡️ Verify Resource Group, ADLS Gen2 Storage Account, and Container exist in Azure.
- [ ] Run `create_service_principal.sh` ➡️ Verify Service Principal exists in Microsoft Entra ID and has `Storage Blob Data Contributor` role on the ADLS Gen2 Container.
- [ ] Verify `.env` has been auto-updated with the Service Principal Client ID and Secret.
- [ ] Run Step 3 Snowflake DDL ➡️ Verify Storage Integration and External Volume exist.
- [ ] Admin Consent ➡️ Log in to Azure Admin Consent URL and accept.
- [ ] Role Assignment ➡️ Search for the Snowflake multi-tenant application and assign it `Storage Blob Data Contributor` at the Azure Storage Account level.
- [ ] Connectivity Verification ➡️ Run `03_verify_integration.sql` and confirm:
  - CSV file written to `verify_stage/`
  - Iceberg files written to `verify_iceberg/`
  - Check ADLS Gen2 container in Azure Portal or CLI to verify files exist.

---

## 🟩 Phase 2: Ingestion & Cleansing (`spec-02`)
- [ ] Run CLI upload ➡️ Verify `raw/sample_orders.csv` is uploaded to ADLS Gen2.
- [ ] Run Snowflake schemas & tables setup ➡️ Verify `staging`, `raw`, `silver`, `gold` schemas exist.
- [ ] Run COPY ➡️ Verify raw table contains **20** rows.
- [ ] Run Silver Merge ➡️ Verify silver table contains **15** rows (cleansed, lowercase email, deduplicated by order ID, corrupt records filtered).

---

## 🟩 Phase 3: Gold Conversion (`spec-03`)
- [ ] Run DDL ➡️ Verify `gold.revenue_by_country_iceberg` and `gold.revenue_by_country_delta` exist.
- [ ] Run Overwrite ➡️ Verify `gold.revenue_by_country_iceberg` has rows.
- [ ] Verify Storage Blobs ➡️ Run Azure CLI storage list and verify `gold/revenue_by_country_iceberg/` has metadata and parquet data files.

---

## 🟩 Phase 4: Fabric Integration (`spec-04`)
- [ ] Create Iceberg Table Shortcut ➡️ Verify `revenue_by_country_iceberg` table appears in Fabric Lakehouse Explorer.
- [ ] Create Delta Table Shortcut ➡️ Verify `revenue_by_country_delta` table appears in Fabric Lakehouse Explorer.
- [ ] Run Read Notebook `01_read_iceberg_shortcut` ➡️ Verify Spark reads and prints the Snowflake Iceberg table data.
- [ ] Run Sync Notebook `02_read_delta_shortcut_and_sync` ➡️ Verify Spark runs without error, writes to Delta format on ADLS Gen2, and prints the matching dataset.
- [ ] Verify Delta logs ➡️ Verify `gold/revenue_by_country_delta/_delta_log/` exists in Azure.

---

## 🟩 Phase 5: Pipeline & Interop Validation (`spec-05`)
- [ ] Run automated script `./scripts/run_pipeline.sh` ➡️ Verify new rows are generated, uploaded, ingested into raw, merged into silver, and aggregated in Gold Iceberg.
- [ ] Run Fabric Sync Notebook ➡️ Verify Delta table is updated in ADLS Gen2.
- [ ] Run validation script `python3 scripts/validate_interop.py` ➡️ Verify console displays status `MATCH ✅` for all countries and prints success.
- [ ] Run Fabric notebook `03_compare_row_counts` ➡️ Verify counts match in Spark.

---

## 🟩 Phase 6: Schema Evolution & Governance (`spec-06`)
- [ ] Run schema evolution SQL ➡️ Verify column `discount_amount` is added to Iceberg table in Snowflake and updated.
- [ ] Verify in Fabric ➡️ Read the Iceberg shortcut in Fabric Spark and verify `discount_amount` column is automatically detected and populated.
- [ ] Masking Policy ➡️ Create policy, apply to `silver_orders.email`, and query as `SYSADMIN` (raw email visible) and as `analyst_role` (masked email `*********@...` visible).

---

## 🟩 Phase 7: Power BI Direct Lake (`spec-07`)
- [ ] Create Semantic Model ➡️ Verify model `revenue_by_country_model` contains `revenue_by_country_delta`.
- [ ] Create Power BI report ➡️ Build map/chart, KPI card, and update time card.
- [ ] Execute Live Update ➡️ Run `./scripts/run_pipeline.sh`, run Fabric sync notebook, refresh Power BI dashboard in browser, and verify values update instantly without import refreshes.
