select event_hash
from {{ ref('fact_ventas') }}
where price <= 0
   or not price_is_valid
   or price_imputed
