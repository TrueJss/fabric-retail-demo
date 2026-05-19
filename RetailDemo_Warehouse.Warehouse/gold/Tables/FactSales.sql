CREATE TABLE [gold].[FactSales] (

	[OrderBK] int NOT NULL, 
	[CustomerSK] bigint NOT NULL, 
	[ProductSK] bigint NOT NULL, 
	[StoreSK] bigint NOT NULL, 
	[OrderDateKey] int NOT NULL, 
	[Quantity] int NOT NULL, 
	[UnitPrice] decimal(10,2) NOT NULL, 
	[TotalAmount] decimal(12,2) NOT NULL, 
	[Status] varchar(20) NOT NULL, 
	[_LoadTimestamp] datetime2(6) NOT NULL
);