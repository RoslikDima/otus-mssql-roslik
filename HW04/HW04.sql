-- 1.Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
-- и не сделали ни одной продажи 04 июля 2015 года. Вывести ИД сотрудника и его полное имя. 
-- Продажи смотреть в таблице Sales.Invoices.

-- 
SELECT 
    p.[PersonID],
    p.[FullName]
FROM [Application].[People] AS p
WHERE p.[IsSalesperson] = 1
  AND NOT EXISTS (
      SELECT 1
      FROM [Sales].[Invoices] AS i
      WHERE i.[SalespersonPersonID] = p.[PersonID]
        AND i.[InvoiceDate] = '2015-07-04'
  )
ORDER BY p.[PersonID];

-- 
WITH SalesOnDate AS (
    SELECT DISTINCT [SalespersonPersonID]
    FROM [Sales].[Invoices]
    WHERE [InvoiceDate] = '2015-07-04'
)
SELECT 
    p.[PersonID],
    p.[FullName]
FROM [Application].[People] AS p
LEFT JOIN SalesOnDate AS sod 
    ON p.[PersonID] = sod.[SalespersonPersonID]
WHERE p.[IsSalesperson] = 1
  AND sod.[SalespersonPersonID] IS NULL
ORDER BY p.[PersonID];


-- 2.Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. Вывести: ИД товара, наименование товара, цена.
--
SELECT 
    si.[StockItemID],
    si.[StockItemName],
    si.[UnitPrice]
FROM [Warehouse].[StockItems] AS si
WHERE si.[UnitPrice] = (
    SELECT MIN([UnitPrice]) 
    FROM [Warehouse].[StockItems]
);

-- 
WITH RankedStockItems AS (
    SELECT 
        [StockItemID],
        [StockItemName],
        [UnitPrice],
        DENSE_RANK() OVER (ORDER BY [UnitPrice] ASC) AS [PriceRank]
    FROM [Warehouse].[StockItems]
)
SELECT 
    [StockItemID],
    [StockItemName],
    [UnitPrice]
FROM RankedStockItems
WHERE [PriceRank] = 1;

-- 3.Выберите информацию по клиентам, которые перевели компании пять максимальных платежей из Sales.CustomerTransactions. 
-- Представьте несколько способов (в том числе с CTE).
--
SELECT 
    c.[CustomerID],
    c.[CustomerName],
    c.[PhoneNumber],
    top_trans.[CustomerTransactionID],
    top_trans.[TransactionDate],
    top_trans.[TransactionAmount]
FROM (
    SELECT TOP (5) 
        [CustomerTransactionID],
        [CustomerID],
        [TransactionDate],
        [TransactionAmount]
    FROM [Sales].[CustomerTransactions]
    ORDER BY [TransactionAmount] DESC
) AS top_trans
INNER JOIN [Sales].[Customers] AS c 
    ON top_trans.[CustomerID] = c.[CustomerID]
ORDER BY top_trans.[TransactionAmount] DESC;

-- 
WITH RankedTransactions AS (
    SELECT 
        [CustomerTransactionID],
        [CustomerID],
        [TransactionDate],
        [TransactionAmount],
        ROW_NUMBER() OVER (ORDER BY [TransactionAmount] DESC) AS [RankNum]
    FROM [Sales].[CustomerTransactions]
)
SELECT 
    c.[CustomerID],
    c.[CustomerName],
    c.[PhoneNumber],
    rt.[CustomerTransactionID],
    rt.[TransactionDate],
    rt.[TransactionAmount]
FROM RankedTransactions AS rt
INNER JOIN [Sales].[Customers] AS c 
    ON rt.[CustomerID] = c.[CustomerID]
WHERE rt.[RankNum] <= 5
ORDER BY rt.[TransactionAmount] DESC;

-- 4.Выберите города (ид и название), в которые были доставлены товары, входящие в тройку самых дорогих товаров, 
-- а также имя сотрудника, который осуществлял упаковку заказов (PackedByPersonID).

-- 
SELECT DISTINCT
    city.[CityID],
    city.[CityName],
    packer.[FullName] AS [PackedByPersonName]
FROM [Sales].[Invoices] AS i
INNER JOIN [Sales].[InvoiceLines] AS il 
    ON i.[InvoiceID] = il.[InvoiceID]
INNER JOIN [Sales].[Customers] AS c 
    ON i.[CustomerID] = c.[CustomerID]
INNER JOIN [Application].[Cities] AS city 
    ON c.[DeliveryCityID] = city.[CityID]
INNER JOIN [Application].[People] AS packer 
    ON i.[PackedByPersonID] = packer.[PersonID]
WHERE il.[StockItemID] IN (
    SELECT TOP (3) [StockItemID]
    FROM [Warehouse].[StockItems]
    ORDER BY [UnitPrice] DESC
)
ORDER BY city.[CityName], packer.[FullName];

--
WITH Top3ExpensiveItems AS (
    SELECT TOP (3) 
        [StockItemID],
        [StockItemName],
        [UnitPrice]
    FROM [Warehouse].[StockItems]
    ORDER BY [UnitPrice] DESC
)
SELECT DISTINCT
    city.[CityID],
    city.[CityName],
    packer.[FullName] AS [PackedByPersonName]
FROM [Sales].[Invoices] AS i
INNER JOIN [Sales].[InvoiceLines] AS il 
    ON i.[InvoiceID] = il.[InvoiceID]
INNER JOIN Top3ExpensiveItems AS top_items 
    ON il.[StockItemID] = top_items.[StockItemID]
INNER JOIN [Sales].[Customers] AS c 
    ON i.[CustomerID] = c.[CustomerID]
INNER JOIN [Application].[Cities] AS city 
    ON c.[DeliveryCityID] = city.[CityID]
INNER JOIN [Application].[People] AS packer 
    ON i.[PackedByPersonID] = packer.[PersonID]
ORDER BY city.[CityName], packer.[FullName];


-- 5
--Что делал исходный запрос:
--Запрос формирует отчет по крупным счетам (инвойсам) с суммой продаж более 27 000 и выводит: 
--Номер и дату счета (InvoiceID, InvoiceDate).
-- Имя продавца (SalesPersonName), оформившего счет.
-- Общую сумму по счету (TotalSummByInvoice), рассчитанную как sum (Quantity * UnitPrice}) по строкам инвойса (Sales.InvoiceLines).
--Сумму по фактически собранным позициям исходного заказа (TotalSummForPickedItems), 
--рассчитанную как sum (PickedQuantity * UnitPrice) по строкам заказа (Sales.OrderLines), 
--но только если заказ был полностью укомплектован (PickingCompletedWhen IS NOT NULL). 
--Если заказ еще не собран или инвойс выставлен без привязки к собранному заказу, колонка вернет NULL.
--Результаты сортируются по убыванию суммы счета (TotalSumm DESC).


WITH LargeInvoices AS (
    -- 1. Считаем суммы инвойсов и сразу отсекаем порог > 27000
    SELECT 
        il.[InvoiceID],
        SUM(il.[Quantity] * il.[UnitPrice]) AS [TotalSumm]
    FROM [Sales].[InvoiceLines] AS il
    GROUP BY il.[InvoiceID]
    HAVING SUM(il.[Quantity] * il.[UnitPrice]) > 27000
),
PickedOrderTotals AS (
    -- 2. Считаем суммы по собранным позициям только для полностью укомплектованных заказов
    SELECT 
        ol.[OrderID],
        SUM(ol.[PickedQuantity] * ol.[UnitPrice]) AS [TotalSummForPickedItems]
    FROM [Sales].[OrderLines] AS ol
    INNER JOIN [Sales].[Orders] AS o 
        ON ol.[OrderID] = o.[OrderID]
    WHERE o.[PickingCompletedWhen] IS NOT NULL
    GROUP BY ol.[OrderID]
)
SELECT 
    i.[InvoiceID],
    i.[InvoiceDate],
    p.[FullName] AS [SalesPersonName],
    li.[TotalSumm] AS [TotalSummByInvoice],
    pot.[TotalSummForPickedItems]
FROM [Sales].[Invoices] AS i
INNER JOIN LargeInvoices AS li 
    ON i.[InvoiceID] = li.[InvoiceID]
INNER JOIN [Application].[People] AS p 
    ON i.[SalespersonPersonID] = p.[PersonID]
LEFT JOIN PickedOrderTotals AS pot 
    ON i.[OrderID] = pot.[OrderID]
ORDER BY 
    li.[TotalSumm] DESC;