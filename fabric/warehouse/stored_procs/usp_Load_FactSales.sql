-- =============================================================================
-- usp_Load_FactSales.sql
-- Loads gold.FactSales from Silver via cross-database query.
-- Strategy: TRUNCATE + INSERT (full reload).
-- =============================================================================

CREATE OR ALTER PROCEDURE gold.usp_Load_FactSales
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        TRUNCATE TABLE gold.FactSales;

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
            o.order_id,
            c.CustomerSK,
            p.ProductSK,
            s.StoreSK,
            d.DateKey,
            o.quantity,
            o.unit_price,
            CAST(o.quantity * o.unit_price AS DECIMAL(12, 2)) AS TotalAmount,
            o.status,
            GETUTCDATE() AS _LoadTimestamp
        FROM RetailDemo_Lakehouse.dbo.silver_orders AS o
        INNER JOIN gold.DimCustomer AS c
            ON o.customer_id = c.CustomerBK
        INNER JOIN gold.DimProduct AS p
            ON o.product_id = p.ProductBK
        INNER JOIN gold.DimStore AS s
            ON o.store_id = s.StoreBK
        INNER JOIN gold.DimDate AS d
            ON o.order_date = d.FullDate;

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
