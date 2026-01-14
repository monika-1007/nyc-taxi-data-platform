-- Transform: 02_fct_trips_clean
-- Author: Monika (Intern)
-- Owner: DataEngineering
-- Purpose: Clean and filter trip records for analytics.
-- Inputs: stg.stg_yellow_trips
-- Output: curated.fct_trips_clean
-- Dependencies: stg.stg_yellow_trips
-- Quality: pickup_ts < dropoff_ts, trip_distance >= 0, total_amount reasonable

CREATE SCHEMA IF NOT EXISTS curated;

CREATE OR REPLACE VIEW curated.fct_trips_clean AS
SELECT
  VendorID,
  pickup_ts,
  dropoff_ts,
  passenger_count,
  trip_distance,
  RatecodeID,
  PULocationID,
  DOLocationID,
  payment_type,
  fare_amount,
  tip_amount,
  tolls_amount,
  total_amount,
  EXTRACT(EPOCH FROM (dropoff_ts - pickup_ts)) / 60.0 AS trip_minutes
FROM stg.stg_yellow_trips
WHERE
  pickup_ts IS NOT NULL
  AND dropoff_ts IS NOT NULL
  AND pickup_ts < dropoff_ts
  AND trip_distance BETWEEN 0 AND 200
  AND total_amount BETWEEN -50 AND 1000;

