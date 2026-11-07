-- Pregunta: ¿Qué productos aparecen en más eventos purchase y cuántos
-- usuarios y sesiones distintas están asociados a esos eventos?
-- purchase_events no es cantidad de unidades ni de órdenes.
-- Los precios son valores observados del producto en esos eventos; no sumarlos
-- como ingresos.
SELECT
    product.product_id,
    product.category_code,
    product.brand,
    count(*) AS purchase_events,
    count(DISTINCT fact.user_id) AS users_with_purchase,
    count(DISTINCT row(fact.user_id, fact.user_session))
        AS user_session_pairs_with_purchase,
    min(fact.price) AS min_observed_product_price,
    approx_percentile(fact.price, 0.5) AS median_observed_product_price,
    max(fact.price) AS max_observed_product_price
FROM gold.fact_ventas AS fact
INNER JOIN gold.dim_producto AS product
    ON fact.product_id = product.product_id
GROUP BY
    product.product_id,
    product.category_code,
    product.brand
ORDER BY purchase_events DESC, product.product_id ASC
LIMIT 100;
