-- Resumen de las dimensiones Gold.
WITH product_summary AS (
    SELECT
        count(*) AS products,
        count(DISTINCT product_id) AS unique_products
    FROM gold.dim_producto
),

calendar_summary AS (
    SELECT
        count(*) AS calendar_days,
        min(date_day) AS first_date,
        max(date_day) AS last_date
    FROM gold.dim_fecha
)

SELECT
    product_summary.products,
    product_summary.unique_products,
    calendar_summary.calendar_days,
    calendar_summary.first_date,
    calendar_summary.last_date
FROM product_summary
CROSS JOIN calendar_summary;

-- Debe devolver cero filas si falta un producto relacionado.
SELECT fact.product_id
FROM gold.fact_ventas AS fact
LEFT JOIN gold.dim_producto AS product
    ON fact.product_id = product.product_id
WHERE product.product_id IS NULL;

-- Debe devolver cero filas si falta una fecha relacionada.
SELECT fact.event_date
FROM gold.fact_ventas AS fact
LEFT JOIN gold.dim_fecha AS calendar
    ON fact.event_date = calendar.date_day
WHERE calendar.date_day IS NULL;
