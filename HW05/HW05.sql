use [WideWorldImporters];
-- 1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года
--(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
--Нарастающий итог должен быть без оконной функции.
WITH MonthlySales AS (
    SELECT 
        DATETRUNC(month, i.[InvoiceDate])   AS [SalesMonth],
        SUM(il.[Quantity] * il.[UnitPrice]) AS [MonthTotal]
    FROM [Sales].[Invoices] AS i
    INNER JOIN [Sales].[InvoiceLines] AS il 
        ON i.[InvoiceID] = il.[InvoiceID]
    WHERE i.[InvoiceDate] >= '2015-01-01'
    GROUP BY 
        DATETRUNC(month, i.[InvoiceDate])
)
SELECT 
    m1.[SalesMonth],
    m1.[MonthTotal],
    SUM(m2.[MonthTotal]) AS [RunningTotal]
FROM MonthlySales AS m1
INNER JOIN MonthlySales AS m2 
    ON m2.[SalesMonth] <= m1.[SalesMonth]
GROUP BY 
    m1.[SalesMonth],
    m1.[MonthTotal]
ORDER BY 
    m1.[SalesMonth];


-- 2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
--Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
SET STATISTICS IO, TIME ON;

WITH MonthlySales AS (
    SELECT 
        DATETRUNC(month, i.[InvoiceDate])   AS [SalesMonth],
        SUM(il.[Quantity] * il.[UnitPrice]) AS [MonthTotal]
    FROM [Sales].[Invoices] AS i
    INNER JOIN [Sales].[InvoiceLines] AS il 
        ON i.[InvoiceID] = il.[InvoiceID]
    WHERE i.[InvoiceDate] >= '2015-01-01'
    GROUP BY 
        DATETRUNC(month, i.[InvoiceDate])
)
SELECT 
    [SalesMonth],
    [MonthTotal],
    SUM([MonthTotal]) OVER (
        ORDER BY [SalesMonth]
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS [RunningTotal]
FROM MonthlySales
ORDER BY 
    [SalesMonth];

SET STATISTICS IO, TIME OFF;


-- 3. Вывести список 2х самых популярных продуктов (по количеству проданных)
--в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).

WITH MonthlyProductSales AS (
    SELECT 
        DATETRUNC(month, i.[InvoiceDate]) AS [SalesMonth],
        il.[StockItemID],
        il.[Description]                  AS [StockItemName],
        SUM(il.[Quantity])                AS [TotalQuantitySold]
    FROM [Sales].[Invoices] AS i
    INNER JOIN [Sales].[InvoiceLines] AS il 
        ON i.[InvoiceID] = il.[InvoiceID]
    WHERE i.[InvoiceDate] >= '2016-01-01'
      AND i.[InvoiceDate] < '2017-01-01'
    GROUP BY 
        DATETRUNC(month, i.[InvoiceDate]),
        il.[StockItemID],
        il.[Description]
),
RankedProducts AS (
    SELECT 
        [SalesMonth],
        [StockItemID],
        [StockItemName],
        [TotalQuantitySold],
        DENSE_RANK() OVER (
            PARTITION BY [SalesMonth] 
            ORDER BY [TotalQuantitySold] DESC
        ) AS [ItemRank]
    FROM MonthlyProductSales
)
SELECT 
    [SalesMonth],
    [ItemRank],
    [StockItemID],
    [StockItemName],
    [TotalQuantitySold]
FROM RankedProducts
WHERE [ItemRank] <= 2
ORDER BY 
    [SalesMonth], 
    [ItemRank];


-- 4. Функции одним запросом
--Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):

--пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
--посчитайте общее количество товаров и выведете полем в этом же запросе
--посчитайте общее количество товаров в зависимости от первой буквы названия товара
--отобразите следующий id товара исходя из того, что порядок отображения товаров по имени
--предыдущий ид товара с тем же порядком отображения (по имени)
--названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
--сформируйте 30 групп товаров по полю вес товара на 1 шт

--Для этой задачи НЕ нужно писать аналог без аналитических функций.
SELECT 
    -- 1. Основные поля товара
    si.[StockItemID],
    si.[StockItemName],
    si.[Brand],
    si.[UnitPrice],
    si.[TypicalWeightPerUnit],

    -- 2. Нумерация по названию с перезапуском при смене первой буквы алфавита
    ROW_NUMBER() OVER (
        PARTITION BY LEFT(si.[StockItemName], 1) 
        ORDER BY si.[StockItemName]
    ) AS [RowNumByFirstLetter],

    -- 3. Общее количество товаров во всей таблице
    COUNT(*) OVER () AS [TotalItemsCount],

    -- 4. Общее количество товаров с той же первой буквой названия
    COUNT(*) OVER (
        PARTITION BY LEFT(si.[StockItemName], 1)
    ) AS [ItemsCountByFirstLetter],

    -- 5. Следующий ID товара (по порядку имени)
    LEAD(si.[StockItemID], 1) OVER (
        ORDER BY si.[StockItemName]
    ) AS [NextStockItemID],

    -- 6. Предыдущий ID товара (по порядку имени)
    LAG(si.[StockItemID], 1) OVER (
        ORDER BY si.[StockItemName]
    ) AS [PrevStockItemID],

    -- 7. Название товара 2 строки назад (если строки нет — 'No items')
    LAG(si.[StockItemName], 2, N'No items') OVER (
        ORDER BY si.[StockItemName]
    ) AS [StockItemNameLag2],

    -- 8. Разбиение на 30 групп по весу единицы товара (TypicalWeightPerUnit)
    NTILE(30) OVER (
        ORDER BY si.[TypicalWeightPerUnit]
    ) AS [WeightGroup30]

FROM [Warehouse].[StockItems] AS si
ORDER BY 
    si.[StockItemName];

-- 5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
--В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
WITH InvoiceTotals AS (
    -- 1. Считаем итоговую сумму каждого инвойса
    SELECT 
        il.[InvoiceID],
        SUM(il.[Quantity] * il.[UnitPrice]) AS [TransactionAmount]
    FROM [Sales].[InvoiceLines] AS il
    GROUP BY il.[InvoiceID]
),
RankedSales AS (
    -- 2. Ранжируем продажи каждого сотрудника от самых свежих к старым
    SELECT 
        i.[SalespersonPersonID],
        i.[CustomerID],
        i.[InvoiceDate],
        it.[TransactionAmount],
        ROW_NUMBER() OVER (
            PARTITION BY i.[SalespersonPersonID]
            ORDER BY i.[InvoiceDate] DESC, i.[InvoiceID] DESC
        ) AS [SaleRank]
    FROM [Sales].[Invoices] AS i
    INNER JOIN InvoiceTotals AS it 
        ON i.[InvoiceID] = it.[InvoiceID]
)
-- 3. Выбираем последнюю сделку (SaleRank = 1) и подтягиваем имена
SELECT 
    p.[PersonID]     AS [SalespersonPersonID],
    p.[FullName]     AS [SalespersonName],
    c.[CustomerID],
    c.[CustomerName],
    rs.[InvoiceDate] AS [SaleDate],
    rs.[TransactionAmount]
FROM RankedSales AS rs
INNER JOIN [Application].[People] AS p 
    ON rs.[SalespersonPersonID] = p.[PersonID]
INNER JOIN [Sales].[Customers] AS c 
    ON rs.[CustomerID] = c.[CustomerID]
WHERE rs.[SaleRank] = 1
ORDER BY p.[PersonID];

-- 6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
--В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
WITH CustomerItemPurchases AS (
    -- 1. Находим для каждого клиента и товара максимальную цену покупки и последнюю дату
    SELECT 
        i.[CustomerID],
        il.[StockItemID],
        MAX(il.[UnitPrice])   AS [UnitPrice],
        MAX(i.[InvoiceDate])  AS [PurchaseDate]
    FROM [Sales].[Invoices] AS i
    INNER JOIN [Sales].[InvoiceLines] AS il 
        ON i.[InvoiceID] = il.[InvoiceID]
    GROUP BY 
        i.[CustomerID],
        il.[StockItemID]
),
RankedCustomerItems AS (
    -- 2. Ранжируем товары внутри каждого клиента по убыванию цены
    SELECT 
        cip.[CustomerID],
        cip.[StockItemID],
        cip.[UnitPrice],
        cip.[PurchaseDate],
        ROW_NUMBER() OVER (
            PARTITION BY cip.[CustomerID]
            ORDER BY cip.[UnitPrice] DESC, cip.[StockItemID] ASC
        ) AS [ItemPriceRank]
    FROM CustomerItemPurchases AS cip
)
-- 3. Выбираем топ-2 дорогих товара и подтягиваем имя клиента
SELECT 
    c.[CustomerID],
    c.[CustomerName],
    rci.[StockItemID],
    rci.[UnitPrice],
    rci.[PurchaseDate]
FROM RankedCustomerItems AS rci
INNER JOIN [Sales].[Customers] AS c 
    ON rci.[CustomerID] = c.[CustomerID]
WHERE rci.[ItemPriceRank] <= 2
ORDER BY 
    c.[CustomerID], 
    rci.[ItemPriceRank];