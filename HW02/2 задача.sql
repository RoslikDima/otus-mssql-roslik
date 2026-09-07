-- 2. ѕоставщиков, у которых не было сделано ни одного заказа 
-- (потом покажем как это делать через подзапрос, сейчас сделайте через JOIN)

--SELECT 
--    s.SupplierID, 
--    s.SupplierName
--FROM Purchasing.Suppliers AS s
--LEFT JOIN Purchasing.PurchaseOrders AS po ON s.SupplierID = po.SupplierID
--WHERE po.PurchaseOrderID IS NULL;

SELECT 
    s.SupplierID, 
    s.SupplierName
FROM Purchasing.Suppliers AS s
WHERE NOT EXISTS (
    SELECT 1 
    FROM Purchasing.PurchaseOrders AS po 
    WHERE po.SupplierID = s.SupplierID
);
