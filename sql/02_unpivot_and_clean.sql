-- ============================================================================
-- 02_unpivot_and_clean.sql
-- Unpivot the wide day_1..day_31 columns into a proper date grain, build a
-- real DATE, and parse the packed time-band label into structured fields.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Step 1 — unpivot wide -> long using LATERAL + VALUES
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS stg_validations_long;
CREATE TABLE stg_validations_long AS
SELECT
    r."StationId"::integer            AS station_id,
    r."StationName"                   AS station_name,
    r."LowOrPeakDescFull"             AS time_band_desc,
    r.year_key::integer                AS year_key,
    r.month_key::integer               AS month_key,
    d.day_num,
    -- a blank cell means "zero validations", not "unknown" — see
    -- docs/methodology.md for why this assumption is safe for this dataset
    COALESCE(NULLIF(d.validations, '')::numeric, 0) AS validations,
    r.source_file
FROM raw_validations r
CROSS JOIN LATERAL (VALUES
    (1, r.day_1),  (2, r.day_2),  (3, r.day_3),  (4, r.day_4),
    (5, r.day_5),  (6, r.day_6),  (7, r.day_7),  (8, r.day_8),
    (9, r.day_9),  (10, r.day_10),(11, r.day_11),(12, r.day_12),
    (13, r.day_13),(14, r.day_14),(15, r.day_15),(16, r.day_16),
    (17, r.day_17),(18, r.day_18),(19, r.day_19),(20, r.day_20),
    (21, r.day_21),(22, r.day_22),(23, r.day_23),(24, r.day_24),
    (25, r.day_25),(26, r.day_26),(27, r.day_27),(28, r.day_28),
    (29, r.day_29),(30, r.day_30),(31, r.day_31)
) AS d(day_num, validations);

-- ---------------------------------------------------------------------------
-- Step 2 — construct a real DATE, dropping impossible day/month combos
-- (day_31 exists on every row even for a 28/29/30-day month)
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS stg_validations_dated;
CREATE TABLE stg_validations_dated AS
SELECT
    station_id, station_name, time_band_desc, year_key, month_key, day_num,
    make_date(year_key, month_key, day_num) AS validation_date,
    validations, source_file
FROM stg_validations_long
WHERE day_num <= EXTRACT(
    DAY FROM (make_date(year_key, month_key, 1) + INTERVAL '1 month - 1 day')
)::int;

-- ---------------------------------------------------------------------------
-- Step 3 — parse "06:00 - 08:59 - שיא בוקר" into band_start / band_end /
-- band_label_he / is_peak instead of treating it as an opaque string
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS dim_time_band;
CREATE TABLE dim_time_band AS
SELECT
    ROW_NUMBER() OVER (ORDER BY TRIM(split_part(time_band_desc, '-', 1))) AS time_band_key,
    time_band_desc,
    TRIM(split_part(time_band_desc, '-', 1))::time AS band_start,
    -- note: the source uses hours up to "27:59" for the post-midnight
    -- "night off-peak" band — that's not a valid Postgres TIME, so band_end
    -- is kept as text and the +N-day offset is documented, not silently cast
    TRIM(split_part(time_band_desc, '-', 2))        AS band_end_raw,
    TRIM(split_part(time_band_desc, '-', 3))         AS band_label_he,
    TRIM(split_part(time_band_desc, '-', 3)) ILIKE '%שיא%' AS is_peak
FROM (SELECT DISTINCT time_band_desc FROM stg_validations_dated) t;

-- ---------------------------------------------------------------------------
-- Step 4 — deduplicate (defensive: guards against a station/time-band/date
-- combination appearing in more than one republished source file)
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS stg_validations_dedup;
CREATE TABLE stg_validations_dedup AS
SELECT station_id, station_name, time_band_desc, validation_date, validations, source_file
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY station_id, time_band_desc, validation_date
            ORDER BY source_file DESC
        ) AS rn
    FROM stg_validations_dated
) t
WHERE rn = 1;
