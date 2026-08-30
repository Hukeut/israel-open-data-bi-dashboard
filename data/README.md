# Data sources

## EN

### Fact table — ticket validations by station

- **Dataset:** "תיקופי מסלקה לתחנה" (Ticket Clearing-House Validations by Station)
- **Publisher:** Ministry of Transport and Road Safety
- **Portal dataset page:** https://data.gov.il/he/datasets/ministry_of_transport/tikufim_station_2022
- **Contact:** bidata@mot.gov.il (listed on the dataset page)
- One CSV resource per year. Direct download links (confirmed working 30/08/2026):

| Year | Download |
|---|---|
| 2023 | https://aws-e.data.gov.il/dataset/1e9d4542-97af-47ac-a780-f2a6b291b1f5/resource/e265857e-9f53-419f-ad0b-860d2bf6fbb8/download/e265857e-9f53-419f-ad0b-860d2bf6fbb8.csv |
| 2024 | https://aws-e.data.gov.il/dataset/1e9d4542-97af-47ac-a780-f2a6b291b1f5/resource/51703b73-c27b-497e-8701-ea979a0c3835/download/51703b73-c27b-497e-8701-ea979a0c3835.csv |
| 2022 | https://aws-e.data.gov.il/dataset/1e9d4542-97af-47ac-a780-f2a6b291b1f5/resource/7382a5e4-f12c-4644-87c1-e6942da3ee92/download/7382a5e4-f12c-4644-87c1-e6942da3ee92.csv |

(2025/2026 partial-year files and 2020/2021 are also on the dataset page if you want a longer time series later.)

You can also query it directly via the CKAN datastore API without downloading the whole file, e.g. to check row counts or pull a filtered slice:
```
https://data.gov.il/api/3/action/datastore_search?resource_id=e265857e-9f53-419f-ad0b-860d2bf6fbb8&limit=5
```

### Dimension table — station geography

- **Dataset:** "תחנות תחבורה ציבורית" (Public Transport Stations)
- **Publisher:** Ministry of Transport and Road Safety
- **Portal dataset page:** https://data.gov.il/he/datasets/bus_stops
- **Resource ID:** `e873e6a2-66c1-494f-a677-f5e77348edb0`
- 34,166 stations nationwide (bus, light rail, and Israel Railways), with city, metropolitan area, station type, operator type, and WGS84 lat/long.

### Why only a sample is committed here

The full 2023 fact file alone is ~1.96M rows before unpivoting. GitHub isn't the right place for that — `data/sample/` ships a small **real** slice (8 Tel Aviv-Yafo stations, all 12 months of 2023, pulled directly from the API above) so the SQL pipeline in `/sql` can be run and verified without downloading anything. For the full dashboard, download the year(s) you want from the table above and point `sql/01_staging.sql`'s `\copy` commands at them instead of the sample files.

---

## HE

### טבלת העובדות — תיקופים לפי תחנה

- **מאגר:** "תיקופי מסלקה לתחנה"
- **מפרסם:** משרד התחבורה והבטיחות בדרכים
- **עמוד המאגר:** https://data.gov.il/he/datasets/ministry_of_transport/tikufim_station_2022
- **יצירת קשר:** bidata@mot.gov.il (מופיע בעמוד המאגר)
- קובץ CSV אחד לכל שנה. קישורי הורדה ישירים (אומתו כפועלים ב-30/08/2026) מופיעים בטבלה למעלה (חלק EN).

ניתן גם לשאול ישירות דרך ה-API של CKAN datastore בלי להוריד את כל הקובץ, למשל כדי לבדוק מספר שורות או למשוך פלח מסונן — ראו כתובת הדוגמה בחלק האנגלי למעלה.

### טבלת הממד — גיאוגרפיה של תחנות

- **מאגר:** "תחנות תחבורה ציבורית"
- **מפרסם:** משרד התחבורה והבטיחות בדרכים
- **עמוד המאגר:** https://data.gov.il/he/datasets/bus_stops
- **מזהה משאב:** `e873e6a2-66c1-494f-a677-f5e77348edb0`
- 34,166 תחנות ברחבי הארץ (אוטובוס, רק"ל ורכבת ישראל), כולל עיר, מטרופולין, סוג תחנה, סוג מפעיל, וקואורדינטות WGS84.

### למה רק מדגם נמצא כאן

קובץ העובדות המלא של 2023 לבדו מכיל כ-1.96 מיליון שורות עוד לפני פריסה מרוחב לאורך. GitHub אינו המקום המתאים לכך — התיקייה `data/sample/` מכילה פלח **אמיתי** קטן (8 תחנות בתל אביב-יפו, כל 12 חודשי 2023, שנמשך ישירות מה-API שלמעלה) כדי שניתן יהיה להריץ ולאמת את צנרת ה-SQL ב-`/sql` בלי להוריד דבר. לדשבורד המלא, יש להוריד את השנה/שנים הרצויות מהטבלה למעלה ולהפנות את פקודות ה-`\copy` בקובץ `sql/01_staging.sql` אליהן במקום לקובצי המדגם.
