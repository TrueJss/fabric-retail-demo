-- =============================================================================
-- 02_dim_customer.sql
-- Note: PRIMARY KEY constraints are not supported inline in Fabric Warehouse
-- CREATE TABLE statements. Uniqueness enforced via CREATE UNIQUE INDEX.
-- =============================================================================

CREATE TABLE gold.DimCustomer (
    CustomerSK          INT             NOT NULL    IDENTITY(1, 1),
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

CREATE UNIQUE INDEX IX_DimCustomer_PK
    ON gold.DimCustomer (CustomerSK);

CREATE UNIQUE INDEX IX_DimCustomer_BK
    ON gold.DimCustomer (CustomerBK);

CREATE INDEX IX_DimCustomer_Region
    ON gold.DimCustomer (Region)
    INCLUDE (CustomerSK);
