{{ config(
    materialized='table',
    table_type='iceberg',
    format='parquet'
) }}

select
    event_hash,
    event_type,
    event_date,
    event_time,
    product_id,
    user_id,
    user_session,
    price,
    price_imputed,
    price_is_valid
from {{ source('lakehouse', 'rees46_events') }}
where event_type = 'purchase'
