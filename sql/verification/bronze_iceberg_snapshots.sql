-- Historial de commits/snapshots de la tabla Iceberg Bronze.
SELECT
    committed_at,
    operation,
    summary
FROM bronze."rees46_events$snapshots" -- noqa: RF05
ORDER BY committed_at;
