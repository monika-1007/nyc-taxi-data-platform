CREATE OR REPLACE PROCEDURE mdm.upsert_taxi_zone_scd2(
  p_location_id INT,
  p_zone_name TEXT,
  p_borough TEXT,
  p_service_zone TEXT,
  p_actor TEXT,
  p_reason TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_current mdm.taxi_zone_scd2%ROWTYPE;
  v_new_version INT;
BEGIN
  SELECT *
  INTO v_current
  FROM mdm.taxi_zone_scd2
  WHERE zone_bk_location_id = p_location_id
    AND is_current = TRUE;

  IF NOT FOUND THEN
    INSERT INTO mdm.taxi_zone_scd2 (
      zone_bk_location_id, zone_name, borough, service_zone,
      version, effective_from_ts, effective_to_ts, is_current,
      created_by, updated_by, change_reason
    )
    VALUES (
      p_location_id, p_zone_name, p_borough, p_service_zone,
      1, now(), NULL, TRUE,
      p_actor, p_actor, p_reason
    );

    INSERT INTO mdm.version_audit(entity, record_bk, action, actor, reason, details)
    VALUES ('taxi_zone', p_location_id::text, 'UPSERT', p_actor, p_reason,
            jsonb_build_object('created_version', 1));
    RETURN;
  END IF;

  -- If nothing changed, just update metadata (optional)
  IF v_current.zone_name = p_zone_name
     AND v_current.borough = p_borough
     AND COALESCE(v_current.service_zone,'') = COALESCE(p_service_zone,'') THEN

    UPDATE mdm.taxi_zone_scd2
    SET updated_at = now(), updated_by = p_actor
    WHERE sk_zone_id = v_current.sk_zone_id;

    RETURN;
  END IF;

  -- Close current
  UPDATE mdm.taxi_zone_scd2
  SET effective_to_ts = now(),
      is_current = FALSE,
      updated_at = now(),
      updated_by = p_actor
  WHERE sk_zone_id = v_current.sk_zone_id;

  v_new_version := v_current.version + 1;

  -- Insert new version (unapproved initially)
  INSERT INTO mdm.taxi_zone_scd2 (
    zone_bk_location_id, zone_name, borough, service_zone,
    version, effective_from_ts, effective_to_ts, is_current,
    created_by, updated_by, change_reason
  )
  VALUES (
    p_location_id, p_zone_name, p_borough, p_service_zone,
    v_new_version, now(), NULL, TRUE,
    p_actor, p_actor, p_reason
  );

  INSERT INTO mdm.version_audit(entity, record_bk, action, actor, reason, details)
  VALUES ('taxi_zone', p_location_id::text, 'UPSERT', p_actor, p_reason,
          jsonb_build_object('closed_version', v_current.version, 'new_version', v_new_version));
END;
$$;

CREATE OR REPLACE PROCEDURE mdm.approve_version(
  p_sk_zone_id UUID,
  p_approver TEXT,
  p_reason TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_row mdm.taxi_zone_scd2%ROWTYPE;
BEGIN
  SELECT * INTO v_row FROM mdm.taxi_zone_scd2 WHERE sk_zone_id = p_sk_zone_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No record found for sk_zone_id=%', p_sk_zone_id;
  END IF;

  UPDATE mdm.taxi_zone_scd2
  SET approved_at = now(),
      approved_by = p_approver,
      approval_reason = p_reason,
      updated_at = now(),
      updated_by = p_approver
  WHERE sk_zone_id = p_sk_zone_id;

  INSERT INTO mdm.version_audit(entity, record_bk, action, actor, reason, details)
  VALUES ('taxi_zone', v_row.zone_bk_location_id::text, 'APPROVE', p_approver, p_reason,
          jsonb_build_object('approved_version', v_row.version, 'sk', p_sk_zone_id));
END;
$$;

CREATE OR REPLACE PROCEDURE mdm.rollback_version(
  p_location_id INT,
  p_target_version INT,
  p_actor TEXT,
  p_reason TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_current mdm.taxi_zone_scd2%ROWTYPE;
  v_target  mdm.taxi_zone_scd2%ROWTYPE;
  v_new_version INT;
BEGIN
  SELECT * INTO v_current
  FROM mdm.taxi_zone_scd2
  WHERE zone_bk_location_id = p_location_id AND is_current = TRUE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No current row for location_id=%', p_location_id;
  END IF;

  SELECT * INTO v_target
  FROM mdm.taxi_zone_scd2
  WHERE zone_bk_location_id = p_location_id AND version = p_target_version;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No target version % for location_id=%', p_target_version, p_location_id;
  END IF;

  -- Close current
  UPDATE mdm.taxi_zone_scd2
  SET effective_to_ts = now(),
      is_current = FALSE,
      updated_at = now(),
      updated_by = p_actor
  WHERE sk_zone_id = v_current.sk_zone_id;

  v_new_version := v_current.version + 1;

  -- Insert new version copied from target
  INSERT INTO mdm.taxi_zone_scd2 (
    zone_bk_location_id, zone_name, borough, service_zone,
    version, effective_from_ts, effective_to_ts, is_current,
    created_by, updated_by, change_reason, rollback_of_version
  )
  VALUES (
    p_location_id, v_target.zone_name, v_target.borough, v_target.service_zone,
    v_new_version, now(), NULL, TRUE,
    p_actor, p_actor, p_reason, p_target_version
  );

  INSERT INTO mdm.version_audit(entity, record_bk, action, actor, reason, details)
  VALUES ('taxi_zone', p_location_id::text, 'ROLLBACK', p_actor, p_reason,
          jsonb_build_object('from_version', v_current.version, 'to_target_version', p_target_version, 'new_version', v_new_version));
END;
$$;

CREATE OR REPLACE FUNCTION mdm.audit_version_history(
  p_location_id INT,
  p_start_ts TIMESTAMPTZ,
  p_end_ts   TIMESTAMPTZ
)
RETURNS TABLE (
  zone_bk_location_id INT,
  version INT,
  zone_name TEXT,
  borough TEXT,
  service_zone TEXT,
  effective_from_ts TIMESTAMPTZ,
  effective_to_ts TIMESTAMPTZ,
  is_current BOOLEAN,
  approved_by TEXT,
  approved_at TIMESTAMPTZ,
  rollback_of_version INT,
  change_reason TEXT
)
LANGUAGE sql
AS $$
  SELECT
    zone_bk_location_id, version, zone_name, borough, service_zone,
    effective_from_ts, effective_to_ts, is_current,
    approved_by, approved_at, rollback_of_version, change_reason
  FROM mdm.taxi_zone_scd2
  WHERE zone_bk_location_id = p_location_id
    AND effective_from_ts < p_end_ts
    AND COALESCE(effective_to_ts, now()) >= p_start_ts
  ORDER BY version;
$$;

