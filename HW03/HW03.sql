--1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
SELECT 
    DATETRUNC(month, o.[OrderDate])     AS [SalesMonth],
    AVG(ol.[UnitPrice])                 AS [AvgUnitPrice],
    SUM(ol.[Quantity] * ol.[UnitPrice]) AS [TotalOrderAmount]
FROM [Sales].[Orders] AS o
INNER JOIN [Sales].[OrderLines] AS ol 
    ON o.[OrderID] = ol.[OrderID]
GROUP BY 
    DATETRUNC(month, o.[OrderDate])
ORDER BY 
    [SalesMonth];


--2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000.
SELECT 
    DATETRUNC(month, o.[OrderDate])     AS [SalesMonth],
    SUM(ol.[Quantity] * ol.[UnitPrice]) AS [TotalOrderAmount]
FROM [Sales].[Orders] AS o
INNER JOIN [Sales].[OrderLines] AS ol 
    ON o.[OrderID] = ol.[OrderID]
GROUP BY 
    DATETRUNC(month, o.[OrderDate])
HAVING 
    SUM(ol.[Quantity] * ol.[UnitPrice]) > 4600000
ORDER BY 
    [SalesMonth];


--3. Вывести сумму продаж, дату первой продажи и количество проданного по месяцам, по товарам, продажи которых менее 50 ед в месяц. 
-- Группировка должна быть по году, месяцу, товару.
SELECT 
    YEAR(o.[OrderDate])                    AS [SalesYear],
    MONTH(o.[OrderDate])                   AS [SalesMonth],
    ol.[StockItemID],
    ol.[Description]                       AS [StockItemName],
    SUM(ol.[Quantity] * ol.[UnitPrice])    AS [TotalSalesAmount],
    MIN(o.[OrderDate])                     AS [FirstSaleDate],
    SUM(ol.[Quantity])                     AS [TotalQuantity]
FROM [Sales].[Orders] AS o
INNER JOIN [Sales].[OrderLines] AS ol 
    ON o.[OrderID] = ol.[OrderID]
GROUP BY 
    YEAR(o.[OrderDate]),
    MONTH(o.[OrderDate]),
    ol.[StockItemID],
    ol.[Description]
HAVING 
    SUM(ol.[Quantity]) < 50
ORDER BY 
    [SalesYear],
    [SalesMonth],
    ol.[StockItemID];