--Описание/Пошаговая инструкция выполнения домашнего задания:
--1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers
USE WideWorldImporters;
GO

INSERT INTO [Sales].[Customers]
(
    [CustomerID],
    [CustomerName],
    [BillToCustomerID],
    [CustomerCategoryID],
    [PrimaryContactPersonID],
    [DeliveryMethodID],
    [DeliveryCityID],
    [PostalCityID],
    [CreditLimit],
    [AccountOpenedDate],
    [StandardDiscountPercentage],
    [IsStatementSent],
    [IsOnCreditHold],
    [PaymentDays],
    [PhoneNumber],
    [FaxNumber],
    [WebsiteURL],
    [DeliveryAddressLine1],
    [DeliveryPostalCode],
    [PostalAddressLine1],
    [PostalPostalCode],
    [LastEditedBy]
)
VALUES
(NEXT VALUE FOR Sequences.CustomerID, N'Test Client Alpha', 1, 3, 1001, 3, 19586, 19586, 5000.00, CAST(GETDATE() AS DATE), 0.000, 0, 0, 7, N'(206) 555-0101', N'(206) 555-0102', N'http://alpha.example.com', N'Suite 100', N'98101', N'PO Box 100', N'98101', 1),
(NEXT VALUE FOR Sequences.CustomerID, N'Test Client Beta',  1, 3, 1001, 3, 19586, 19586, 6000.00, CAST(GETDATE() AS DATE), 0.000, 0, 0, 7, N'(206) 555-0103', N'(206) 555-0104', N'http://beta.example.com',  N'Suite 200', N'98101', N'PO Box 200', N'98101', 1),
(NEXT VALUE FOR Sequences.CustomerID, N'Test Client Gamma', 1, 3, 1001, 3, 19586, 19586, 7000.00, CAST(GETDATE() AS DATE), 0.000, 0, 0, 7, N'(206) 555-0105', N'(206) 555-0106', N'http://gamma.example.com', N'Suite 300', N'98101', N'PO Box 300', N'98101', 1),
(NEXT VALUE FOR Sequences.CustomerID, N'Test Client Delta', 1, 3, 1001, 3, 19586, 19586, 8000.00, CAST(GETDATE() AS DATE), 0.000, 0, 0, 7, N'(206) 555-0107', N'(206) 555-0108', N'http://delta.example.com', N'Suite 400', N'98101', N'PO Box 400', N'98101', 1),
(NEXT VALUE FOR Sequences.CustomerID, N'Test Client Epsilon', 1, 3, 1001, 3, 19586, 19586, 9000.00, CAST(GETDATE() AS DATE), 0.000, 0, 0, 7, N'(206) 555-0109', N'(206) 555-0110', N'http://epsilon.example.com', N'Suite 500', N'98101', N'PO Box 500', N'98101', 1);
GO

-- Проверяем результат вставки
SELECT 
    CustomerID, 
    CustomerName, 
    CreditLimit, 
    PhoneNumber
FROM [Sales].[Customers]
WHERE CustomerName LIKE N'Test Client%';
GO

--2. Удалите одну запись из Customers, которая была вами добавлена
DELETE FROM [Sales].[Customers]
WHERE [CustomerName] = N'Test Client Epsilon';
GO

-- Проверяем: строки с Epsilon больше нет
SELECT CustomerID, CustomerName 
FROM [Sales].[Customers]
WHERE [CustomerName] = N'Test Client Epsilon';
GO

--3. Изменить одну запись, из добавленных через UPDATE
UPDATE [Sales].[Customers]
SET 
    [CreditLimit] = 15000.00,
    [PhoneNumber] = N'(206) 555-9999',
    [DeliveryAddressLine1] = N'Suite 999 (Updated)',
    [LastEditedBy] = 1
WHERE [CustomerName] = N'Test Client Alpha';
GO

-- Проверяем обновленные поля
SELECT 
    CustomerID, 
    CustomerName, 
    CreditLimit, 
    PhoneNumber, 
    DeliveryAddressLine1
FROM [Sales].[Customers]
WHERE [CustomerName] = N'Test Client Alpha';
GO
--4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
USE WideWorldImporters;
GO

-- 1. Создаем таблицу-источник с колонкой под ID
DECLARE @SourceTable TABLE
(
    [CustomerID]   INT,
    [CustomerName] NVARCHAR(100),
    [CreditLimit]  DECIMAL(18,2),
    [PhoneNumber]  NVARCHAR(20)
);

-- 2. Генерируем NEXT VALUE FOR заранее для новых записей
INSERT INTO @SourceTable ([CustomerID], [CustomerName], [CreditLimit], [PhoneNumber])
VALUES 
    (NULL, N'Test Client Beta', 25000.00, N'(206) 555-7777'),
    (NEXT VALUE FOR Sequences.CustomerID, N'Test Client Zeta', 12000.00, N'(206) 555-8888');

-- 3. Выполняем MERGE, подставляя уже готовый src.[CustomerID]
MERGE INTO [Sales].[Customers] AS target
USING @SourceTable AS src
    ON target.[CustomerName] = src.[CustomerName]
WHEN MATCHED THEN
    UPDATE SET 
        target.[CreditLimit] = src.[CreditLimit],
        target.[PhoneNumber] = src.[PhoneNumber],
        target.[LastEditedBy] = 1
WHEN NOT MATCHED THEN
    INSERT 
    (
        [CustomerID],
        [CustomerName],
        [BillToCustomerID],
        [CustomerCategoryID],
        [PrimaryContactPersonID],
        [DeliveryMethodID],
        [DeliveryCityID],
        [PostalCityID],
        [CreditLimit],
        [AccountOpenedDate],
        [StandardDiscountPercentage],
        [IsStatementSent],
        [IsOnCreditHold],
        [PaymentDays],
        [PhoneNumber],
        [FaxNumber],
        [WebsiteURL],
        [DeliveryAddressLine1],
        [DeliveryPostalCode],
        [PostalAddressLine1],
        [PostalPostalCode],
        [LastEditedBy]
    )
    VALUES
    (
        src.[CustomerID], -- Берем заранее сгенерированный ID из источника
        src.[CustomerName],
        1, 3, 1001, 3, 19586, 19586,
        src.[CreditLimit],
        CAST(GETDATE() AS DATE),
        0.000, 0, 0, 7,
        src.[PhoneNumber],
        N'(206) 555-0000',
        N'http://zeta.example.com',
        N'Suite 600', N'98101',
        N'PO Box 600', N'98101',
        1
    );
GO

-- 4. Проверяем результат работы MERGE
SELECT CustomerID, CustomerName, CreditLimit, PhoneNumber
FROM [Sales].[Customers]
WHERE CustomerName IN (N'Test Client Beta', N'Test Client Zeta');
GO
--5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert

-- 1. Создаем чистую целевую таблицу под структуру выгруженного файла
DROP TABLE IF EXISTS [dbo].[Customers_BulkDemo];
CREATE TABLE [dbo].[Customers_BulkDemo]
(
    [CustomerID]   INT,
    [CustomerName] NVARCHAR(100),
    [CreditLimit]  DECIMAL(18,2),
    [PhoneNumber]  NVARCHAR(20)
);
GO

-- 2. Загружаем данные из файла
BULK INSERT [dbo].[Customers_BulkDemo]
FROM 'C:\Temp\customers_export.txt'
WITH
(
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = '\t',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

-- 3. Проверяем результат импорта
SELECT 
    [CustomerID], 
    [CustomerName], 
    [CreditLimit], 
    [PhoneNumber]
FROM [dbo].[Customers_BulkDemo];
GO