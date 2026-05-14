-- =============================================================================
-- usp_Load_FactSales.sql
-- Loads gold.FactSales from the Silver Delta table via cross-database query.
--
-- Strategy : TRUNCATE + INSERT (full reload every run)
--   Dimensions are fully loaded before this procedure runs (guaranteed by the
--   master pipeline execution order). All SK lookups use INNER JOINs — orders
--   that have no matching dimension row are silently excluded. This should not
--   happen if Silver data quality assertions passed, but excludes any edge case
--   without failing the pipeline.
--
-- DateKey derivation: CONVERT(INT, CONVERT(VARCHAR(8), order_date, 112))
--   Converts a DATE column to YYYYMMDD integer format (e.g. 20230115).
--   CONVERT style 112 = ISO yyyymmdd. CONVERT rather than CAST is required
--   here because we need format control — this is the only deliberate
--   exception to the project's CAST-first convention.
--
-- TotalAmount: pre-calculated as Quantity × UnitPrice at load time to avoid
--   pushing arithmetic into every DAX measure at query time.
-- =============================================================================

CREATE OR ALTER PROCEDURE gold.usp_Load_FactSales
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- Step 1: clear the fact table
        -- TRUNCATE is safe here: dimensions are loaded first and all FKs
        -- will be satisfied by the subsequent INSERT.
        TRUNCATE TABLE gold.FactSales;

        -- Step 2: insert all completed + pending + cancelled orders
        -- with surrogate keys resolved via dimension joins
        INSERT INTO gold.FactSales (
            OrderBK,
            CustomerSK,
            ProductSK,
            StoreSK,
            OrderDateKey,
            Quantity,
            UnitPrice,
            TotalAmount,
            Status,
            _LoadTimestamp
        )
        SELECT
            o.order_id AS OrderBK,
            c.CustomerSK,
            p.ProductSK,
            s.StoreSK,
            CONVERT(INT, CONVERT(VARCHAR(8), CAST(o.order_date AS DATE), 112)) AS OrderDateKey,
            CAST(o.quantity AS INT) AS Quantity,
            CAST(o.unit_price AS DECIMAL(10, 2)) AS UnitPrice,
            CAST(o.quantity * o.unit_price AS DECIMAL(12, 2)) AS TotalAmount,
            o.status AS Status,
            GETUTCDATE() AS _LoadTimestamp
        FROM RetailDemo_Lakehouse.dbo.silver_orders AS o
        INNER JOIN gold.DimCustomer AS c ON c.CustomerBK = CAST(o.customer_id AS INT)
        INNER JOIN gold.DimProduct AS p ON p.ProductBK = CAST(o.product_id AS INT)
        INNER JOIN gold.DimStore AS s ON s.StoreBK = CAST(o.store_id AS INT)
        INNER JOIN gold.DimDate AS d
            ON d.DateKey = CONVERT(INT, CONVERT(VARCHAR(8), CAST(o.order_date AS DATE), 112));

        PRINT CONCAT(
            'usp_Load_FactSales complete. Rows inserted: ',
            @@ROWCOUNT
        );

    END TRY
    BEGIN CATCH
        PRINT CONCAT('usp_Load_FactSales FAILED: ', ERROR_MESSAGE());
        THROW;
    END CATCH;

END;
