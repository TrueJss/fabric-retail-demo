-- =============================================================================
-- 06_user_region_mapping.sql
-- Maps Power BI user email addresses to their permitted Region(s).
-- Used by the dynamic RLS role in the semantic model:
--
--   [Region] = LOOKUPVALUE(
--       UserRegionMapping[Region],
--       UserRegionMapping[UserEmail], USERPRINCIPALNAME()
--   )
--
-- One row per user–region pair. A user with access to multiple regions
-- gets one row per region. A user not present in this table sees no data.
-- Update this table to grant or revoke regional access — no Power BI
-- republish required.
-- =============================================================================

CREATE TABLE gold.UserRegionMapping (
    UserEmail   VARCHAR(255)    NOT NULL,
    Region      VARCHAR(50)     NOT NULL,
    CONSTRAINT PK_UserRegionMapping PRIMARY KEY (UserEmail, Region)
);

-- Fast lookup during RLS evaluation
CREATE INDEX IX_UserRegionMapping_Email
    ON gold.UserRegionMapping (UserEmail)
    INCLUDE (Region);

-- =============================================================================
-- Sample data — replace with real user principal names from your tenant.
-- These demo accounts mirror the four regions in the data model.
-- =============================================================================

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
