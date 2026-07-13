# spec-05-live-interop-validation — Revision Log

This log documents the execution and validation of the end-to-end data pipeline interoperability between Snowflake and Fabric.

## Execution Log

1.  **Live Data Generation**: Ran `scripts/run_pipeline.sh`. Successfully generated new random sales orders, uploaded them to Azure, and executed the Snowflake ingestion/transformation pipeline (Raw -> Silver -> Gold Iceberg).
2.  **Fabric Sync**: Executed the `02_read_delta_shortcut_and_sync` notebook in Microsoft Fabric to detect the new Iceberg rows and sync them to the Delta table in Azure.
3.  **Cross-Format Validation**: 
    *   Executed the Python validation script (`scripts/validate_interop.py`) locally.
    *   Ran the Fabric comparison notebook (`03_compare_row_counts`).

## Verification Results

*   **Row Counts Match**: The Fabric comparison notebook confirmed that the Iceberg shortcut and Delta table counts match perfectly.
*   **Metrics Match**: The `validate_interop.py` script output confirmed `MATCH ✅` for all country revenue and order metrics across both Iceberg (read via Snowflake) and Delta (read via Snowflake External Table).
*   **Success Status**: Pipeline confirmed working end-to-end: "🎉 SUCCESS: Iceberg and Delta tables are in perfect sync!".

## Revisions and Lessons Learned

*   **Bidirectional Architecture**: We successfully demonstrated that a heterogeneous engine environment can collaborate without format lock-in. Snowflake acts as the robust Iceberg writer, while Fabric seamlessly reads Iceberg and writes Delta.
