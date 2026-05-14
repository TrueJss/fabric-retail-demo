-- =============================================================================
-- 05_fact_sales.sql
-- Central fact table. One row per order line.
-- TotalAmount is pre-calculated at load time (Quantity × UnitPrice) to avoid
-- pushing arithmetic into every DAX measure.
--
-- FK constraints are defined explicitly for documentation and query-optimizer
-- hints. Note: Fabric Warehouse defines FK constraints but does NOT enforce
-- them at write time — referential integrity is guaranteed by the stored
-- procedure load logic, not by the database engine.
--
-- Load strategy: TRUNCATE + INSERT on every run (full reload).
-- Dimensions must be loaded before this table on each pipeline run.
-- =============================================================================

CREATE TABLE gold.FactSales (
    SalesSK         BIGINT          NOT NULL    IDENTITY(1, 1),
    OrderBK         INT             NOT NULL,   -- source order_id (business key)
    CustomerSK      INT             NOT NULL,
    ProductSK       INT             NOT NULL,
    StoreSK         INT             NOT NULL,
    OrderDateKey    INT             NOT NULL,   -- FK → DimDate.DateKey (YYYYMMDD)
    Quantity        INT             NOT NULL,
    UnitPrice       DECIMAL(10, 2)  NOT NULL,
    TotalAmount     DECIMAL(12, 2)  NOT NULL,   -- Quantity × UnitPrice, pre-computed
    Status          VARCHAR(20)     NOT NULL,   -- "completed" | "pending" | "cancelled"
    _LoadTimestamp  DATETIME2       NOT NULL,
    CONSTRAINT PK_FactSales PRIMARY KEY (SalesSK),
    CONSTRAINT FK_FactSales_Customer FOREIGN KEY (CustomerSK) REFERENCES gold.DimCustomer (CustomerSK),
    CONSTRAINT FK_FactSales_Product FOREIGN KEY (ProductSK) REFERENCES gold.DimProduct (ProductSK),
    CONSTRAINT FK_FactSales_Store FOREIGN KEY (StoreSK) REFERENCES gold.DimStore (StoreSK),
    CONSTRAINT FK_FactSales_Date FOREIGN KEY (OrderDateKey) REFERENCES gold.DimDate (DateKey)
);

-- Primary time-based filter in all Power BI report pages
CREATE INDEX IX_FactSales_OrderDateKey
    ON gold.FactSales (OrderDateKey)
    INCLUDE (CustomerSK, ProductSK, StoreSK, TotalAmount, Quantity);

-- Dimension FK indexes — used by Power BI relationship join paths
CREATE INDEX IX_FactSales_CustomerSK
    ON gold.FactSales (CustomerSK)
    INCLUDE (OrderDateKey, TotalAmount);

CREATE INDEX IX_FactSales_ProductSK
    ON gold.FactSales (ProductSK)
    INCLUDE (OrderDateKey, TotalAmount, Quantity);

CREATE INDEX IX_FactSales_StoreSK
    ON gold.FactSales (StoreSK)
    INCLUDE (OrderDateKey, TotalAmount);

-- Supports status-level filtering (completed vs cancelled)
CREATE INDEX IX_FactSales_Status
    ON gold.FactSales (Status)
    INCLUDE (TotalAmount, Quantity);
