CREATE TABLE [gold].[DimStore] (

	[StoreSK] bigint IDENTITY NOT NULL, 
	[StoreBK] int NOT NULL, 
	[StoreName] varchar(100) NOT NULL, 
	[Region] varchar(50) NOT NULL, 
	[City] varchar(100) NULL, 
	[State] char(2) NULL, 
	[Manager] varchar(100) NULL, 
	[OpenDate] date NULL, 
	[_LoadTimestamp] datetime2(6) NOT NULL
);