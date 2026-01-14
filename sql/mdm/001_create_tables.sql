-- File: 001_create_tables.sql
-- Purpose: Create SCD Type 2 master data tables for Taxi Zones
-- Author: Monika
-- Owner: Data Engineering
-- Database: PostgreSQL (RDS)

-- Create schema for master data
CREATE SCHEMA IF NOT EXISTS mdm;

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- SCD Type 2 table for Taxi Zones
CREATE TABLE IF NOT EXISTS mdm.taxi_zone_scd2 (
    sk_zone_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),   -- surrogate key
    zone_bk_location_id INT NOT NULL,                        -- business key (LocationID)

    zone_name TEXT NOT NULL,
    borough TEXT NOT NULL,
    service_zone TEXT,

    -- SCD Type 2 columns
    version INT NOT NULL,
    effective_from_ts TIMESTAMPTZ NOT NULL DEFAULT now(),
    effective_to_ts TIMESTAMPTZ,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,

    -- Governance metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by TEXT NOT NULL,

    approved_at TIMESTAMPTZ,
    approved_by TEXT,
    approval_reason TEXT,

    change_reason TEXT,
    rollback_of_version INT,

    CONSTRAINT uq_zone_current UNIQUE (zone_bk_location_id, is_current)
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_taxi_zone_bk
ON mdm.taxi_zone_scd2 (zone_bk_location_id);

CREATE INDEX IF NOT EXISTS idx_taxi_zone_effective
ON mdm.taxi_zone_scd2 (zone_bk_location_id, effective_from_ts, effective_to_ts);

-- Audit table to track version actions
CREATE TABLE IF NOT EXISTS mdm.version_audit (
    audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    entity TEXT NOT NULL,          -- e.g., 'taxi_zone'
    record_bk TEXT NOT NULL,       -- business key (LocationID as text)
    action TEXT NOT NULL,          -- UPSERT / APPROVE / ROLLBACK
    actor TEXT NOT NULL,           -- who did it
    reason TEXT,                   -- why
    at_ts TIMESTAMPTZ NOT NULL DEFAULT now(),

    details JSONB                  -- flexible details
);

CREATE INDEX IF NOT EXISTS idx_version_audit_entity
ON mdm.version_audit (entity, record_bk, at_ts DESC);

