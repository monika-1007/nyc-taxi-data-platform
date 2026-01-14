from pyspark.sql import functions as F
from delta.tables import DeltaTable

delta_path = "s3://nyc-taxizone-dev-raw/delta/mdm/taxi_zone_scd2/"
run_ts = F.current_timestamp()

# incoming source (example: from parquet/csv already loaded as df)
# df_in columns: zone_bk_location_id, zone_name, borough, service_zone, updated_by, change_reason
df_in = spark.table("nyc_taxi.raw_taxi_zone_lookup") \
    .select(
        F.col("LocationID").cast("int").alias("zone_bk_location_id"),
        F.col("Zone").alias("zone_name"),
        F.col("Borough").alias("borough"),
        F.col("service_zone").alias("service_zone")
    ) \
    .withColumn("updated_by", F.lit("scd2_delta_job")) \
    .withColumn("change_reason", F.lit("daily refresh"))

# Create delta table if not exists
if not DeltaTable.isDeltaTable(spark, delta_path):
    (df_in
     .withColumn("version", F.lit(1))
     .withColumn("effective_from_ts", run_ts)
     .withColumn("effective_to_ts", F.lit(None).cast("timestamp"))
     .withColumn("is_current", F.lit(True))
     .write.format("delta")
     .mode("overwrite")
     .save(delta_path))
else:
    dt = DeltaTable.forPath(spark, delta_path)

    # Current records
    df_cur = spark.read.format("delta").load(delta_path).filter("is_current = true") \
        .select("zone_bk_location_id","zone_name","borough","service_zone","version")

    # Join to detect changes
    df_changes = (df_in.alias("s")
        .join(df_cur.alias("t"), on="zone_bk_location_id", how="left")
        .withColumn("is_new", F.col("t.zone_bk_location_id").isNull())
        .withColumn("is_changed",
                    (~F.col("is_new")) & (
                        (F.col("s.zone_name") != F.col("t.zone_name")) |
                        (F.col("s.borough") != F.col("t.borough")) |
                        (F.coalesce(F.col("s.service_zone"), F.lit("")) != F.coalesce(F.col("t.service_zone"), F.lit("")))
                    ))
        .filter("is_new OR is_changed")
        .select("s.*", F.col("t.version").alias("prev_version"))
    )

    # 1) Close out old current records for changed keys
    keys_to_close = df_changes.filter("is_changed = true").select("zone_bk_location_id").distinct()
    dt.alias("t").merge(
        keys_to_close.alias("k"),
        "t.zone_bk_location_id = k.zone_bk_location_id AND t.is_current = true"
    ).whenMatchedUpdate(set={
        "effective_to_ts": "current_timestamp()",
        "is_current": "false"
    }).execute()

    # 2) Insert new versions
    df_new_versions = (df_changes
        .withColumn("version", F.when(F.col("prev_version").isNull(), F.lit(1)).otherwise(F.col("prev_version") + 1))
        .withColumn("effective_from_ts", F.current_timestamp())
        .withColumn("effective_to_ts", F.lit(None).cast("timestamp"))
        .withColumn("is_current", F.lit(True))
        .drop("prev_version")
    )

    (df_new_versions
     .write.format("delta")
     .mode("append")
     .save(delta_path))

