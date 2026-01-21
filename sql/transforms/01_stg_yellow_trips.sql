-- Transform: 01_stg_yellow_trips
-- Author: Monika (Intern)
-- Owner: DataEngineering
-- Purpose: Standardize raw yellow taxi trips and enforce basic type casting.
-- Inputs: raw.yellow_tripdata
-- Output: stg.stg_yellow_trips
-- Dependencies: None
-- Notes: This is the first staging layer (minimal business logic).

-- CREATE SCHEMA IF NOT EXISTS stg;

CREATE OR REPLACE VIEW stg.stg_yellow_trips AS
SELECT
  VendorID,
  CAST(tpep_pickup_datetime AS timestamp)  AS pickup_ts,
  CAST(tpep_dropoff_datetime AS timestamp) AS dropoff_ts,
  passenger_count,
  trip_distance,
  RatecodeID,
  PULocationID,
  DOLocationID,
  payment_type,
  fare_amount,
  tip_amount,
  tolls_amount,
  total_amount
FROM raw.yellow_tripdata;

