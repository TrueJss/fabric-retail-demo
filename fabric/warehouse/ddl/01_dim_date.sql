-- =============================================================================
-- 01_dim_date.sql
-- Note: PRIMARY KEY constraints are not supported inline in Fabric Warehouse
-- CREATE TABLE statements. Uniqueness enforced via CREATE UNIQUE INDEX.
-- =============================================================================

CREATE TABLE gold.DimDate (
    DateKey         INT             NOT NULL,
    FullDate        DATE            NOT NULL,
    DayOfWeek       TINYINT         NOT NULL,
    DayName         VARCHAR(10)     NOT NULL,
    DayOfMonth      TINYINT         NOT NULL,
    DayOfYear       SMALLINT        NOT NULL,
    WeekOfYear      TINYINT         NOT NULL,
    MonthNumber     TINYINT         NOT NULL,
    MonthName       VARCHAR(10)     NOT NULL,
    MonthShort      CHAR(3)         NOT NULL,
    Quarter         TINYINT         NOT NULL,
    QuarterName     VARCHAR(6)      NOT NULL,
    YearNumber      SMALLINT        NOT NULL,
    IsWeekend       BIT             NOT NULL
);

CREATE UNIQUE INDEX IX_DimDate_PK
    ON gold.DimDate (DateKey);

CREATE INDEX IX_DimDate_FullDate
    ON gold.DimDate (FullDate);

CREATE INDEX IX_DimDate_YearMonth
    ON gold.DimDate (YearNumber, MonthNumber, DateKey);
