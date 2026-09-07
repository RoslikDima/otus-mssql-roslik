-- 6. Все ид и имена клиентов и их контактные телефоны, которые покупали товар Chocolate frogs 250g 
SELECT DISTINCT
    c.CustomerID,
    c.CustomerName,
    c.PhoneNumber
FROM Sales.Customers AS c
JOIN Sales.Orders AS o ON c.CustomerID = o.CustomerID
JOIN Sales.OrderLines AS ol ON o.OrderID = ol.OrderID
JOIN Warehouse.StockItems AS si ON ol.StockItemID = si.StockItemID
WHERE si.StockItemName = 'Chocolate frogs 250g';


SELECT 
    fk.name AS ForeignKeyName,
    tp.name AS ParentTable,
    cp.name AS ParentColumn,
    tr.name AS ReferencedTable,
    cr.name AS ReferencedColumn
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.tables AS tp ON fkc.parent_object_id = tp.object_id
INNER JOIN sys.tables AS tr ON fkc.referenced_object_id = tr.object_id
INNER JOIN sys.columns AS cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
INNER JOIN sys.columns AS cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
WHERE tp.name = 'Orders' OR tr.name = 'Orders'; -- Подставьте имя вашей таблицы


--SELECT 
--    fk.name AS [Название FK],
--    tp.name AS [Дочерняя таблица (Где FK)],
--    cp.name AS [Колонка с FK],
--    tr.name AS [Родительская таблица (На кого ссылается)],
--    cr.name AS [Главная колонка (PK)]
--FROM sys.foreign_keys AS fk
--INNER JOIN sys.foreign_key_columns AS fkc 
--    ON fk.object_id = fkc.constraint_object_id
--INNER JOIN sys.tables AS tp 
--    ON fkc.parent_object_id = tp.object_id
--INNER JOIN sys.tables AS tr 
--    ON fkc.referenced_object_id = tr.object_id
--INNER JOIN sys.columns AS cp 
--    ON fkc.parent_object_id = cp.object_id 
--    AND fkc.parent_column_id = cp.column_id
--INNER JOIN sys.columns AS cr 
--    ON fkc.referenced_object_id = cr.object_id 
--    AND fkc.referenced_column_id = cr.column_id
--ORDER BY [Дочерняя таблица (Где FK)];