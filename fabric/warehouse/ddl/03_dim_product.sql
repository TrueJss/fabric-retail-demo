-- =============================================================================
-- 03_dim_product.sql
-- Note: PRIMARY KEY constraints are not supported inline in Fabric Warehouse
-- CREATE TABLE statements. Uniqueness enforced via CREATE UNIQUE INDEX.
-- =============================================================================

CREATE TABLE gold.DimProduct (
    ProductSK       INT             NOT NULL    IDENTITY(1, 1),
    ProductBK       INT             NOT NULL,
    CategoryID      INT             NOT NULL,
    CategoryName    VARCHAR(100)    NOT NULL,
    ProductName     VARCHAR(255)    NOT NULL,
    CostPrice       DECIMAL(10, 2)  NOT NULL,
    RetailPrice     DECIMAL(10, 2)  NOT NULL,
    MarginPct       DECIMAL(5, 2)   NULL,
    _LoadTimestamp  DATETIME2       NOT NULL
);

CREATE UNIQUE INDEX IX_DimProduct_PK
    ON gold.DimProduct (ProductSK);

CREATE UNIQUE INDEX IX_DimProduct_BK
    ON gold.DimProduct (ProductBK);

CREATE INDEX IX_DimProduct_Category
    ON gold.DimProduct (CategoryID, CategoryName)
    INCLUDE (ProductSK, ProductName);
