-- Auto Generated (Do not modify) 91B6F604B0BD62E2C1DDF0E337D9A4AAB134B40B880282901C3F8DF850AEB849
CREATE   VIEW gold.vw_DimDate AS
SELECT
    d.DateKey,
    d.FullDate,
    d.DayOfWeek,
    d.DayName,
    d.DayOfMonth,
    d.DayOfYear,
    d.WeekOfYear,
    d.MonthNumber,
    d.MonthName,
    d.MonthShort,
    d.Quarter,
    d.QuarterName,
    d.YearNumber,
    d.IsWeekend
FROM gold.DimDate AS d;