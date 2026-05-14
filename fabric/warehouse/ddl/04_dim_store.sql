-- =============================================================================
-- 04_dim_store.sql
-- Store dimension. Region here matches DimCustomer.Region — both columns draw
-- from the same REGIONS lookup in the source data, which ensures consistent
-- grouping in Power BI cross-filtering.
-- Loaded via MERGE (SCD Type 1) from silver_stores.
-- =============================================================================

CREATE TABLE gold.DimStore (
    StoreSK         INT             NOT NULL    IDENTITY(1, 1),
    StoreBK         INT             NOT NULL,   -- source business key
    StoreName       VARCHAR(100)    NOT NULL,
    Region          VARCHAR(50)     NOT NULL,   -- "North" | "South" | "East" | "West"
    City            VARCHAR(100)    NULL,
    State           CHAR(2)         NULL,
    Manager         VARCHAR(100)    NULL,
    OpenDate        DATE            NULL,
    _LoadTimestamp  DATETIME2       NOT NULL,
    CONSTRAINT PK_DimStore PRIMARY KEY (StoreSK)
);

-- Lookup index for MERGE join
CREATE UNIQUE INDEX IX_DimStore_BK
    ON gold.DimStore (StoreBK);

-- Supports regional store breakdowns in Power BI
CREATE INDEX IX_DimStore_Region
    ON gold.DimStore (Region)
    INCLUDE (StoreSK, StoreName);
