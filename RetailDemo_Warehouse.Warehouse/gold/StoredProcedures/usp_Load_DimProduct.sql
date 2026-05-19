-- =============================================================================
-- usp_Load_DimProduct.sql
-- Loads gold.DimProduct from the Silver Delta table via cross-database query.
--
-- Strategy : MERGE (SCD Type 1)
-- Silver source: RetailDemo_Lakehouse.dbo.silver_products
--
-- silver_products already carries the category hierarchy flattened into each
-- row (category_id + category_name), so no additional join is needed here.
-- =============================================================================

CREATE   PROCEDURE gold.usp_Load_DimProduct
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        MERGE gold.DimProduct AS tgt
        USING (
            SELECT
                product_id AS ProductBK,
                CAST(category_id AS INT) AS CategoryID,
                category_name AS CategoryName,
                name AS ProductName,
                CAST(cost_price AS DECIMAL(10, 2)) AS CostPrice,
                CAST(retail_price AS DECIMAL(10, 2)) AS RetailPrice,
                CAST(margin_pct AS DECIMAL(5, 2)) AS MarginPct,
                GETUTCDATE() AS LoadTimestamp
            FROM RetailDemo_Lakehouse.dbo.silver_products
        ) AS src
            ON tgt.ProductBK = src.ProductBK

        WHEN MATCHED
            THEN
            UPDATE
                SET
                    tgt.CategoryID = src.CategoryID,
                    tgt.CategoryName = src.CategoryName,
                    tgt.ProductName = src.ProductName,
                    tgt.CostPrice = src.CostPrice,
                    tgt.RetailPrice = src.RetailPrice,
                    tgt.MarginPct = src.MarginPct,
                    tgt._LoadTimestamp = src.LoadTimestamp

        WHEN NOT MATCHED BY TARGET
            THEN
            INSERT (
                ProductBK, CategoryID, CategoryName, ProductName,
                CostPrice, RetailPrice, MarginPct, _LoadTimestamp
            )
            VALUES (
                src.ProductBK, src.CategoryID, src.CategoryName,
                src.ProductName, src.CostPrice, src.RetailPrice,
                src.MarginPct, src.LoadTimestamp
            );

        PRINT CONCAT(
            'usp_Load_DimProduct complete. Rows affected: ',
            @@ROWCOUNT
        );

    END TRY
    BEGIN CATCH
        PRINT CONCAT('usp_Load_DimProduct FAILED: ', ERROR_MESSAGE());
        THROW;
    END CATCH;

END;