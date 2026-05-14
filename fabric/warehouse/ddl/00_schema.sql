-- =============================================================================
-- 00_schema.sql
-- Creates the gold schema that contains the entire star schema.
-- Run this script first, before any table or view creation.
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
    EXEC ('CREATE SCHEMA gold');
