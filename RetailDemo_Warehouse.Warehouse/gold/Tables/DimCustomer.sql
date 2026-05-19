CREATE TABLE [gold].[DimCustomer] (

	[CustomerSK] bigint IDENTITY NOT NULL, 
	[CustomerBK] int NOT NULL, 
	[FirstName] varchar(100) NOT NULL, 
	[LastName] varchar(100) NOT NULL, 
	[FullName] varchar(200) NOT NULL, 
	[Email] varchar(255) NOT NULL, 
	[Phone] varchar(50) NULL, 
	[AddressStreet] varchar(255) NULL, 
	[AddressCity] varchar(100) NULL, 
	[AddressState] char(2) NULL, 
	[Region] varchar(50) NOT NULL, 
	[RegistrationDate] date NULL, 
	[_LoadTimestamp] datetime2(6) NOT NULL
);