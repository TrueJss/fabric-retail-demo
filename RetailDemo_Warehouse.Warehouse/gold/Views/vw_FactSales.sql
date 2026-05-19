-- Auto Generated (Do not modify) 0E7318FF7036C0265339985EC1D325111DA5FF587857C7CC444CF24FBA3D4E75
CREATE   VIEW gold.vw_FactSales AS
SELECT
    f.OrderBK           AS OrderID,
    f.CustomerSK,
    f.ProductSK,
    f.StoreSK,
    f.OrderDateKey,
    f.Quantity,
    f.UnitPrice,
    f.TotalAmount,
    f.Status            AS OrderStatus
FROM gold.FactSales AS f;