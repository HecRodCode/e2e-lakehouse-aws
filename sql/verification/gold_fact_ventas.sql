-- Conteo de la tabla Gold, comparado con los purchases válidos de Silver.
WITH silver_purchases AS (
    SELECT count(*) AS n_rows
    FROM silver.rees46_events
    WHERE event_type = 'purchase'
),

gold_purchases AS (
    SELECT count(*) AS n_rows
    FROM gold.fact_ventas
)

SELECT
    silver_purchases.n_rows AS silver_purchase_rows,
    gold_purchases.n_rows AS gold_fact_rows,
    silver_purchases.n_rows - gold_purchases.n_rows AS difference
FROM silver_purchases
CROSS JOIN gold_purchases;

-- Debe devolver cero filas: la clave técnica de la granularidad es event_hash.
SELECT
    event_hash,
    count(*) AS occurrences
FROM gold.fact_ventas
GROUP BY event_hash
HAVING count(*) > 1;

-- Debe devolver cero filas: todas las compras deben tener precio positivo,
-- válido y no imputado.
SELECT
    event_hash,
    price,
    price_is_valid,
    price_imputed
FROM gold.fact_ventas
WHERE
    price IS NULL
    OR price <= 0
    OR NOT price_is_valid
    OR price_imputed;
