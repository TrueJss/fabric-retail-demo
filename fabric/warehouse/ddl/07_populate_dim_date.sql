-- =============================================================================
-- 07_populate_dim_date.sql
-- Populates gold.DimDate with one row per calendar day: 2023-01-01 → 2025-12-31
-- (1,096 rows).
--
-- Fabric Warehouse does not support recursive CTEs. The date spine is generated
-- using a CROSS JOIN numbers approach: four VALUE sets multiplied together
-- produce integers 0–1999, which are filtered down to the exact day range
-- and added to the start date.
-- =============================================================================

TRUNCATE TABLE gold.DimDate;

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
FROM (
    SELECT
        DATEADD(
            DAY,
            a.n + (b.n * 10) + (c.n * 100) + (d.n * 1000),
            CAST('2023-01-01' AS DATE)
        ) AS FullDate
    FROM
        (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS a(n)
    CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS b(n)
    CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS c(n)
    CROSS JOIN (VALUES (0),(1)) AS d(n)
    WHERE
        a.n + (b.n * 10) + (c.n * 100) + (d.n * 1000)
        <= DATEDIFF(DAY, '2023-01-01', '2025-12-31')
) AS dates;

-- Verify row count (expect 1096 rows)
SELECT
    COUNT(*) AS TotalDays,
    MIN(FullDate) AS FirstDate,
    MAX(FullDate) AS LastDate
FROM gold.DimDate;
