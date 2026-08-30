-- ============================================================================
-- 05_aggregations_window_functions.sql
-- Pre-aggregated tables for the trend/ranking visuals — computed once here in
-- SQL rather than on every Power BI refresh. Also where the window-function
-- depth of this project lives: LAG (MoM/YoY growth), rolling AVG() OVER,
-- RANK(), NTILE(), and FILTER(WHERE ...) conditional aggregation.
-- ============================================================================

-- Monthly total per station, with month-over-month and year-over-year growth
DROP TABLE IF EXISTS agg_station_monthly;
CREATE TABLE agg_station_monthly AS
WITH monthly AS (
    SELECT
        station_id,
        date_trunc('month', date)::date AS month_start,
        SUM(validations) AS total_validations
    FROM fact_validations
    GROUP BY station_id, date_trunc('month', date)
)
SELECT
    station_id,
    month_start,
    total_validations,
    LAG(total_validations, 1)  OVER (PARTITION BY station_id ORDER BY month_start) AS prev_month_validations,
    LAG(total_validations, 12) OVER (PARTITION BY station_id ORDER BY month_start) AS prev_year_validations,
    ROUND(
        100.0 * (total_validations - LAG(total_validations, 1) OVER (PARTITION BY station_id ORDER BY month_start))
        / NULLIF(LAG(total_validations, 1) OVER (PARTITION BY station_id ORDER BY month_start), 0)
    , 1) AS mom_growth_pct,
    ROUND(
        100.0 * (total_validations - LAG(total_validations, 12) OVER (PARTITION BY station_id ORDER BY month_start))
        / NULLIF(LAG(total_validations, 12) OVER (PARTITION BY station_id ORDER BY month_start), 0)
    , 1) AS yoy_growth_pct,
    RANK()  OVER (PARTITION BY month_start ORDER BY total_validations DESC) AS rank_in_month,
    NTILE(4) OVER (PARTITION BY month_start ORDER BY total_validations DESC) AS volume_quartile
FROM monthly;

-- 7-day rolling average ridership per station (smooths daily/weekday noise)
DROP TABLE IF EXISTS agg_station_daily_rolling;
CREATE TABLE agg_station_daily_rolling AS
SELECT
    station_id,
    date,
    SUM(validations) AS daily_validations,
    AVG(SUM(validations)) OVER (
        PARTITION BY station_id
        ORDER BY date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7d_avg
FROM fact_validations
GROUP BY station_id, date;

-- Peak vs. off-peak split per station per month
DROP TABLE IF EXISTS agg_peak_split;
CREATE TABLE agg_peak_split AS
SELECT
    f.station_id,
    date_trunc('month', f.date)::date AS month_start,
    SUM(f.validations) FILTER (WHERE tb.is_peak)     AS peak_validations,
    SUM(f.validations) FILTER (WHERE NOT tb.is_peak) AS offpeak_validations,
    SUM(f.validations)                                AS total_validations,
    ROUND(100.0 * SUM(f.validations) FILTER (WHERE tb.is_peak) / NULLIF(SUM(f.validations), 0), 1) AS peak_share_pct
FROM fact_validations f
JOIN dim_time_band tb ON f.time_band_key = tb.time_band_key
GROUP BY f.station_id, date_trunc('month', f.date);

-- Sanity-check queries worth keeping in your notes / README:
-- SELECT s.city_name, a.station_id, a.month_start, a.total_validations, a.rank_in_month
-- FROM agg_station_monthly a JOIN dim_station s ON a.station_id = s.station_id
-- ORDER BY a.total_validations DESC LIMIT 10;
