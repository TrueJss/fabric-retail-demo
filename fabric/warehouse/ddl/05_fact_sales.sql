-- =============================================================================
-- 05_fact_sales.sql
-- Fabric Warehouse limitations applied:
--   - No inline PRIMARY KEY or FOREIGN KEY
--   - IDENTITY with no seed/increment parameters
--   - No CREATE INDEX
-- Referential integrity is guaranteed by stored procedure INNER JOIN lookups.
-- =============================================================================

CREATE TABLE gold.FactSales (
    SalesSK         BIGINT          NOT NULL    IDENTITY,
    OrderBK         INT             NOT NULL,
    CustomerSK      INT             NOT NULL,
    ProductSK       INT             NOT NULL,
    StoreSK         INT             NOT NULL,
    OrderDateKey    INT             NOT NULL,
    Quantity        INT             NOT NULL,
    UnitPrice       DECIMAL(10, 2)  NOT NULL,
    TotalAmount     DECIMAL(12, 2)  NOT NULL,
    Status          VARCHAR(20)     NOT NULL,
    _LoadTimestamp  DATETIME2(6)    NOT NULL
);
