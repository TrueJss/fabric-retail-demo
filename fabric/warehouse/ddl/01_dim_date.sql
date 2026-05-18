-- =============================================================================
-- 01_dim_date.sql
-- Note: PRIMARY KEY constraints are not supported inline in Fabric Warehouse
-- CREATE TABLE statements. Uniqueness enforced via CREATE UNIQUE INDEX.
-- =============================================================================

CREATE TABLE gold.DimDate (
    DateKey         INT             NOT NULL,
    FullDate        DATE            NOT NULL,
    DayOfWeek       INT             NOT NULL,
    DayName         VARCHAR(10)     NOT NULL,
    DayOfMonth      INT             NOT NULL,
    DayOfYear       INT             NOT NULL,
    WeekOfYear      INT             NOT NULL,
    MonthNumber     INT             NOT NULL,
    MonthName       VARCHAR(10)     NOT NULL,
    MonthShort      CHAR(3)         NOT NULL,
    Quarter         INT             NOT NULL,
    QuarterName     VARCHAR(6)      NOT NULL,
    YearNumber      INT             NOT NULL,
    IsWeekend       BIT             NOT NULL
);
