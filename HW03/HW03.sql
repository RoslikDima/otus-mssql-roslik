-- 1 Все товары, в названии которых есть "urgent" или название начинается с "Animal".
SELECT 
    StockItemName
FROM Warehouse.StockItems
WHERE StockItemName LIKE '%urgent%' 
   OR StockItemName LIKE 'Animal%';

-- 2 Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
SELECT 
    s.SupplierID, 
    s.SupplierName
FROM Purchasing.Suppliers AS s
WHERE NOT EXISTS (
    SELECT 1 
    FROM Purchasing.PurchaseOrders AS po 
    WHERE po.SupplierID = s.SupplierID
);

-- 3 Заказы (Orders) с ценой товара (UnitPrice) более 100$ либо количеством единиц (Quantity) 
-- товара более 20 штуки присутствующей датой комплектации всего заказа (PickingCompletedWhen).
select
	o.OrderDate,
	o.OrderDate,
	o.PickingCompletedWhen,
	ol.Description as ItemDescription,
	ol.UnitPrice,
	ol.Quantity
from [Sales].[Orders] as o
inner join [Sales].[OrderLines] as ol on o.OrderID = ol.OrderID
where o.PickingCompletedWhen is not null      -- присутствующей датой комплектации всего заказа (PickingCompletedWhen).
and (ol.UnitPrice > 100 or ol.Quantity > 20); -- (UnitPrice) > 100$ ИЛИ (Quantity) > 20 штуки

-- Заказы поставщикам (Purchasing.Suppliers), которые должны быть исполнены (ExpectedDeliveryDate) 
-- в январе 2013 года с доставкой "Air Freight" 
-- или "Refrigerated Air Freight" (DeliveryMethodName) и которые исполнены (IsOrderFinalized).
SELECT 
    s.SupplierName,
    po.PurchaseOrderID,
    po.ExpectedDeliveryDate,
    dm.DeliveryMethodName,
    po.IsOrderFinalized
FROM Purchasing.Suppliers AS s
JOIN Purchasing.PurchaseOrders AS po ON s.SupplierID = po.SupplierID
JOIN Application.DeliveryMethods AS dm ON po.DeliveryMethodID = dm.DeliveryMethodID
WHERE po.ExpectedDeliveryDate BETWEEN '2013-01-01' AND '2013-01-31'  -- Январь 2013
  AND dm.DeliveryMethodName IN ('Air Freight', 'Refrigerated Air Freight') -- Способы доставки
  AND po.IsOrderFinalized = 1;                                        -- Заказ исполнен




----
SELECT 
    obj.name AS FK_Name,
    sch.name AS SchemaName,
    tab1.name AS TableName,
    col1.name AS ColumnName,
    tab2.name AS ReferencedTableName,
    col2.name AS ReferencedColumnName
FROM sys.foreign_key_columns fkc
INNER JOIN sys.foreign_keys obj ON obj.object_id = fkc.constraint_object_id
INNER JOIN sys.tables tab1 ON tab1.object_id = fkc.parent_object_id
INNER JOIN sys.schemas sch ON tab1.schema_id = sch.schema_id
INNER JOIN sys.columns col1 ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
INNER JOIN sys.tables tab2 ON tab2.object_id = fkc.referenced_object_id
INNER JOIN sys.columns col2 ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id
WHERE tab1.name = 'PurchaseOrders' AND tab2.name = 'Suppliers';
-- WHERE tab1.name IN ('Suppliers', 'PurchaseOrders') 
-- OR tab2.name IN ('Suppliers', 'PurchaseOrders');
---


