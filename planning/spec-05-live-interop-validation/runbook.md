# spec-05-live-interop-validation — Runbook

This runbook guides you through executing the automated pipeline, generating live rows, syncing the data, and performing cross-engine validations.

---

## Step 1: Run Ingestion and Snowflake Pipeline (CLI)

Run the shell script to generate live data, upload to Azure, and ingest it in Snowflake:
```bash
# Set execute permissions
chmod +x scripts/run_pipeline.sh

# Run pipeline
./scripts/run_pipeline.sh
```

**Verification of Step 1**:
- The script should print that the pipeline completed.
- It should show the raw order counts (should increase by 5) and the silver/iceberg counts.

---

## Step 2: Run the Sync Notebook in Microsoft Fabric (Manual Browser Steps)

1. Open your browser and navigate to the **Microsoft Fabric Portal**.
2. Open your Fabric Workspace and click on the **`02_read_delta_shortcut_and_sync`** notebook.
3. Click **Run All** to execute the Spark job.
4. Confirm the job runs successfully, reads the updated Iceberg data via OneLake shortcut, and overrides the Delta table in ADLS Gen2 with the new rows.

---

## Step 3: Execute Fabric Comparison Notebook (Manual Browser Steps)

1. In the Fabric Workspace, click on the **`03_compare_row_counts`** notebook (or create a new notebook with the contents of [compare_row_counts.py](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/fabric/notebooks/compare_row_counts.py)).
2. Click **Run All**.
3. Verify that the output prints:
   `🎉 SUCCESS: OneLake Iceberg shortcut and Delta table counts match perfectly!`

---

## Step 4: Run CLI Cross-Format Validation Tool (CLI)

Verify that Snowflake can read the Fabric-written Delta table and that the numbers match the Iceberg table.

Run:
```bash
python3 scripts/validate_interop.py
```

**Success Criteria**:
- The script should print a table comparing Iceberg and Delta metrics for each country.
- The status for all rows should be `MATCH ✅`.
- The final output should show: `🎉 SUCCESS: Iceberg and Delta tables are in perfect sync!`.
