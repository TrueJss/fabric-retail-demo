-- Auto Generated (Do not modify) E204B03A931D189D6EFC2658F782A5210B78373575029150CC6298BC958639DD
CREATE   VIEW gold.vw_DimProduct AS
SELECT
    p.ProductSK,
    p.ProductBK         AS ProductID,
    p.CategoryID,
    p.CategoryName,
    p.ProductName,
    p.CostPrice,
    p.RetailPrice,
    p.MarginPct
FROM gold.DimProduct AS p;