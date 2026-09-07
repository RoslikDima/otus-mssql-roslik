-- 1. Все товары, в которых в название есть пометка urgent или название начинается с Animal
use [WideWorldImporters];

SELECT 
    StockItemID, 
    StockItemName, 
    UnitPrice
FROM Warehouse.StockItems
WHERE StockItemName LIKE '%urgent%' 
   OR StockItemName LIKE 'Animal%';

--SELECT 
--	StockItemID, 
--    StockItemName, 
--    UnitPrice
--FROM Warehouse.StockItems AS si
--JOIN (VALUES ('%urgent%'), ('Animal%')) AS patterns(p)
--  ON si.StockItemName LIKE patterns.p; 

--SELECT 
--	StockItemID, 
--    StockItemName, 
--    UnitPrice
--FROM Warehouse.StockItems AS si
--WHERE EXISTS (
--    SELECT 1 
--    FROM (VALUES ('%urgent%'), ('Animal%')) AS patterns(p)
--    WHERE si.StockItemName LIKE patterns.p
--);

