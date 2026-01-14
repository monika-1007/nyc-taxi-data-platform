-- TEST 1: No null pickup/dropoff
SELECT *
FROM stg.stg_yellow_trips
WHERE pickup_ts IS NULL OR dropoff_ts IS NULL
LIMIT 10;

-- TEST 2: pickup before dropoff must hold
SELECT *
FROM stg.stg_yellow_trips
WHERE pickup_ts >= dropoff_ts
LIMIT 10;

-- TEST 3: trip_distance must be non-negative
SELECT *
FROM stg.stg_yellow_trips
WHERE trip_distance < 0
LIMIT 10;

