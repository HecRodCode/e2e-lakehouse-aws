-- Pregunta: ¿En qué días hubo más eventos purchase y cuántos usuarios,
-- sesiones y productos distintos aparecen en ellos?
-- purchase_events cuenta eventos, no órdenes: una sesión puede tener varios
-- eventos purchase que pertenecen a una misma orden.
SELECT
    calendar.date_day,
    calendar.day_name,
    count(fact.event_hash) AS purchase_events,
    count(DISTINCT fact.user_id) AS users_with_purchase,
    count(DISTINCT row(fact.user_id, fact.user_session))
        AS user_session_pairs_with_purchase,
    count(DISTINCT fact.product_id) AS distinct_products
FROM gold.dim_fecha AS calendar
LEFT JOIN gold.fact_ventas AS fact
    ON calendar.date_day = fact.event_date
GROUP BY
    calendar.date_day,
    calendar.day_name
ORDER BY calendar.date_day;
