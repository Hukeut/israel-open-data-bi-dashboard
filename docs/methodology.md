# Methodology & assumptions log

Every non-obvious decision made while cleaning this dataset, documented on purpose — this log is itself part of the portfolio value: it shows the reasoning, not just the output.

## EN

**1. Blank `day_N` cells are treated as 0, not missing.**
The portal's own description states the data is scoped to "stations listed in the operator's line license" — i.e. a row only exists for station/time-band/month combinations that were licensed to run at all. Within a licensed row, a blank day almost certainly means zero validations that day, not "not collected." Treating it as `NULL`/dropped would silently understate ridership and break daily aggregates. This is documented, not hidden, in `sql/02_unpivot_and_clean.sql`.

**2. `day_31` (and `day_29`/`day_30` in short months) is discarded when the month doesn't have that many days**, computed from the actual calendar rather than hardcoded — see the `EXTRACT(DAY FROM ...)` filter in `02_unpivot_and_clean.sql`.

**3. The time-band label is parsed, not treated as an opaque category.**
`"06:00 - 08:59 - שיא בוקר"` is split into a start time, an end time (kept as text — see #4), a Hebrew label, and a derived `is_peak` boolean, so DAX/SQL can filter and aggregate on peak vs. off-peak without string-matching every time.

**4. One time band runs past midnight and isn't a valid SQL `TIME`.**
`"24:00 - 27:59 - שפל לילה"` (night off-peak) is expressed in "extended" hour notation past 24:00, common in transit scheduling to keep a service-day's late trips grouped with that day rather than rolling into the next calendar day. `band_end_raw` is kept as text rather than force-cast, to avoid silently corrupting it — if you need it as a true offset later, treat it as `date + (hour - 24) hours` for hours ≥ 24.

**5. Deduplication is defensive, not reactive.**
Government open-data republishes occasionally overlap (a month's data revised and reposted). `ROW_NUMBER() ... PARTITION BY station_id, time_band_desc, validation_date` guards against silently double-counting if you load more than one file covering an overlapping period — verified this didn't actually trigger on the sample data (556 raw rows → 556 deduped rows).

**6. Fact rows with no match in the station dimension are surfaced, not silently dropped.**
The two source files are published independently and can drift (a station renamed or added between publish dates). `03_dimensions_and_date_spine.sql` includes the exact query to run and report this percentage — treat it as a real data-quality number to state, not something to engineer around invisibly.

**7. Israel's weekend is Friday/Saturday, not Saturday/Sunday** — `is_weekend` in `dim_date` is set accordingly; a naive Power BI weekend flag defaults to Sat/Sun and would misclassify every week here.

**8. Why a sample scoped to Tel Aviv–Yafo, full year 2023.**
The full national files run into the millions of rows before unpivoting even for a single year. Scoping the working sample to one city and one closed calendar year keeps the project genuinely runnable end-to-end (pipeline verified: 556 raw rows → 16,918 fact rows after unpivot/clean/join) while still being real, messy, unmodified government data — not a synthetic reduction.

## Pipeline verification (ran against the sample shipped in this repo)

```
raw_validations rows:              556
stg_validations_long (unpivoted):  17,236
stg_validations_dated (valid dates only): 16,918
dim_time_band rows:                 7
stg_validations_dedup rows:        16,918   (no duplicates found in this sample)
Fact stations unmatched to dim_station: 0
dim_date rows:                      365
fact_validations rows:             16,918
agg_station_monthly rows:           84
```

---

## HE

**1. תא ריק ב-`day_N` נחשב כאפס, לא כערך חסר.**
התיאור באתר עצמו קובע שהנתונים מוגבלים ל"תחנות המפורטות ברישיון הקו של המפעיל" — כלומר שורה קיימת רק עבור צירופי תחנה/רצועת-שעות/חודש שהיו מורשים לפעול בכלל. בתוך שורה מורשית, יום ריק כמעט בוודאות אומר אפס תיקופים באותו יום, לא "לא נאסף". התייחסות אליו כ-`NULL`/השמטתו הייתה ממעיטה בשקט בנפח הנוסעים ושוברת צבירות יומיות. ההחלטה מתועדת, לא מוסתרת, ב-`sql/02_unpivot_and_clean.sql`.

**2. `day_31` (וכן `day_29`/`day_30` בחודשים קצרים) מושמט כאשר לחודש אין כה הרבה ימים**, מחושב מהלוח האמיתי ולא מקודד באופן קשיח — ראו את הסינון עם `EXTRACT(DAY FROM ...)` ב-`02_unpivot_and_clean.sql`.

**3. תווית רצועת השעות מפוענחת, לא נשמרת כקטגוריה אטומה.**
`"06:00 - 08:59 - שיא בוקר"` מפוצלת לשעת התחלה, שעת סיום (נשמרת כטקסט — ראו #4), תווית בעברית, ודגל `is_peak` נגזר, כך ש-DAX/SQL יכולים לסנן ולצבור לפי שיא מול שפל בלי התאמת מחרוזות בכל פעם.

**4. רצועת שעות אחת חוצה חצות ואינה ערך `TIME` תקין ב-SQL.**
`"24:00 - 27:59 - שפל לילה"` מבוטאת בסימון שעות "מורחב" מעבר ל-24:00, נהוג בתכנון תחבורה ציבורית כדי לקבץ נסיעות מאוחרות של יום שירות עם אותו יום ולא לגלוש ליום הקלנדרי הבא. `band_end_raw` נשמר כטקסט ולא מומר בכפייה, כדי לא להשחית אותו בשקט.

**5. הסרת כפילויות היא הגנתית, לא תגובתית.**
פרסומים חוזרים של נתוני ממשלה פתוחים לפעמים חופפים (נתוני חודש מתוקנים ומפורסמים מחדש). `ROW_NUMBER() ... PARTITION BY station_id, time_band_desc, validation_date` מגן מפני ספירה כפולה בשקט אם נטען יותר מקובץ אחד המכסה תקופה חופפת — אומת שבמדגם זה זה לא קרה בפועל (556 שורות גולמיות → 556 שורות אחרי הסרת כפילויות).

**6. שורות עובדה ללא התאמה בממד התחנות מוצגות, לא מושמטות בשקט.**
שני קבצי המקור מפורסמים בנפרד ועלולים לסטות (תחנה ששונה שמה או נוספה בין תאריכי הפרסום). `03_dimensions_and_date_spine.sql` כולל את השאילתה המדויקת להרצה ולדיווח על האחוז הזה — יש להתייחס אליו כמספר איכות-נתונים אמיתי שיש לציין, לא משהו להנדס סביבו בשקט.

**7. סוף השבוע בישראל הוא שישי/שבת, לא שבת/ראשון** — `is_weekend` ב-`dim_date` מוגדר בהתאם; דגל סוף שבוע נאיבי ב-Power BI ברירת המחדל שלו שבת/ראשון והיה מסווג לא נכון כל שבוע כאן.

**8. מדוע מדגם המוגבל לתל אביב-יפו, שנת 2023 מלאה.**
הקבצים הארציים המלאים מגיעים למיליוני שורות עוד לפני פריסה מרוחב לאורך אפילו עבור שנה בודדת. הגבלת המדגם העובד לעיר אחת ולשנה קלנדרית סגורה אחת שומרת על פרויקט שניתן להרצה מקצה לקצה בפועל (הצנרת אומתה: 556 שורות גולמיות → 16,918 שורות עובדה אחרי פריסה/ניקוי/חיבור) תוך שהוא נשאר נתוני ממשלה אמיתיים, מבולגנים ובלתי משתנים — לא צמצום סינתטי.
