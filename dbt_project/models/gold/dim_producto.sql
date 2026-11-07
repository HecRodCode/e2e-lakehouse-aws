{{ config(
    materialized='table',
    table_type='iceberg',
    format='parquet'
) }}

with ranked_products as (
    select
        product_id,
        category_id,
        category_code,
        brand,
        row_number() over (
            partition by product_id
            order by event_time desc nulls last, event_hash desc
        ) as row_num
    from {{ source('lakehouse', 'rees46_events') }}
    where product_id is not null
)

select
    product_id,
    category_id,
    category_code,
    brand
from ranked_products
where row_num = 1
