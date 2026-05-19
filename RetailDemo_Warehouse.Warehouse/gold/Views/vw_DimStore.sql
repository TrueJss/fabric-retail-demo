-- Auto Generated (Do not modify) 78CFE66D28B9974CE6F2158D1BA5ACEC8DF38AB912B0FC388B2D4CEF8465F2BD
CREATE   VIEW gold.vw_DimStore AS
SELECT
    s.StoreSK,
    s.StoreBK           AS StoreID,
    s.StoreName,
    s.Region,
    s.City,
    s.State,
    s.Manager,
    s.OpenDate
FROM gold.DimStore AS s;