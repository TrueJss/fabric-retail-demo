CREATE TABLE [gold].[DimProduct] (

	[ProductSK] bigint IDENTITY NOT NULL, 
	[ProductBK] int NOT NULL, 
	[CategoryID] int NOT NULL, 
	[CategoryName] varchar(100) NOT NULL, 
	[ProductName] varchar(255) NOT NULL, 
	[CostPrice] decimal(10,2) NOT NULL, 
	[RetailPrice] decimal(10,2) NOT NULL, 
	[MarginPct] decimal(5,2) NULL, 
	[_LoadTimestamp] datetime2(6) NOT NULL
);