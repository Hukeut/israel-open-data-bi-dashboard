# Power BI build guide

## EN — step by step (written for a first-time Power BI user)

The `/model` folder already contains clean, star-schema-ready CSVs produced by running `/sql` on the sample data — you can start directly from these without installing or running any database.

### 1. Install and load data
1. Install **Power BI Desktop** (free, Microsoft Store or powerbi.microsoft.com/desktop — Windows only; use a VM if you're on Mac).
2. **Home → Get Data → Text/CSV**, and import each file in `/model`: `dim_date.csv`, `dim_station.csv`, `dim_time_band.csv`, `fact_validations.csv`, `agg_station_monthly.csv`, `agg_station_daily_rolling.csv`, `agg_peak_split.csv`.
3. For each, click **Transform Data** (not Load directly) to open Power Query and check column types before loading — `date`/`month_start` columns should be typed `Date`, `validations`/`*_pct` numeric.
4. **Close & Apply**.

### 2. Build the model (relationships)
1. Switch to **Model view**.
2. Drag `fact_validations[date]` onto `dim_date[date]` → confirm one-to-many, single direction (from `dim_date` to `fact_validations`).
3. Same for `fact_validations[station_id] → dim_station[station_id]` and `fact_validations[time_band_key] → dim_time_band[time_band_key]`.
4. Click `dim_date` → **Table tools → Mark as date table** → select `date`. Required for time-intelligence DAX.

### 3. DAX measures
Create a measures table (right-click Fields pane → New table → `Measures = {}`), then add:

```dax
Total Validations = SUM(fact_validations[validations])

YoY % Change =
VAR CurrentTotal = [Total Validations]
VAR PriorYear = CALCULATE([Total Validations], SAMEPERIODLASTYEAR(dim_date[date]))
RETURN DIVIDE(CurrentTotal - PriorYear, PriorYear)

30-Day Rolling Avg =
AVERAGEX(
    DATESINPERIOD(dim_date[date], MAX(dim_date[date]), -30, DAY),
    [Total Validations]
)

Peak Share % =
DIVIDE(
    CALCULATE([Total Validations], dim_time_band[is_peak] = TRUE),
    [Total Validations]
)

Station Rank = RANKX(ALL(dim_station[city_name]), [Total Validations])
```

### 4. Report pages
- **Overview:** KPI cards (Total Validations, YoY % Change, Peak Share %) + monthly trend line with rolling average overlay.
- **Stations:** ranked bar chart of top stations by `[Total Validations]`; map visual using `dim_station[latitude]`/`[longitude]`, bubble size = `[Total Validations]`.
- **Time patterns:** peak/off-peak donut (`dim_time_band[is_peak]`); day-of-week column chart (`dim_date[day_name]`).
- Add slicers: date range, `metro_name`/`city_name`, `is_peak`.

### 5. Ship it
1. Save as `israel-open-data-bi-dashboard.pbix` in this folder.
2. Take screenshots (or a short GIF) of each page and add them here — GitHub can't render a live `.pbix`.
3. Optional but recommended: publish to Power BI Service (free tier) and link it here for an interactive version anyone can open in a browser.

### Next step to scale this up
Once the above works on the sample, download the full yearly file(s) per `data/README.md`, re-run `/sql` against them (or point Power Query directly at a Postgres database if you loaded the pipeline there), and swap the `/model` CSVs for the full versions — the model and DAX measures don't need to change.

---

## HE — שלבים (עבור מי שמשתמש ב-Power BI לראשונה)

התיקייה `/model` כבר מכילה קובצי CSV נקיים ומוכנים לסכימת כוכב, שהופקו מהרצת `/sql` על נתוני המדגם — ניתן להתחיל ישירות מהם בלי להתקין או להריץ מסד נתונים כלשהו.

### 1. התקנה וטעינת נתונים
1. התקינו **Power BI Desktop** (חינמי, Microsoft Store או powerbi.microsoft.com/desktop — Windows בלבד; השתמשו במכונה וירטואלית אם אתם על Mac).
2. **Home → Get Data → Text/CSV**, וייבאו כל קובץ מתוך `/model`: `dim_date.csv`, `dim_station.csv`, `dim_time_band.csv`, `fact_validations.csv`, `agg_station_monthly.csv`, `agg_station_daily_rolling.csv`, `agg_peak_split.csv`.
3. עבור כל קובץ, לחצו **Transform Data** (לא טעינה ישירה) כדי לפתוח את Power Query ולבדוק את סוגי העמודות לפני הטעינה — עמודות `date`/`month_start` צריכות להיות מסוג `Date`, ו-`validations`/`*_pct` מספריות.
4. **Close & Apply**.

### 2. בניית המודל (קשרים)
1. עברו ל-**Model view**.
2. גררו את `fact_validations[date]` אל `dim_date[date]` ← ודאו יחס one-to-many, כיוון יחיד (מ-`dim_date` אל `fact_validations`).
3. כנ"ל עבור `fact_validations[station_id] → dim_station[station_id]` ו-`fact_validations[time_band_key] → dim_time_band[time_band_key]`.
4. לחצו על `dim_date` ← **Table tools → Mark as date table** ← בחרו `date`. נדרש עבור פונקציות DAX מבוססות זמן.

### 3. מדדי DAX
צרו טבלת מדדים (קליק ימני על חלונית Fields ← New table ← `Measures = {}`), ואז הוסיפו את המדדים המופיעים בחלק האנגלי למעלה (הקוד זהה, DAX אינו תלוי-שפה).

### 4. עמודי הדוח
- **סקירה כללית:** כרטיסי KPI (סה"כ תיקופים, שינוי שנתי %, נתח שיא %) + קו מגמה חודשי עם ממוצע נע.
- **תחנות:** תרשים עמודות מדורג של התחנות המובילות; מפה עם `dim_station[latitude]`/`[longitude]`, גודל בועה = סה"כ תיקופים.
- **דפוסי זמן:** דונאט שיא/שפל; תרשים עמודות לפי יום בשבוע.
- הוסיפו מסננים (slicers): טווח תאריכים, `metro_name`/`city_name`, `is_peak`.

### 5. פרסום
1. שמרו כ-`israel-open-data-bi-dashboard.pbix` בתיקייה זו.
2. צלמו מסך (או הקליטו GIF קצר) של כל עמוד והוסיפו כאן — GitHub לא יכול להציג `.pbix` חי.
3. מומלץ: פרסמו ל-Power BI Service (שכבה חינמית) וקשרו כאן לגרסה אינטראקטיבית שכל אחד יכול לפתוח בדפדפן.

### הצעד הבא להרחבה
לאחר שהאמור לעיל עובד על המדגם, הורידו את הקבצים השנתיים המלאים לפי `data/README.md`, הריצו מחדש את `/sql` עליהם (או כוונו את Power Query ישירות למסד Postgres אם טענתם את הצנרת שם), והחליפו את קובצי ה-CSV ב-`/model` בגרסאות המלאות — המודל ומדדי ה-DAX לא צריכים להשתנות.
