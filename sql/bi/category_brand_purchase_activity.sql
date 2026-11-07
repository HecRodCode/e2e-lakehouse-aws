-- Pregunta: ¿Qué categorías y marcas concentran más eventos purchase?
-- Los atributos de dim_producto son los valores más recientes observados en
-- Silver (SCD tipo 1), no una foto histórica de cada evento.
-- Los precios son del producto en los eventos; no representan ingresos.
SELECT
    product.category_code,
    product.brand,
    count(*) AS purchase_events,
    count(DISTINCT product.product_id) AS distinct_products,
    count(DISTINCT fact.user_id) AS users_with_purchase,
    count(DISTINCT row(fact.user_id, fact.user_session))
        AS user_session_pairs_with_purchase,
    approx_percentile(fact.price, 0.5) AS median_observed_product_price
FROM gold.fact_ventas AS fact
INNER JOIN gold.dim_producto AS product
    ON fact.product_id = product.product_id
GROUP BY
    product.category_code,
    product.brand
ORDER BY
    purchase_events DESC,
    product.category_code ASC,
    product.brand ASC
LIMIT 100;
