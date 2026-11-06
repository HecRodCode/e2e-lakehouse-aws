-- Cantidad de archivos y tamaño promedio de los archivos de Bronze.
SELECT
    count(*) AS files,
    round(avg(file_size_in_bytes) / 1e6, 1) AS average_mb
FROM bronze."rees46_events$files"; -- noqa: RF05
