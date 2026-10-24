CREATE TABLE IF NOT EXISTS glue.silver.rees46_events_quarantine (
  event_time        STRING,
  event_date        DATE,
  event_type        STRING,
  product_id        BIGINT,
  category_id       BIGINT,
  category_code     STRING,
  brand             STRING,
  price             DOUBLE,
  user_id           BIGINT,
  user_session      STRING,
  reject_reason     STRING,
  _silver_batch_id  STRING,
  _processed_at     TIMESTAMP_NTZ
)
USING iceberg
PARTITIONED BY (event_date)
TBLPROPERTIES ('format-version' = '2');