-- Data Quality Checks: yellow trips curated
-- Purpose: Identify failed records and compute pass rates

-- 1) pickup must be before dropoff
SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN pickup_ts < dropoff_ts THEN 1 ELSE 0 END) AS pass_rows,
  1.0 * SUM(CASE WHEN pickup_ts < dropoff_ts THEN 1 ELSE 0 END) / COUNT(*) AS pass_rate
FROM stg.stg_yellow_trips;

-- 2) trip_distance range
SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN trip_distance BETWEEN 0 AND 200 THEN 1 ELSE 0 END) AS pass_rows,
  1.0 * SUM(CASE WHEN trip_distance BETWEEN 0 AND 200 THEN 1 ELSE 0 END) / COUNT(*) AS pass_rate
FROM stg.stg_yellow_trips;

-- 3) total_amount range
SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN total_amount BETWEEN -50 AND 1000 THEN 1 ELSE 0 END) AS pass_rows,
  1.0 * SUM(CASE WHEN total_amount BETWEEN -50 AND 1000 THEN 1 ELSE 0 END) / COUNT(*) AS pass_rate
FROM stg.stg_yellow_trips;

