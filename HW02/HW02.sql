-- 1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
SELECT 
    si.[StockItemID],
    si.[StockItemName],
    si.[SupplierID],
    si.[UnitPrice],
    si.[TypicalWeightPerUnit]
FROM [Warehouse].[StockItems] AS si
WHERE si.[StockItemName] LIKE N'%urgent%'
   OR si.[StockItemName] LIKE N'Animal%'
ORDER BY si.[StockItemID];


-- 2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
SELECT 
    s.[SupplierID],
    s.[SupplierName],
    s.[PhoneNumber],
    s.[SupplierReference]
FROM [Purchasing].[Suppliers] AS s
LEFT JOIN [Purchasing].[PurchaseOrders] AS po 
    ON s.[SupplierID] = po.[SupplierID]
WHERE po.[PurchaseOrderID] IS NULL
ORDER BY s.[SupplierID];


--3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ либо количеством единиц (Quantity) товара 
--более 20 штуки присутствующей датой комплектации всего заказа (PickingCompletedWhen).

SELECT 
    o.[OrderID],
    o.[OrderDate],
    o.[PickingCompletedWhen],
    ol.[Quantity],
    ol.[UnitPrice]
FROM [Sales].[Orders] AS o
INNER JOIN [Sales].[OrderLines] AS ol 
    ON o.[OrderID] = ol.[OrderID]
WHERE o.[PickingCompletedWhen] IS NOT NULL
  AND (ol.[UnitPrice] > 100 OR ol.[Quantity] > 20);

--4. Заказы поставщикам (Purchasing.Suppliers), которые должны быть исполнены (ExpectedDeliveryDate) 
-- в январе 2013 года с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName) и которые исполнены (IsOrderFinalized).
SELECT 
    po.[PurchaseOrderID],
    s.[SupplierID],
    s.[SupplierName],
    po.[OrderDate],
    po.[ExpectedDeliveryDate],
    dm.[DeliveryMethodName],
    po.[IsOrderFinalized]
FROM [Purchasing].[PurchaseOrders] AS po
INNER JOIN [Purchasing].[Suppliers] AS s 
    ON po.[SupplierID] = s.[SupplierID]
INNER JOIN [Application].[DeliveryMethods] AS dm 
    ON po.[DeliveryMethodID] = dm.[DeliveryMethodID]
WHERE po.[ExpectedDeliveryDate] >= '2013-01-01'
  AND po.[ExpectedDeliveryDate] < '2013-02-01'
  AND dm.[DeliveryMethodName] IN (N'Air Freight', N'Refrigerated Air Freight')
  AND po.[IsOrderFinalized] = 1;


--5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника, 
-- который оформил заказ (SalespersonPerson). Сделать без подзапросов.
SELECT TOP (10)
    o.[OrderID],
    o.[OrderDate],
    c.[CustomerName],
    p.[FullName] AS [SalespersonName]
FROM [Sales].[Orders] AS o
INNER JOIN [Sales].[Customers] AS c 
    ON o.[CustomerID] = c.[CustomerID]
INNER JOIN [Application].[People] AS p 
    ON o.[SalespersonPersonID] = p.[PersonID]
ORDER BY 
    o.[OrderDate] DESC;


--6. Все ид и имена клиентов и их контактные телефоны, которые покупали товар "Chocolate frogs 250g".
SELECT DISTINCT
    c.[CustomerID],
    c.[CustomerName],
    c.[PhoneNumber]
FROM [Sales].[Customers] AS c
INNER JOIN [Sales].[Orders] AS o 
    ON c.[CustomerID] = o.[CustomerID]
INNER JOIN [Sales].[OrderLines] AS ol 
    ON o.[OrderID] = ol.[OrderID]
INNER JOIN [Warehouse].[StockItems] AS si 
    ON ol.[StockItemID] = si.[StockItemID]
WHERE si.[StockItemName] = N'Chocolate frogs 250g'
ORDER BY c.[CustomerID];