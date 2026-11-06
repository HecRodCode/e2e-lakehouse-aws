-- Cantidad y distribución de tamaños de los archivos de Silver.
SELECT
    count(*) AS files,
    round(avg(file_size_in_bytes) / 1e6, 1) AS average_mb,
    round(min(file_size_in_bytes) / 1e6, 2) AS minimum_mb,
    round(max(file_size_in_bytes) / 1e6, 1) AS maximum_mb
FROM silver."rees46_events$files"; -- noqa: RF05
