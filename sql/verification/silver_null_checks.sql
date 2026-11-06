-- Recuento de nulos en columnas clave de Silver.
-- Los campos de texto opcionales se normalizan a 'unknown' en Silver.
SELECT
    count_if(event_time IS NULL) AS null_event_time,
    count_if(event_date IS NULL) AS null_event_date,
    count_if(event_type IS NULL) AS null_event_type,
    count_if(product_id IS NULL) AS null_product_id,
    count_if(category_id IS NULL) AS null_category_id,
    count_if(category_code IS NULL) AS null_category_code,
    count_if(brand IS NULL) AS null_brand,
    count_if(user_id IS NULL) AS null_user_id,
    count_if(user_session IS NULL) AS null_user_session
FROM silver.rees46_events;
