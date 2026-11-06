-- Reconciliación diaria y total. FULL JOIN detecta días ausentes en una capa.
-- La fila de total debe mostrar una diferencia de 30.222 para la carga
-- actual: 30.220 duplicados exactos y 2 filas en cuarentena.
WITH bronze_by_day AS (
    SELECT
        event_date,
        count(*) AS n_rows
    FROM bronze.rees46_events
    GROUP BY event_date
),

silver_by_day AS (
    SELECT
        event_date,
        count(*) AS n_rows
    FROM silver.rees46_events
    GROUP BY event_date
),

daily_reconciliation AS (
    SELECT
        coalesce(b.event_date, s.event_date) AS event_date,
        coalesce(b.n_rows, 0) AS bronze_rows,
        coalesce(s.n_rows, 0) AS silver_rows
    FROM bronze_by_day AS b
    FULL JOIN silver_by_day AS s
        ON b.event_date = s.event_date
)

SELECT
    event_date,
    sum(bronze_rows) AS bronze_rows,
    sum(silver_rows) AS silver_rows,
    sum(bronze_rows - silver_rows) AS rows_removed
FROM daily_reconciliation
GROUP BY rollup (event_date)
ORDER BY event_date;
