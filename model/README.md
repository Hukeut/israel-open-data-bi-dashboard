# Model output

These CSVs are the direct output of running `/sql` (01→05) against the sample data in `data/sample/` — 8 Tel Aviv–Yafo stations, full calendar year 2023. They're ready to import straight into Power BI (see `/powerbi/README.md`) with no further transformation needed.

Pipeline verified end-to-end: 556 raw rows → 16,918 fact rows after unpivot/date-construction/dedup/join. See `docs/methodology.md` for the reasoning behind every cleaning decision, and the full row-count trace.

| File | Role |
|---|---|
| `dim_date.csv` | Date dimension (365 rows, one per day of 2023) |
| `dim_station.csv` | Station dimension (8 rows — the sample stations) |
| `dim_time_band.csv` | Time-band dimension (7 rows) |
| `fact_validations.csv` | Fact table, grain = station × date × time-band (16,918 rows) |
| `agg_station_monthly.csv` | Pre-aggregated monthly totals + MoM/YoY growth + rank |
| `agg_station_daily_rolling.csv` | Daily totals + 7-day rolling average |
| `agg_peak_split.csv` | Peak vs. off-peak split per station per month |

To regenerate against the full national data instead of the sample: download the full yearly file(s) per `data/README.md`, update `sql/01_staging.sql`'s `\copy` source paths, and re-run `sql/01` through `sql/05` in order.
