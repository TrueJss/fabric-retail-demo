-- =============================================================================
-- 03_dim_product.sql
-- Product dimension including the category hierarchy flattened into the row.
-- Category is denormalised here (no separate DimCategory table) because Power BI
-- handles the hierarchy via a single table — this keeps the model simpler and
-- Import mode scans faster.
-- Loaded via MERGE (SCD Type 1) from silver_products.
-- =============================================================================

CREATE TABLE gold.DimProduct (
    ProductSK       INT             NOT NULL    IDENTITY(1, 1),
    ProductBK       INT             NOT NULL,   -- source business key
    CategoryID      INT             NOT NULL,
    CategoryName    VARCHAR(100)    NOT NULL,
    ProductName     VARCHAR(255)    NOT NULL,
    CostPrice       DECIMAL(10, 2)  NOT NULL,
    RetailPrice     DECIMAL(10, 2)  NOT NULL,
    MarginPct       DECIMAL(5, 2)   NULL,       -- (RetailPrice - CostPrice) / RetailPrice * 100
    _LoadTimestamp  DATETIME2       NOT NULL,
    CONSTRAINT PK_DimProduct PRIMARY KEY (ProductSK)
);

-- Lookup index for MERGE join
CREATE UNIQUE INDEX IX_DimProduct_BK
    ON gold.DimProduct (ProductBK);

-- Supports category-level slicing in Power BI
CREATE INDEX IX_DimProduct_Category
    ON gold.DimProduct (CategoryID, CategoryName)
    INCLUDE (ProductSK, ProductName);
