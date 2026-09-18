--1. Требуется написать запрос, который в результате своего выполнения
--формирует сводку по количеству покупок в разрезе клиентов и месяцев.
--В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.
WITH SourceData AS (
    SELECT 
        DATETRUNC(month, i.[InvoiceDate]) AS [SalesMonth],
        i.[CustomerID],
        i.[InvoiceID]
    FROM [Sales].[Invoices] AS i
    WHERE i.[CustomerID] IN (1, 2, 3, 4, 5, 6)
)
SELECT 
    [SalesMonth],
    ISNULL([1], 0) AS [Customer_1],
    ISNULL([2], 0) AS [Customer_2],
    ISNULL([3], 0) AS [Customer_3],
    ISNULL([4], 0) AS [Customer_4],
    ISNULL([5], 0) AS [Customer_5],
    ISNULL([6], 0) AS [Customer_6]
FROM SourceData
PIVOT (
    COUNT([InvoiceID])
    FOR [CustomerID] IN ([1], [2], [3], [4], [5], [6])
) AS pvt
ORDER BY [SalesMonth];


--2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
--вывести все адреса, которые есть в таблице, в одной колонке.

SELECT 
    c.[CustomerID],
    c.[CustomerName],
    addr.[AddressType],
    addr.[AddressValue]
FROM [Sales].[Customers] AS c
CROSS APPLY (
    VALUES 
        ('Delivery Address 1', c.[DeliveryAddressLine1]),
        ('Delivery Address 2', c.[DeliveryAddressLine2]),
        ('Postal Address 1',   c.[PostalAddressLine1]),
        ('Postal Address 2',   c.[PostalAddressLine2])
) AS addr([AddressType], [AddressValue])
WHERE c.[CustomerName] LIKE '%Tailspin Toys%'
  AND addr.[AddressValue] IS NOT NULL 
  AND addr.[AddressValue] <> '';


--3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
--Сделайте выборку ИД страны, названия и ее кода так,
--чтобы в поле с кодом был либо цифровой либо буквенный код.
SELECT 
    CountryID,
    CountryName,
    CodeType,
    CountryCode
FROM (
    -- Шаг 1: Приведение типов к единому стандарту NVARCHAR(3)
    SELECT 
        [CountryID],
        [CountryName],
        CAST([IsoNumericCode] AS NVARCHAR(3)) AS [IsoNumericCode],
        [IsoAlpha3Code]
    FROM [Application].[Countries]
) AS src
-- Шаг 2: Разворот двух колонок в одну
UNPIVOT (
    CountryCode FOR CodeType IN (
        [IsoNumericCode], 
        [IsoAlpha3Code]
    )
) AS unpvt
ORDER BY CountryID, CodeType;


--4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
--В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
SELECT 
    c.[CustomerID],
    c.[CustomerName],
    items.[StockItemID],
    items.[UnitPrice],
    items.[PurchaseDate]
FROM [Sales].[Customers] AS c

-- 1. Находим самый дорогой уникальный товар клиента
CROSS APPLY (
    SELECT TOP (1)
        il.[StockItemID],
        il.[UnitPrice],
        i.[InvoiceDate] AS [PurchaseDate]
    FROM [Sales].[Invoices] AS i
    INNER JOIN [Sales].[InvoiceLines] AS il 
        ON i.[InvoiceID] = il.[InvoiceID]
    WHERE i.[CustomerID] = c.[CustomerID]
    ORDER BY 
        il.[UnitPrice] DESC, 
        i.[InvoiceDate] DESC, 
        il.[InvoiceLineID] DESC
) AS item1

-- 2. Находим второй самый дорогой товар, исключая первый
OUTER APPLY (
    SELECT TOP (1)
        il.[StockItemID],
        il.[UnitPrice],
        i.[InvoiceDate] AS [PurchaseDate]
    FROM [Sales].[Invoices] AS i
    INNER JOIN [Sales].[InvoiceLines] AS il 
        ON i.[InvoiceID] = il.[InvoiceID]
    WHERE i.[CustomerID] = c.[CustomerID]
      AND il.[StockItemID] <> item1.[StockItemID] -- Исключаем первый товар!
    ORDER BY 
        il.[UnitPrice] DESC, 
        i.[InvoiceDate] DESC, 
        il.[InvoiceLineID] DESC
) AS item2

-- 3. Разворачиваем 2 товара из столбцов в строки (UNPIVOT через VALUES)
CROSS APPLY (
    VALUES 
        (item1.[StockItemID], item1.[UnitPrice], item1.[PurchaseDate]),
        (item2.[StockItemID], item2.[UnitPrice], item2.[PurchaseDate])
) AS items([StockItemID], [UnitPrice], [PurchaseDate])

WHERE items.[StockItemID] IS NOT NULL
ORDER BY 
    c.[CustomerID], 
    items.[UnitPrice] DESC;