-- =============================================================================
-- 02_dim_customer.sql
-- Fabric Warehouse limitations applied:
--   - No inline PRIMARY KEY
--   - IDENTITY with no seed/increment parameters
--   - No CREATE INDEX
-- =============================================================================
 
CREATE TABLE gold.DimCustomer (
    CustomerSK          INT             NOT NULL    IDENTITY,
    CustomerBK          INT             NOT NULL,
    FirstName           VARCHAR(100)    NOT NULL,
    LastName            VARCHAR(100)    NOT NULL,
    FullName            VARCHAR(200)    NOT NULL,
    Email               VARCHAR(255)    NOT NULL,
    Phone               VARCHAR(50)     NULL,
    AddressStreet       VARCHAR(255)    NULL,
    AddressCity         VARCHAR(100)    NULL,
    AddressState        CHAR(2)         NULL,
    Region              VARCHAR(50)     NOT NULL,
    RegistrationDate    DATE            NULL,
    _LoadTimestamp      DATETIME2       NOT NULL
);
