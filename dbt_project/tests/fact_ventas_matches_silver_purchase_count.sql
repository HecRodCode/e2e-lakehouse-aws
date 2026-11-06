with silver_purchases as (
    select count(*) as n_rows
    from {{ source('lakehouse', 'rees46_events') }}
    where event_type = 'purchase'
),

gold_purchases as (
    select count(*) as n_rows
    from {{ ref('fact_ventas') }}
)

select
    silver_purchases.n_rows as silver_purchase_rows,
    gold_purchases.n_rows as gold_fact_rows
from silver_purchases
cross join gold_purchases
where silver_purchases.n_rows <> gold_purchases.n_rows
