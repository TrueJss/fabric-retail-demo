-- =============================================================================
-- 08_views.sql
-- Semantic layer views. Power BI Import mode connects to these views, not the
-- raw tables. This decouples the report from physical schema changes — adding
-- a column to a table, renaming an internal field, or changing a data type
-- only requires updating a view, not republishing the semantic model.
--
-- Each view is a clean projection of its underlying table with no joins.
-- Star schema relationships are defined inside the Power BI semantic model.
-- =============================================================================


-- ---------------------------------------------------------------------------
-- vw_FactSales
-- Exposes all fact columns. Excludes the internal SalesSK (not needed in PBI)
-- and the audit _LoadTimestamp (kept in the table, not surfaced in the model).
-- ---------------------------------------------------------------------------
CREATE OR ALTER VIEW gold.vw_FactSales AS
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


-- ---------------------------------------------------------------------------
-- vw_DimCustomer
-- Surfaces the customer dimension. Region is the RLS control column — it must
-- be present and correctly named here for the semantic model RLS filter to work.
-- CustomerSK is the join key to FactSales.
-- ---------------------------------------------------------------------------
CREATE OR ALTER VIEW gold.vw_DimCustomer AS
SELECT
    c.CustomerSK,
    c.CustomerBK        AS CustomerID,
    c.FirstName,
    c.LastName,
    c.FullName,
    c.Email,
    c.Phone,
    c.AddressStreet,
    c.AddressCity,
    c.AddressState,
    c.Region,
    c.RegistrationDate
FROM gold.DimCustomer AS c;


-- ---------------------------------------------------------------------------
-- vw_DimProduct
-- Surfaces the product dimension including the category hierarchy flattened
-- into the same row. Power BI will build the hierarchy from CategoryName →
-- ProductName columns.
-- ---------------------------------------------------------------------------
CREATE OR ALTER VIEW gold.vw_DimProduct AS
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


-- ---------------------------------------------------------------------------
-- vw_DimStore
-- Surfaces the store dimension. Region aligns with DimCustomer.Region
-- (same four values: North / South / East / West).
-- ---------------------------------------------------------------------------
CREATE OR ALTER VIEW gold.vw_DimStore AS
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


-- ---------------------------------------------------------------------------
-- vw_DimDate
-- Full calendar dimension. Power BI uses this to build the date hierarchy
-- (Year → Quarter → Month → Day) and for time intelligence measures (YTD,
-- MoM, rolling 12 months).
-- ---------------------------------------------------------------------------
CREATE OR ALTER VIEW gold.vw_DimDate AS
SELECT
    d.DateKey,
    d.FullDate,
    d.DayOfWeek,
    d.DayName,
    d.DayOfMonth,
    d.DayOfYear,
    d.WeekOfYear,
    d.MonthNumber,
    d.MonthName,
    d.MonthShort,
    d.Quarter,
    d.QuarterName,
    d.YearNumber,
    d.IsWeekend
FROM gold.DimDate AS d;


-- ---------------------------------------------------------------------------
-- vw_UserRegionMapping
-- Exposes the RLS mapping table. Power BI does NOT import this view — it is
-- used exclusively inside the RLS DAX filter expression in the semantic model:
--
--   [Region] = LOOKUPVALUE(
--       UserRegionMapping[Region],
--       UserRegionMapping[UserEmail],
--       USERPRINCIPALNAME()
--   )
-- ---------------------------------------------------------------------------
CREATE OR ALTER VIEW gold.vw_UserRegionMapping AS
SELECT
    m.UserEmail,
    m.Region
FROM gold.UserRegionMapping AS m;
