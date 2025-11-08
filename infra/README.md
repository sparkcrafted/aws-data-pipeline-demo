# Infrastructure (Public Twin)
Infrastructure-as-Code for the demo environment.

**Modules (planned):**
- `s3_lake/` — landing/clean/curated buckets + lifecycle
- `glue_catalog/` — databases, crawlers, tables
- `lakeformation/` — RBAC, LF-Tags, grants
- `dms_mysql_to_s3/` — demo MySQL + DMS replication to S3 (full load)
- `firehose_to_s3/` — Kinesis Data Firehose stream to landing

> Use placeholders for ARNs/bucket names. Never commit state files or secrets.
