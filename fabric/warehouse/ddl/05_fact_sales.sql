-- =============================================================================
-- 05_fact_sales.sql
-- Note: PRIMARY KEY and FOREIGN KEY constraints are not supported inline in
-- Fabric Warehouse CREATE TABLE statements. Uniqueness on SalesSK enforced
-- via IDENTITY + CREATE UNIQUE INDEX. Referential integrity is guaranteed
-- by the stored procedure load logic (INNER JOIN SK lookups).
-- =============================================================================

CREATE TABLE gold.FactSales (
    SalesSK         BIGINT          NOT NULL    IDENTITY(1, 1),
    OrderBK         INT             NOT NULL,
    CustomerSK      INT             NOT NULL,
    ProductSK       INT             NOT NULL,
    StoreSK         INT             NOT NULL,
    OrderDateKey    INT             NOT NULL,
    Quantity        INT             NOT NULL,
    UnitPrice       DECIMAL(10, 2)  NOT NULL,
    TotalAmount     DECIMAL(12, 2)  NOT NULL,
    Status          VARCHAR(20)     NOT NULL,
    _LoadTimestamp  DATETIME2       NOT NULL
);

CREATE UNIQUE INDEX IX_FactSales_PK
    ON gold.FactSales (SalesSK);

CREATE INDEX IX_FactSales_OrderDateKey
    ON gold.FactSales (OrderDateKey)
    INCLUDE (CustomerSK, ProductSK, StoreSK, TotalAmount, Quantity);

CREATE INDEX IX_FactSales_CustomerSK
    ON gold.FactSales (CustomerSK)
    INCLUDE (OrderDateKey, TotalAmount);

CREATE INDEX IX_FactSales_ProductSK
    ON gold.FactSales (ProductSK)
    INCLUDE (OrderDateKey, TotalAmount, Quantity);

CREATE INDEX IX_FactSales_StoreSK
    ON gold.FactSales (StoreSK)
    INCLUDE (OrderDateKey, TotalAmount);

CREATE INDEX IX_FactSales_Status
    ON gold.FactSales (Status)
    INCLUDE (TotalAmount, Quantity);
