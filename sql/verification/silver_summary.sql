-- Conteo, unicidad de hashes y rango temporal de Silver.
SELECT
    count(*) AS total_rows,
    count(DISTINCT event_hash) AS distinct_hashes,
    min(event_time) AS first_event,
    max(event_time) AS last_event
FROM silver.rees46_events;

-- Para la carga actual se esperan 42.418.542 filas y 31 días.
SELECT
    count(*) AS total_rows,
    count(DISTINCT event_hash) AS distinct_hashes,
    count(DISTINCT event_date) AS distinct_event_dates
FROM silver.rees46_events;
