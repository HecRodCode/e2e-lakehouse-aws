-- Inspección de filas rechazadas y del motivo de cuarentena.
SELECT
    reject_reason,
    event_type,
    user_id,
    user_session,
    event_time
FROM silver.rees46_events_quarantine
ORDER BY event_time;
