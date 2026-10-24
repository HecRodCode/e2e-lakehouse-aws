CREATE TABLE IF NOT EXISTS glue.silver.rees46_events (
  event_time        TIMESTAMP_NTZ,
  event_date        DATE,
  event_type        STRING,
  product_id        BIGINT,
  category_id       BIGINT,
  category_code     STRING,
  brand             STRING,
  price             DOUBLE,
  price_imputed     BOOLEAN,
  price_is_valid    BOOLEAN,
  user_id           BIGINT,
  user_session      STRING,
  event_hash        STRING,
  _silver_batch_id  STRING,
  _processed_at     TIMESTAMP_NTZ
)
USING iceberg
PARTITIONED BY (event_date)
TBLPROPERTIES ('format-version' = '2');