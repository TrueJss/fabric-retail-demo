-- =============================================================================
-- usp_Load_DimCustomer.sql
-- Loads gold.DimCustomer from the Silver Delta table via cross-database query.
--
-- Strategy : MERGE (SCD Type 1)
--   MATCHED     → update all non-key attributes (no change detection —
--                  acceptable for this dimension size; see note below)
--   NOT MATCHED → insert new customer with IDENTITY surrogate key
--   NOT MATCHED BY SOURCE → no action (customers are never hard-deleted)
--
-- Cross-database reference: RetailDemo_Lakehouse.dbo.silver_customers
-- The Lakehouse name must match the exact item name in your Fabric workspace.
-- Fabric Warehouse resolves this via the SQL Analytics Endpoint of the Lakehouse,
-- which is automatically available to all items in the same workspace.
--
-- Note on change detection: for production with millions of rows, add an
-- ISNULL-guarded comparison in the WHEN MATCHED clause to skip unchanged rows.
-- At demo scale this is unnecessary.
-- =============================================================================

CREATE   PROCEDURE gold.usp_Load_DimCustomer
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @inserted INT = 0;
    DECLARE @updated INT = 0;

    BEGIN TRY

        MERGE gold.DimCustomer AS tgt
        USING (
            SELECT
                customer_id AS CustomerBK,
                first_name AS FirstName,
                last_name AS LastName,
                CONCAT(first_name, ' ', last_name) AS FullName,
                email AS Email,
                phone AS Phone,
                address_street AS AddressStreet,
                address_city AS AddressCity,
                address_state AS AddressState,
                region AS Region,
                CAST(registration_date AS DATE) AS RegistrationDate,
                GETUTCDATE() AS LoadTimestamp
            FROM RetailDemo_Lakehouse.dbo.silver_customers
        ) AS src
            ON tgt.CustomerBK = src.CustomerBK

        WHEN MATCHED
            THEN
            UPDATE
                SET
                    tgt.FirstName = src.FirstName,
                    tgt.LastName = src.LastName,
                    tgt.FullName = src.FullName,
                    tgt.Email = src.Email,
                    tgt.Phone = src.Phone,
                    tgt.AddressStreet = src.AddressStreet,
                    tgt.AddressCity = src.AddressCity,
                    tgt.AddressState = src.AddressState,
                    tgt.Region = src.Region,
                    tgt.RegistrationDate = src.RegistrationDate,
                    tgt._LoadTimestamp = src.LoadTimestamp

        WHEN NOT MATCHED BY TARGET
            THEN
            INSERT (
                CustomerBK, FirstName, LastName, FullName, Email, Phone,
                AddressStreet, AddressCity, AddressState, Region,
                RegistrationDate, _LoadTimestamp
            )
            VALUES (
                src.CustomerBK, src.FirstName, src.LastName, src.FullName,
                src.Email, src.Phone, src.AddressStreet, src.AddressCity,
                src.AddressState, src.Region, src.RegistrationDate,
                src.LoadTimestamp
            );

        -- @@ROWCOUNT after MERGE = inserts + updates combined
        -- Split is approximated via table counts (exact split needs OUTPUT clause)
        PRINT CONCAT(
            'usp_Load_DimCustomer complete. Rows affected: ',
            @@ROWCOUNT
        );

    END TRY
    BEGIN CATCH
        PRINT CONCAT('usp_Load_DimCustomer FAILED: ', ERROR_MESSAGE());
        THROW;
    END CATCH;

END;