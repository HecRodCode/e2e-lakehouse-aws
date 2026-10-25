CREATE TABLE IF NOT EXISTS glue.ops.pipeline_runs (
  run_id            STRING,
  pipeline          STRING,
  status            STRING,
  started_at        TIMESTAMP_NTZ,
  finished_at       TIMESTAMP_NTZ,
  duration_seconds  DOUBLE,
  rows_read         BIGINT,
  rows_written      BIGINT,
  rows_rejected     BIGINT,
  details           STRING,
  error_message     STRING
)
USING iceberg
TBLPROPERTIES ('format-version' = '2');