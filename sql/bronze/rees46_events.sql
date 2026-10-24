CREATE TABLE IF NOT EXISTS glue.bronze.rees46_events (
    event_time    STRING,
    event_type    STRING,
    product_id    BIGINT,
    category_id   BIGINT,
    category_code STRING,
    brand         STRING,
    price         DOUBLE,
    user_id       BIGINT,
    user_session  STRING,
    event_date    DATE,
    _ingested_at  TIMESTAMP,
    _source       STRING,
    _batch_id     STRING
)
USING iceberg
PARTITIONED BY (event_date)