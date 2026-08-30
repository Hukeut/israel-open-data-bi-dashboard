-- ============================================================================
-- 04_fact_table.sql
-- FACT_VALIDATIONS — grain: one row per station x date x time-band.
-- This is the table Power BI's FACT side of the star schema loads from.
-- ============================================================================

DROP TABLE IF EXISTS fact_validations;
CREATE TABLE fact_validations AS
SELECT
    f.station_id,
    f.validation_date AS date,
    tb.time_band_key,
    f.validations
FROM stg_validations_dedup f
JOIN dim_time_band tb ON f.time_band_desc = tb.time_band_desc;

-- Recommended indexes if you're loading this into a real Postgres instance
-- Power BI will query repeatedly (skip if you're exporting straight to CSV):
CREATE INDEX IF NOT EXISTS idx_fact_validations_station ON fact_validations(station_id);
CREATE INDEX IF NOT EXISTS idx_fact_validations_date    ON fact_validations(date);
