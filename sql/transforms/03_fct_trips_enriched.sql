-- Transform: 03_fct_trips_enriched
-- Author: Monika (Intern)
-- Owner: DataEngineering
-- Purpose: Enrich trips with pickup/dropoff zone names for reporting.
-- Inputs: curated.fct_trips_clean, mdm.dim_taxi_zone_golden (or raw taxi zone lookup)
-- Output: curated.fct_trips_enriched

CREATE OR REPLACE VIEW curated.fct_trips_enriched AS
SELECT
  t.*,
  pu.canonical_zone_name AS pickup_zone,
  pu.borough             AS pickup_borough,
  do.canonical_zone_name AS dropoff_zone,
  do.borough             AS dropoff_borough
FROM curated.fct_trips_clean t
LEFT JOIN mdm.map_zone_locationid_to_golden mpu
  ON t.PULocationID = mpu.location_id AND mpu.active_flag = true
LEFT JOIN mdm.dim_taxi_zone_golden pu
  ON mpu.golden_zone_id = pu.golden_zone_id AND pu.current_flag = true
LEFT JOIN mdm.map_zone_locationid_to_golden mdo
  ON t.DOLocationID = mdo.location_id AND mdo.active_flag = true
LEFT JOIN mdm.dim_taxi_zone_golden do
  ON mdo.golden_zone_id = do.golden_zone_id AND do.current_flag = true;

