-- =============================================================================
-- 01_dim_date.sql
-- Date dimension covering 2023-01-01 → 2025-12-31.
-- DateKey uses YYYYMMDD integer format (e.g. 20230115) so it joins cleanly
-- to OrderDateKey in FactSales without a type conversion.
-- Populated by 07_populate_dim_date.sql.
-- =============================================================================

CREATE TABLE gold.DimDate (
    DateKey         INT             NOT NULL,   -- YYYYMMDD, e.g. 20230115
    FullDate        DATE            NOT NULL,
    DayOfWeek       TINYINT         NOT NULL,   -- 1=Sunday … 7=Saturday (DATEPART default)
    DayName         VARCHAR(10)     NOT NULL,   -- "Monday", "Tuesday" …
    DayOfMonth      TINYINT         NOT NULL,   -- 1–31
    DayOfYear       SMALLINT        NOT NULL,   -- 1–366
    WeekOfYear      TINYINT         NOT NULL,   -- ISO week number 1–53
    MonthNumber     TINYINT         NOT NULL,   -- 1–12
    MonthName       VARCHAR(10)     NOT NULL,   -- "January" …
    MonthShort      CHAR(3)         NOT NULL,   -- "Jan" …
    Quarter         TINYINT         NOT NULL,   -- 1–4
    QuarterName     VARCHAR(6)      NOT NULL,   -- "Q1" … "Q4"
    YearNumber      SMALLINT        NOT NULL,   -- e.g. 2024
    IsWeekend       BIT             NOT NULL,   -- 1 if Saturday or Sunday
    CONSTRAINT PK_DimDate PRIMARY KEY (DateKey)
);

-- Covering index on FullDate for any date-range filters
CREATE INDEX IX_DimDate_FullDate
    ON gold.DimDate (FullDate);

-- Index to support YTD / monthly aggregations in DAX
CREATE INDEX IX_DimDate_YearMonth
    ON gold.DimDate (YearNumber, MonthNumber, DateKey);
