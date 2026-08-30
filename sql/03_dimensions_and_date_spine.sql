-- ============================================================================
-- 03_dimensions_and_date_spine.sql
-- Build DIM_STATION (cleaned geography lookup) and DIM_DATE (a full date
-- spine — required for Power BI's time-intelligence DAX functions to work).
-- ============================================================================

DROP TABLE IF EXISTS dim_station;
CREATE TABLE dim_station AS
SELECT
    "StationId"                                                    AS station_id,
    COALESCE(NULLIF(TRIM("CityName"), ''), 'Unclassified')         AS city_name,
    COALESCE(NULLIF(TRIM("MetropolinName"), ''), 'Unclassified')   AS metro_name,
    COALESCE(NULLIF(TRIM("StationTypeName"), ''), 'Unknown')       AS station_type,
    COALESCE(NULLIF(TRIM("StationOperatorTypeName"), ''), 'Unknown') AS operator_type,
    "Lat"  AS latitude,
    "Long" AS longitude
FROM raw_stations
WHERE "StationId" IS NOT NULL;

-- Sanity check to run and document, not skip: how many fact stations have no
-- match in the geography file? Some stations rename/decommission between the
-- two source files' publish dates. Document the % excluded — don't silently
-- drop rows without knowing the scale.
-- SELECT COUNT(DISTINCT f.station_id)
-- FROM stg_validations_dedup f
-- LEFT JOIN dim_station d ON f.station_id = d.station_id
-- WHERE d.station_id IS NULL;

DROP TABLE IF EXISTS dim_date;
CREATE TABLE dim_date AS
SELECT
    d::date AS date,
    EXTRACT(YEAR FROM d)::int    AS year,
    EXTRACT(MONTH FROM d)::int   AS month,
    TO_CHAR(d, 'FMMonth')        AS month_name,
    EXTRACT(DOW FROM d)::int     AS day_of_week,      -- 0 = Sunday
    TO_CHAR(d, 'FMDay')          AS day_name,
    EXTRACT(DOW FROM d) IN (5, 6) AS is_weekend,        -- Israel weekend = Fri/Sat
    EXTRACT(QUARTER FROM d)::int  AS quarter
FROM generate_series(
    (SELECT MIN(validation_date) FROM stg_validations_dedup),
    (SELECT MAX(validation_date) FROM stg_validations_dedup),
    INTERVAL '1 day'
) AS d;
