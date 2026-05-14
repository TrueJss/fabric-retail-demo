-- =============================================================================
-- 07_populate_dim_date.sql
-- Populates gold.DimDate with one row per calendar day: 2023-01-01 → 2025-12-31.
-- Run once after 01_dim_date.sql. Re-runnable: TRUNCATE clears existing rows
-- before re-inserting, so safe to execute multiple times.
--
-- MAXRECURSION is set to 1100 (covers ~3 years of daily rows with headroom).
-- =============================================================================

TRUNCATE TABLE gold.DimDate;

WITH DateCTE AS (
    SELECT CAST('2023-01-01' AS DATE) AS FullDate
    UNION ALL
    SELECT DATEADD(DAY, 1, FullDate)
    FROM DateCTE
    WHERE FullDate < '2025-12-31'
)

INSERT INTO gold.DimDate (
    DateKey,
    FullDate,
    DayOfWeek,
    DayName,
    DayOfMonth,
    DayOfYear,
    WeekOfYear,
    MonthNumber,
    MonthName,
    MonthShort,
    Quarter,
    QuarterName,
    YearNumber,
    IsWeekend
)
SELECT
    CAST(CONVERT(VARCHAR(8), FullDate, 112) AS INT) AS DateKey,
    FullDate,
    DATEPART(WEEKDAY, FullDate) AS DayOfWeek,
    DATENAME(WEEKDAY, FullDate) AS DayName,
    DATEPART(DAY, FullDate) AS DayOfMonth,
    DATEPART(DAYOFYEAR, FullDate) AS DayOfYear,
    DATEPART(WEEK, FullDate) AS WeekOfYear,
    DATEPART(MONTH, FullDate) AS MonthNumber,
    DATENAME(MONTH, FullDate) AS MonthName,
    LEFT(DATENAME(MONTH, FullDate), 3) AS MonthShort,
    DATEPART(QUARTER, FullDate) AS Quarter,
    CONCAT('Q', DATEPART(QUARTER, FullDate)) AS QuarterName,
    DATEPART(YEAR, FullDate) AS YearNumber,
    CASE
        WHEN DATEPART(WEEKDAY, FullDate) IN (1, 7) THEN 1
        ELSE 0
    END AS IsWeekend
FROM DateCTE
OPTION (MAXRECURSION 1100);

-- Verify row count (expect 1096 rows for 2023-01-01 → 2025-12-31)
SELECT
    COUNT(*)                        AS TotalDays,
    MIN(FullDate)                   AS FirstDate,
    MAX(FullDate)                   AS LastDate,
    SUM(CAST(IsWeekend AS INT))     AS WeekendDays
FROM gold.DimDate;
