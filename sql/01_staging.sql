-- ============================================================================
-- 01_staging.sql
-- Israel Open Data BI Dashboard — raw / staging layer
-- Loads the source files exactly as published, untouched. Never mutate these
-- tables directly — every downstream table is re-derivable from raw_*.
-- ============================================================================

-- Fact source: "תיקופי מסלקה לתחנה" (Ticket Clearing-House Validations by
-- Station), Ministry of Transport and Road Safety, data.gov.il
-- dataset: ministry_of_transport/tikufim_station_2022
CREATE TABLE IF NOT EXISTS raw_validations (
    "StationId"         text,
    "StationName"       text,
    "LowOrPeakDescFull" text,
    year_key            text,
    month_key           text,
    day_1  text, day_2  text, day_3  text, day_4  text, day_5  text,
    day_6  text, day_7  text, day_8  text, day_9  text, day_10 text,
    day_11 text, day_12 text, day_13 text, day_14 text, day_15 text,
    day_16 text, day_17 text, day_18 text, day_19 text, day_20 text,
    day_21 text, day_22 text, day_23 text, day_24 text, day_25 text,
    day_26 text, day_27 text, day_28 text, day_29 text, day_30 text,
    day_31 text,
    source_file text
);

-- Dimension source: "תחנות תחבורה ציבורית" (Public Transport Stations),
-- Ministry of Transport, data.gov.il dataset: bus_stops
CREATE TABLE IF NOT EXISTS raw_stations (
    "StationId"               integer,
    "CityCode"                integer,
    "CityName"                text,
    "MetropolinCode"          integer,
    "MetropolinName"          text,
    "StationTypeCode"         integer,
    "StationTypeName"         text,
    "StationOperatorTypeCode" integer,
    "StationOperatorTypeName" text,
    "Lat"                     numeric,
    "Long"                    numeric
);

-- Load. Every field is loaded as TEXT in raw_validations on purpose — the
-- source file mixes numbers and blanks in the day_N columns, and casting
-- belongs in the cleaning step (02), not the load step, so a load never
-- silently drops a row because of a type error.
\copy raw_validations(  "StationId","StationName","LowOrPeakDescFull",year_key,month_key, \
    day_1,day_2,day_3,day_4,day_5,day_6,day_7,day_8,day_9,day_10,day_11,day_12,day_13,day_14, \
    day_15,day_16,day_17,day_18,day_19,day_20,day_21,day_22,day_23,day_24,day_25,day_26,day_27, \
    day_28,day_29,day_30,day_31 ) \
    FROM 'data/sample/tikufim_station_2023_sample_raw.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
UPDATE raw_validations SET source_file = 'tikufim_station_2023_sample_raw.csv' WHERE source_file IS NULL;

\copy raw_stations FROM 'data/sample/stations_sample_raw.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- To run this against the FULL yearly files instead of the repo's small
-- sample: download the CSVs listed in data/README.md, point \copy at them
-- (one \copy per year, each tagging its own source_file), and everything
-- downstream in 02-05 runs unchanged.
