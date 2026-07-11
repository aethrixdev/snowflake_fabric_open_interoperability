# spec-04-fabric-shortcut-and-notebook-read — Spec

## Overview
This milestone establishes the Microsoft Fabric layer of our interoperability architecture. It configures OneLake shortcuts to read the Gold Iceberg table written by Snowflake and uses Fabric Spark notebooks to read the Iceberg table, perform logic, and write back the Gold Delta table to ADLS Gen2.

## What This Milestone Builds
1. **OneLake ADLS Gen2 Shortcuts**:
   - Instructions to configure a OneLake shortcut inside a Fabric Lakehouse pointing to the actual Snowflake-managed Iceberg folder containing the random suffix (observed: `gold/revenue_by_country_iceberg.EVL46xbr/` in ADLS Gen2).
   - Instructions to configure a OneLake shortcut pointing to the Delta table base directory `gold/revenue_by_country_delta/`.
2. **Fabric Spark Notebook - Read Iceberg Table**:
   - A Python Spark script `read_iceberg_shortcut.py` that runs in Fabric to load the virtualized Iceberg table from the OneLake shortcut, print its schema, and display the aggregated revenue data.
3. **Fabric Spark Notebook - Write/Sync Delta Table**:
   - A Python Spark script `read_delta_shortcut.py` (which acts as our synchronization agent) that reads the Iceberg shortcut, applies Spark session configurations to authenticate against ADLS Gen2 using the Service Principal (`AZURE_SP_CLIENT_ID`), and writes/overwrites the data as a Delta Lake table at `gold/revenue_by_country_delta/` in ADLS Gen2.

## What "Done" Looks Like
- A Fabric Lakehouse is active with a shortcut pointing to the Iceberg table folder in ADLS Gen2.
- The `read_iceberg_shortcut.py` notebook runs successfully in Fabric, displaying the revenue aggregation.
- The `read_delta_shortcut.py` notebook runs successfully, writing a Delta table in ADLS Gen2 under `gold/revenue_by_country_delta/`, which creates the standard `_delta_log` and Parquet data files.

## Target Files to Implement
- [spec.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/planning/spec-04-fabric-shortcut-and-notebook-read/spec.md): This file, defining the spec.
- [shortcut_config.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/fabric/shortcuts/shortcut_config.md): Detailed markdown guide for creating shortcuts in the Microsoft Fabric Portal.
- [read_iceberg_shortcut.py](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/fabric/notebooks/read_iceberg_shortcut.py): Spark Python script for reading the Iceberg table.
- [read_delta_shortcut.py](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/fabric/notebooks/read_delta_shortcut.py): Spark Python script for reading Iceberg and writing Delta.
- [runbook.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/planning/spec-04-fabric-shortcut-and-notebook-read/runbook.md): Detailed steps to upload notebooks and run them in Fabric.
