CREATE TABLE [gold].[DimDate] (

	[DateKey] int NOT NULL, 
	[FullDate] date NOT NULL, 
	[DayOfWeek] int NOT NULL, 
	[DayName] varchar(10) NOT NULL, 
	[DayOfMonth] int NOT NULL, 
	[DayOfYear] int NOT NULL, 
	[WeekOfYear] int NOT NULL, 
	[MonthNumber] int NOT NULL, 
	[MonthName] varchar(10) NOT NULL, 
	[MonthShort] char(3) NOT NULL, 
	[Quarter] int NOT NULL, 
	[QuarterName] varchar(6) NOT NULL, 
	[YearNumber] int NOT NULL, 
	[IsWeekend] bit NOT NULL
);