# NYC Taxi SQL Transform Catalog

## 01_stg_yellow_trips
- Purpose: Standardize raw yellow taxi trips
- Input: raw.yellow_tripdata
- Output: stg.stg_yellow_trips
- Owner: DataEngineering
- Quality: Type casting only

## 02_fct_trips_clean
- Purpose: Clean trips for analytics
- Input: stg.stg_yellow_trips
- Output: curated.fct_trips_clean
- Rules:
  - pickup < dropoff
  - trip_distance 0–200
  - total_amount -50–1000

## 03_fct_trips_enriched
- Purpose: Add zone context
- Inputs: curated.fct_trips_clean + mdm zone tables
- Output: curated.fct_trips_enriched

