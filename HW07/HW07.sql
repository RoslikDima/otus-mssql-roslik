DECLARE 
    @ColumnListPivot NVARCHAR(MAX),
    @ColumnListSelect NVARCHAR(MAX),
    @Sql NVARCHAR(MAX);

-- 1. Формируем списки колонок по всем клиентам, у которых были покупки
-- (либо по всей таблице Sales.Customers, если нужны даже клиенты без истории)
SELECT 
    -- Список для блока PIVOT: [Customer 1], [Customer 2], ...
    @ColumnListPivot = STRING_AGG(CAST(QUOTENAME(c.[CustomerName]) AS NVARCHAR(MAX)), N', ') 
                       WITHIN GROUP (ORDER BY c.[CustomerName]),
    
    -- Список для блока SELECT: ISNULL([Customer 1], 0) AS [Customer 1], ...
    @ColumnListSelect = STRING_AGG(CAST(N'ISNULL(' + QUOTENAME(c.[CustomerName]) + N', 0) AS ' + QUOTENAME(c.[CustomerName]) AS NVARCHAR(MAX)), N', ' + CHAR(13) + CHAR(10) + N'       ') 
                        WITHIN GROUP (ORDER BY c.[CustomerName])
FROM [Sales].[Customers] AS c
WHERE EXISTS (
    SELECT 1 
    FROM [Sales].[Invoices] AS i 
    WHERE i.[CustomerID] = c.[CustomerID]
);

-- 2. Собираем итоговый динамический запрос
SET @Sql = N'
WITH SourceData AS (
    SELECT 
        DATETRUNC(month, i.[InvoiceDate]) AS [SalesMonth],
        c.[CustomerName],
        i.[InvoiceID]
    FROM [Sales].[Invoices] AS i
    INNER JOIN [Sales].[Customers] AS c 
        ON i.[CustomerID] = c.[CustomerID]
)
SELECT 
    [SalesMonth],
    ' + @ColumnListSelect + N'
FROM SourceData
PIVOT (
    COUNT([InvoiceID])
    FOR [CustomerName] IN (' + @ColumnListPivot + N')
) AS pvt
ORDER BY [SalesMonth];';

-- 3. Безопасное выполнение
EXEC sys.sp_executesql @stmt = @Sql;