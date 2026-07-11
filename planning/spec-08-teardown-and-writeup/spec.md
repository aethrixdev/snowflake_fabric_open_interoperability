# spec-08-teardown-and-writeup — Spec

## Overview
This milestone covers clean infrastructure teardown and final repository documentation. It ensures no active cloud services linger (to avoid ongoing costs) and updates the portfolio writeup files (README, ARCHITECTURE, LESSONS_LEARNED) with detailed architectural insights.

## What This Milestone Builds
1. **Teardown Script**:
   - A shell script `teardown.sh` to remove all Snowflake-managed objects (database, warehouse, storage integrations, external volumes) and delete the Azure resource group and AD service principal.
2. **Project Portfolio Writeup**:
   - Updates to the root project documentation:
     - **[README.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/README.md)**: High-level overview, quick start, and instructions.
     - **[ARCHITECTURE.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/ARCHITECTURE.md)**: Data flow diagram, architecture details, and format conversion logic.
     - **[LESSONS_LEARNED.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/LESSONS_LEARNED.md)**: Technical challenges, format translation details, and lessons learned.

## What "Done" Looks Like
- `teardown.sh` runs successfully, leaving no remaining assets in Azure or Snowflake.
- Root markdown files contain a complete, professional portfolio description.
- MASTER_PLAN is fully marked as Done.

## Target Files to Implement
- [spec.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/planning/spec-08-teardown-and-writeup/spec.md): This file, defining the spec.
- [teardown.sh](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/infra/teardown.sh): Shell script to clean up cloud resources.
- [README.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/README.md): Repository documentation.
- [ARCHITECTURE.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/ARCHITECTURE.md): Architecture description.
- [LESSONS_LEARNED.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/LESSONS_LEARNED.md): Lessons learned.
- [runbook.md](file:///Users/dev/Downloads/snowflake-fabric-iceberg-interop/planning/spec-08-teardown-and-writeup/runbook.md): Runbook executing final teardown.
