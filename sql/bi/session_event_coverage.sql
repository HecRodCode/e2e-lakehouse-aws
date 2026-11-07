-- Pregunta: ¿En cuántas sesiones aparecen vistas, carritos y compras?
-- La presencia conjunta de etapas no prueba su orden temporal ni constituye
-- por sí sola una tasa de conversión causal.
-- La clave se compone de usuario y sesión: 348 IDs de sesión aparecen
-- asociados a más de un usuario en el dataset.
-- Varias filas purchase pueden corresponder a una sola orden en una sesión.
WITH user_session_events AS (
    SELECT
        user_id,
        user_session,
        max(if(event_type = 'view', 1, 0)) AS has_view,
        max(if(event_type = 'cart', 1, 0)) AS has_cart,
        max(if(event_type = 'purchase', 1, 0)) AS has_purchase
    FROM silver.rees46_events
    WHERE user_session IS NOT NULL
    GROUP BY user_id, user_session
)

SELECT
    count(*) AS user_session_pairs,
    count_if(has_view = 1) AS pairs_with_view,
    count_if(has_cart = 1) AS pairs_with_cart,
    count_if(has_purchase = 1) AS pairs_with_purchase,
    count_if(has_view = 1 AND has_cart = 1)
        AS pairs_with_view_and_cart,
    count_if(has_view = 1 AND has_purchase = 1)
        AS pairs_with_view_and_purchase,
    count_if(
        has_view = 1 AND has_cart = 1 AND has_purchase = 1
    )
        AS pairs_with_all_three_events,
    round(
        100.0
        * count_if(has_view = 1 AND has_purchase = 1)
        / nullif(count_if(has_view = 1), 0),
        2
    ) AS pct_view_pairs_also_with_purchase
FROM user_session_events;
