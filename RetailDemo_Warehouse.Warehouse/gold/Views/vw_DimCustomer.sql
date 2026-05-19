-- Auto Generated (Do not modify) 3C6B730EEAD3511F18F70ABC5F1341E2A7B4E95AC837A786E51B1495000A8822
CREATE   VIEW gold.vw_DimCustomer AS
SELECT
    c.CustomerSK,
    c.CustomerBK        AS CustomerID,
    c.FirstName,
    c.LastName,
    c.FullName,
    c.Email,
    c.Phone,
    c.AddressStreet,
    c.AddressCity,
    c.AddressState,
    c.Region,
    c.RegistrationDate
FROM gold.DimCustomer AS c;