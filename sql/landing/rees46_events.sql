CREATE EXTERNAL TABLE landing.rees46_events (
  event_time    string,
  event_type    string,
  product_id    bigint,
  category_id   bigint,
  category_code string,
  brand         string,
  price         double,
  user_id       bigint,
  user_session  string
)
PARTITIONED BY (event_date string)
STORED AS PARQUET
LOCATION 's3:/lakehouse-datalake-106948907720/landing/rees46/'
TBLPROPERTIES (
  'projection.enabled'            = 'true',
  'projection.event_date.type'    = 'date',
  'projection.event_date.range'   = '2019-10-01,2019-10-31',
  'projection.event_date.format'  = 'yyyy-MM-dd',
  'storage.location.template'     = 's3://lakehouse-datalake-106948907720/landing/rees46/event_date=${event_date}'
);