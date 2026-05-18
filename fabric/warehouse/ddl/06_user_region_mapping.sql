-- =============================================================================
-- 06_user_region_mapping.sql
-- Fabric Warehouse limitations applied:
--   - No inline PRIMARY KEY
--   - No CREATE INDEX
-- =============================================================================
 
CREATE TABLE gold.UserRegionMapping (
    UserEmail   VARCHAR(255)    NOT NULL,
    Region      VARCHAR(50)     NOT NULL
);
 
INSERT INTO gold.UserRegionMapping (UserEmail, Region)
VALUES
('north.manager@demo.com', 'North'),
('south.manager@demo.com', 'South'),
('east.manager@demo.com', 'East'),
('west.manager@demo.com', 'West'),
('national.manager@demo.com', 'North'),
('national.manager@demo.com', 'South'),
('national.manager@demo.com', 'East'),
('national.manager@demo.com', 'West');
