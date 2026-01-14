CALL mdm.upsert_taxi_zone_scd2(56, 'Corona', 'Queens', 'Boro Zone', 'monika', 'initial load');

CALL mdm.upsert_taxi_zone_scd2(56, 'Corona Area', 'Queens', 'Boro Zone', 'monika', 'rename for standardization');

SELECT sk_zone_id, zone_bk_location_id, version, zone_name, is_current
FROM mdm.taxi_zone_scd2
WHERE zone_bk_location_id = 56
ORDER BY version;

CALL mdm.approve_version('<PASTE_SK_UUID_HERE>', 'steward_sim', 'approved naming update');

CALL mdm.rollback_version(56, 1, 'steward_sim', 'rollback - incorrect rename');

SELECT *
FROM mdm.audit_version_history(56, now() - interval '30 days', now());

