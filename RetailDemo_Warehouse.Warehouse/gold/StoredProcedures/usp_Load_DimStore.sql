-- =============================================================================
-- usp_Load_DimStore.sql
-- Loads gold.DimStore from the Silver Delta table via cross-database query.
--
-- Strategy : MERGE (SCD Type 1)
-- Silver source: RetailDemo_Lakehouse.dbo.silver_stores
-- =============================================================================

CREATE   PROCEDURE gold.usp_Load_DimStore
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        MERGE gold.DimStore AS tgt
        USING (
            SELECT
                store_id AS StoreBK,
                name AS StoreName,
                region AS Region,
                city AS City,
                state AS State,
                manager AS Manager,
                CAST(open_date AS DATE) AS OpenDate,
                GETUTCDATE() AS LoadTimestamp
            FROM RetailDemo_Lakehouse.dbo.silver_stores
        ) AS src
            ON tgt.StoreBK = src.StoreBK

        WHEN MATCHED
            THEN
            UPDATE
                SET
                    tgt.StoreName = src.StoreName,
                    tgt.Region = src.Region,
                    tgt.City = src.City,
                    tgt.State = src.State,
                    tgt.Manager = src.Manager,
                    tgt.OpenDate = src.OpenDate,
                    tgt._LoadTimestamp = src.LoadTimestamp

        WHEN NOT MATCHED BY TARGET
            THEN
            INSERT (
                StoreBK, StoreName, Region, City,
                State, Manager, OpenDate, _LoadTimestamp
            )
            VALUES (
                src.StoreBK, src.StoreName, src.Region, src.City,
                src.State, src.Manager, src.OpenDate, src.LoadTimestamp
            );

        PRINT CONCAT(
            'usp_Load_DimStore complete. Rows affected: ',
            @@ROWCOUNT
        );

    END TRY
    BEGIN CATCH
        PRINT CONCAT('usp_Load_DimStore FAILED: ', ERROR_MESSAGE());
        THROW;
    END CATCH;

END;