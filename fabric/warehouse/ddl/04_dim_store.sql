-- =============================================================================
-- 04_dim_store.sql
-- Note: PRIMARY KEY constraints are not supported inline in Fabric Warehouse
-- CREATE TABLE statements. Uniqueness enforced via CREATE UNIQUE INDEX.
-- =============================================================================

CREATE TABLE gold.DimStore (
    StoreSK         INT             NOT NULL    IDENTITY(1, 1),
    StoreBK         INT             NOT NULL,
    StoreName       VARCHAR(100)    NOT NULL,
    Region          VARCHAR(50)     NOT NULL,
    City            VARCHAR(100)    NULL,
    State           CHAR(2)         NULL,
    Manager         VARCHAR(100)    NULL,
    OpenDate        DATE            NULL,
    _LoadTimestamp  DATETIME2       NOT NULL
);

CREATE UNIQUE INDEX IX_DimStore_PK
    ON gold.DimStore (StoreSK);

CREATE UNIQUE INDEX IX_DimStore_BK
    ON gold.DimStore (StoreBK);

CREATE INDEX IX_DimStore_Region
    ON gold.DimStore (Region)
    INCLUDE (StoreSK, StoreName);
