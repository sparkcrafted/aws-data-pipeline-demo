# Apps (Transforms & Producers)
Runtime code used by the pipeline.

**Planned layout**
- `lambda_csv_to_parquet/` — CSV→Parquet converter (Python)
- `glue_jobs/` — PySpark jobs (optional)
- `streaming_producer_mock/` — small script to send JSON events to Firehose
- `athena_queries/` — verification SQL (clean/stream outputs)

> Keep code decoupled from infra; config via env vars or parameters.
