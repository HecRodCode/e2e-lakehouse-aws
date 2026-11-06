-- Debe devolver cero filas. Detecta diferencias y días ausentes en una capa.
WITH bronze_by_day AS (
    SELECT
        CAST(event_date AS varchar) AS event_day,
        COUNT(*) AS n_rows
    FROM bronze.rees46_events
    GROUP BY event_day
),

landing_by_day AS (
    SELECT
        event_date AS event_day,
        COUNT(*) AS n_rows
    FROM landing.rees46_events
    GROUP BY event_day
)

SELECT
    l.n_rows AS landing_rows,
    b.n_rows AS bronze_rows,
    COALESCE(l.event_day, b.event_day) AS event_date
FROM landing_by_day AS l
FULL JOIN bronze_by_day AS b
    ON l.event_day = b.event_day
WHERE l.n_rows IS DISTINCT FROM b.n_rows;
