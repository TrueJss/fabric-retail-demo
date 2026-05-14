-- =============================================================================
-- 02_dim_customer.sql
-- Customer dimension. Loaded from silver_customers via stored procedure
-- usp_Load_DimCustomer (MERGE / SCD Type 1).
--
-- Region is the RLS control column — the dynamic RLS filter in Power BI
-- joins UserRegionMapping.Region to DimCustomer.Region via USERPRINCIPALNAME().
-- =============================================================================

CREATE TABLE gold.DimCustomer (
    CustomerSK          INT             NOT NULL    IDENTITY(1, 1),
    CustomerBK          INT             NOT NULL,   -- source business key
    FirstName           VARCHAR(100)    NOT NULL,
    LastName            VARCHAR(100)    NOT NULL,
    FullName            VARCHAR(200)    NOT NULL,   -- derived: FirstName + ' ' + LastName
    Email               VARCHAR(255)    NOT NULL,
    Phone               VARCHAR(50)     NULL,
    AddressStreet       VARCHAR(255)    NULL,
    AddressCity         VARCHAR(100)    NULL,
    AddressState        CHAR(2)         NULL,
    Region              VARCHAR(50)     NOT NULL,   -- "North" | "South" | "East" | "West"
    RegistrationDate    DATE            NULL,
    _LoadTimestamp      DATETIME2       NOT NULL,
    CONSTRAINT PK_DimCustomer PRIMARY KEY (CustomerSK)
);

-- Lookup index used in MERGE join (business key → surrogate key)
CREATE UNIQUE INDEX IX_DimCustomer_BK
    ON gold.DimCustomer (CustomerBK);

-- Supports RLS filter pushdown on Region
CREATE INDEX IX_DimCustomer_Region
    ON gold.DimCustomer (Region)
    INCLUDE (CustomerSK);
