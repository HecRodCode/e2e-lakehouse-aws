-- Análisis descriptivo: ¿qué precios de producto aparecen en los eventos
-- purchase de Gold y hay valores imputados o inválidos?
-- REES46 define price como el precio del producto en el evento. No hay
-- cantidad ni un ID de orden; no sumar este campo como ingresos.
SELECT
    count(*) AS purchase_events,
    count(DISTINCT product_id) AS distinct_products,
    count_if(price_is_valid AND NOT price_imputed)
        AS events_with_observed_valid_price,
    count_if(price_imputed) AS events_with_imputed_price,
    min(price) AS min_observed_product_price,
    avg(price) AS avg_observed_product_price_per_event,
    approx_percentile(price, 0.5) AS median_observed_product_price_per_event,
    approx_percentile(price, 0.9) AS p90_observed_product_price_per_event,
    max(price) AS max_observed_product_price
FROM gold.fact_ventas
WHERE
    price_is_valid
    AND NOT price_imputed;
