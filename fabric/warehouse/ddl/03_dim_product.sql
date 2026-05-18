-- =============================================================================
-- 03_dim_product.sql
-- Fabric Warehouse limitations applied:
--   - No inline PRIMARY KEY
--   - IDENTITY with no seed/increment parameters
--   - No CREATE INDEX
-- =============================================================================
 
CREATE TABLE gold.DimProduct (
    ProductSK       BIGINT          NOT NULL    IDENTITY,
    ProductBK       INT             NOT NULL,
    CategoryID      INT             NOT NULL,
    CategoryName    VARCHAR(100)    NOT NULL,
    ProductName     VARCHAR(255)    NOT NULL,
    CostPrice       DECIMAL(10, 2)  NOT NULL,
    RetailPrice     DECIMAL(10, 2)  NOT NULL,
    MarginPct       DECIMAL(5, 2)   NULL,
    _LoadTimestamp  DATETIME2(6)    NOT NULL
);
