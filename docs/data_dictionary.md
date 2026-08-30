# Data dictionary

## EN

### Raw source — `raw_validations` (from the fact CSV, as published)

| Field | Type | Notes |
|---|---|---|
| `StationId` | text → int | Joins to `raw_stations.StationId` |
| `StationName` | text | Hebrew, inconsistent spacing |
| `LowOrPeakDescFull` | text | e.g. `"06:00 - 08:59 - שיא בוקר"` — unparsed time range + Hebrew peak label |
| `year_key` | text → int | |
| `month_key` | text → int | |
| `day_1` … `day_31` | text → numeric | Blank when no data; see `docs/methodology.md` for why blank = 0 here |

### Raw source — `raw_stations` (from the dimension CSV, as published)

| Field | Type | Notes |
|---|---|---|
| `StationId` | int | |
| `CityCode` / `CityName` | int / text | |
| `MetropolinCode` / `MetropolinName` | int / text | e.g. `1` / `"תל אביב"` |
| `StationTypeCode` / `StationTypeName` | int / text | e.g. regular stop, terminal, rail station boundary |
| `StationOperatorTypeCode` / `StationOperatorTypeName` | int / text | e.g. bus operator, rail |
| `Lat` / `Long` | numeric | WGS84 |

### Model — star schema tables (output of `/sql`, shipped pre-built in `/model`)

**`fact_validations`** — grain: one row per `station_id` × `date` × `time_band_key`

| Field | Type | Description |
|---|---|---|
| `station_id` | int | FK → `dim_station.station_id` |
| `date` | date | FK → `dim_date.date` |
| `time_band_key` | int | FK → `dim_time_band.time_band_key` |
| `validations` | numeric | Ticket validations (ridership proxy) in that station/date/time-band |

**`dim_station`**

| Field | Description |
|---|---|
| `station_id` | Primary key |
| `city_name` | Municipality |
| `metro_name` | Metropolitan area (e.g. "תל אביב") |
| `station_type` | e.g. "תחנה רגילה" (regular stop), "רכבת ישראל" (rail) |
| `operator_type` | e.g. "מפעילי אוטובוסים" (bus operators), "רכבת" (rail) |
| `latitude` / `longitude` | WGS84 |

**`dim_date`** — one row per calendar day in the observed range

| Field | Description |
|---|---|
| `date` | Primary key |
| `year`, `month`, `month_name`, `quarter` | |
| `day_of_week` | 0 = Sunday (Postgres `EXTRACT(DOW ...)` convention) |
| `day_name` | |
| `is_weekend` | `true` for Friday/Saturday (Israel's weekend, not Sat/Sun) |

**`dim_time_band`**

| Field | Description |
|---|---|
| `time_band_key` | Primary key |
| `time_band_desc` | Original raw label, kept for traceability |
| `band_start` | Parsed start time |
| `band_end_raw` | Parsed end time as text — some bands run past midnight (e.g. `27:59`), which isn't a valid SQL `TIME`, so this is kept as text rather than silently wrapping it |
| `band_label_he` | Hebrew label, e.g. "שיא בוקר" (morning peak) |
| `is_peak` | Boolean, derived from whether the label contains "שיא" |

**`agg_station_monthly`, `agg_station_daily_rolling`, `agg_peak_split`** — pre-aggregated tables backing the trend/ranking visuals; see `sql/05_aggregations_window_functions.sql` for exact definitions.

---

## HE

### מקור גולמי — `raw_validations` (מקובץ העובדות, כפי שפורסם)

| שדה | סוג | הערות |
|---|---|---|
| `StationId` | טקסט → מספר שלם | מתחבר ל-`raw_stations.StationId` |
| `StationName` | טקסט | עברית, רווחים לא עקביים |
| `LowOrPeakDescFull` | טקסט | לדוגמה `"06:00 - 08:59 - שיא בוקר"` — טווח שעות ותיוג שיא לא מפוענחים במחרוזת אחת |
| `year_key` | טקסט → מספר שלם | |
| `month_key` | טקסט → מספר שלם | |
| `day_1` עד `day_31` | טקסט → מספר | ריק כשאין נתונים; ראו `docs/methodology.md` להסבר מדוע ריק = אפס במאגר זה |

### מקור גולמי — `raw_stations` (מקובץ הממד, כפי שפורסם)

| שדה | סוג | הערות |
|---|---|---|
| `StationId` | מספר שלם | |
| `CityCode` / `CityName` | מספר שלם / טקסט | |
| `MetropolinCode` / `MetropolinName` | מספר שלם / טקסט | לדוגמה `1` / `"תל אביב"` |
| `StationTypeCode` / `StationTypeName` | מספר שלם / טקסט | לדוגמה תחנה רגילה, מסוף, גבול תחנת רכבת |
| `StationOperatorTypeCode` / `StationOperatorTypeName` | מספר שלם / טקסט | לדוגמה מפעילי אוטובוסים, רכבת |
| `Lat` / `Long` | מספר | WGS84 |

### המודל — טבלאות סכימת הכוכב (פלט של `/sql`, מסופק מוכן מראש ב-`/model`)

**`fact_validations`** — רמת פירוט: שורה אחת לכל `station_id` × `date` × `time_band_key`

| שדה | סוג | תיאור |
|---|---|---|
| `station_id` | מספר שלם | מפתח זר → `dim_station.station_id` |
| `date` | תאריך | מפתח זר → `dim_date.date` |
| `time_band_key` | מספר שלם | מפתח זר → `dim_time_band.time_band_key` |
| `validations` | מספר | כמות תיקופים (קירוב לנוסעים) בתחנה/תאריך/רצועת שעות זו |

**`dim_station`** — `station_id` (מפתח ראשי), `city_name` (רשות מקומית), `metro_name` (מטרופולין), `station_type`, `operator_type`, `latitude`/`longitude`.

**`dim_date`** — שורה אחת לכל יום קלנדרי בטווח שנצפה: `date` (מפתח ראשי), `year`/`month`/`month_name`/`quarter`, `day_of_week` (0 = יום ראשון), `day_name`, `is_weekend` (אמת ביום שישי/שבת — סוף השבוע הישראלי).

**`dim_time_band`** — `time_band_key` (מפתח ראשי), `time_band_desc` (התווית המקורית, לצורך מעקב), `band_start`, `band_end_raw` (כטקסט — חלק מהרצועות חוצות חצות, למשל "27:59", שאינו ערך `TIME` תקין), `band_label_he`, `is_peak` (בוליאני, נגזר מהופעת "שיא" בתווית).

**`agg_station_monthly`, `agg_station_daily_rolling`, `agg_peak_split`** — טבלאות מצטברות מוכנות מראש עבור תרשימי המגמה והדירוג; ההגדרות המדויקות ב-`sql/05_aggregations_window_functions.sql`.
