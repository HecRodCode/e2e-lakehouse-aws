{{ config(
    materialized='table',
    table_type='iceberg',
    format='parquet'
) }}

with purchase_date_bounds as (
    select
        min(event_date) as first_date,
        max(event_date) as last_date
    from {{ source('lakehouse', 'rees46_events') }}
    where event_type = 'purchase'
      and event_date is not null
),

calendar_dates as (
    select date_add('day', day_offset, first_date) as date_day
    from purchase_date_bounds
    cross join unnest(sequence(0, date_diff('day', first_date, last_date))) as dates(day_offset)
)

select
    cast(date_format(date_day, '%Y%m%d') as integer) as date_key,
    date_day,
    year(date_day) as year,
    quarter(date_day) as quarter,
    month(date_day) as month,
    day(date_day) as day_of_month,
    day_of_week(date_day) as day_of_week,
    date_format(date_day, '%W') as day_name,
    date_format(date_day, '%M') as month_name,
    day_of_week(date_day) in (6, 7) as is_weekend
from calendar_dates
