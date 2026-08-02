/*
=========================================================
Project Name : Nova Retail Analytics Platform
File Name    : 10_Create_Indexes.sql
Description  : Create performance indexes for OLTP and DWH
=========================================================
*/


/*
=========================================================
PART 1: OLTP Database Indexes
=========================================================
*/

USE NovaRetail_OLTP;
GO


/*
---------------------------------------------------------
1. Branches by City
---------------------------------------------------------
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Branches_CityID'
      AND object_id = OBJECT_ID(N'Sales.Branches')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Branches_CityID
        ON Sales.Branches (CityID);
END;
GO


/*
---------------------------------------------------------
2. Products by Category
---------------------------------------------------------
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Products_CategoryID'
      AND object_id = OBJECT_ID(N'Production.Products')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Products_CategoryID
        ON Production.Products (CategoryID)

        INCLUDE
        (
            ProductName,
            UnitPrice,
            UnitCost,
            StockQuantity,
            IsActive
        );
END;
GO


/*
---------------------------------------------------------
3. Employees by Branch
---------------------------------------------------------
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Employees_BranchID'
      AND object_id =
          OBJECT_ID(N'HumanResources.Employees')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Employees_BranchID
        ON HumanResources.Employees (BranchID)

        INCLUDE
        (
            FirstName,
            LastName,
            HireDate,
            Salary,
            IsActive
        );
END;
GO


/*
---------------------------------------------------------
4. Customers by City
---------------------------------------------------------
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Customers_CityID'
      AND object_id = OBJECT_ID(N'Sales.Customers')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Customers_CityID
        ON Sales.Customers (CityID)

        INCLUDE
        (
            FirstName,
            LastName,
            RegistrationDate,
            IsActive
        );
END;
GO


/*
---------------------------------------------------------
5. Orders by Customer
---------------------------------------------------------
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Orders_CustomerID'
      AND object_id = OBJECT_ID(N'Sales.Orders')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Orders_CustomerID
        ON Sales.Orders (CustomerID)

        INCLUDE
        (
            OrderDate,
            OrderStatus,
            BranchID,
            EmployeeID
        );
END;
GO


/*
---------------------------------------------------------
6. Orders by Employee
---------------------------------------------------------
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Orders_EmployeeID'
      AND object_id = OBJECT_ID(N'Sales.Orders')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Orders_EmployeeID
        ON Sales.Orders (EmployeeID)

        INCLUDE
        (
            OrderDate,
            OrderStatus,
            BranchID,
            CustomerID
        );
END;
GO


/*
---------------------------------------------------------
7. Orders by Branch
---------------------------------------------------------
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Orders_BranchID'
      AND object_id = OBJECT_ID(N'Sales.Orders')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Orders_BranchID
        ON Sales.Orders (BranchID)

        INCLUDE
        (
            OrderDate,
            OrderStatus,
            CustomerID,
            EmployeeID
        );
END;
GO


/*
---------------------------------------------------------
8. Orders by Status and Date
---------------------------------------------------------
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Orders_Status_OrderDate'
      AND object_id = OBJECT_ID(N'Sales.Orders')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Orders_Status_OrderDate
        ON Sales.Orders
        (
            OrderStatus,
            OrderDate
        )

        INCLUDE
        (
            CustomerID,
            EmployeeID,
            BranchID
        );
END;
GO


/*
---------------------------------------------------------
9. Order Details by Order
---------------------------------------------------------
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_OrderDetails_OrderID'
      AND object_id = OBJECT_ID(N'Sales.OrderDetails')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_OrderDetails_OrderID
        ON Sales.OrderDetails (OrderID)

        INCLUDE
        (
            ProductID,
            Quantity,
            UnitPrice,
            DiscountPercent
        );
END;
GO


/*
---------------------------------------------------------
10. Order Details by Product
---------------------------------------------------------
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_OrderDetails_ProductID'
      AND object_id = OBJECT_ID(N'Sales.OrderDetails')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_OrderDetails_ProductID
        ON Sales.OrderDetails (ProductID)

        INCLUDE
        (
            OrderID,
            Quantity,
            UnitPrice,
            DiscountPercent
        );
END;
GO


/*
=========================================================
PART 2: Data Warehouse Indexes
=========================================================
*/

USE NovaRetail_DWH;
GO


/*
---------------------------------------------------------
11. FactSales by Date
---------------------------------------------------------
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_FactSales_OrderDateKey'
      AND object_id = OBJECT_ID(N'Fact.FactSales')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactSales_OrderDateKey
        ON Fact.FactSales (OrderDateKey)

        INCLUDE
        (
            OrderID,
            OrderStatus,
            Quantity,
            NetSales,
            Profit
        );
END;
GO


/*
---------------------------------------------------------
12. FactSales by Customer
---------------------------------------------------------
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_FactSales_CustomerKey'
      AND object_id = OBJECT_ID(N'Fact.FactSales')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactSales_CustomerKey
        ON Fact.FactSales (CustomerKey)

        INCLUDE
        (
            OrderDateKey,
            OrderID,
            Quantity,
            NetSales,
            Profit
        );
END;
GO


/*
---------------------------------------------------------
13. FactSales by Product
---------------------------------------------------------
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_FactSales_ProductKey'
      AND object_id = OBJECT_ID(N'Fact.FactSales')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactSales_ProductKey
        ON Fact.FactSales (ProductKey)

        INCLUDE
        (
            OrderDateKey,
            OrderID,
            Quantity,
            NetSales,
            Profit
        );
END;
GO


/*
---------------------------------------------------------
14. FactSales by Branch
---------------------------------------------------------
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_FactSales_BranchKey'
      AND object_id = OBJECT_ID(N'Fact.FactSales')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactSales_BranchKey
        ON Fact.FactSales (BranchKey)

        INCLUDE
        (
            OrderDateKey,
            OrderID,
            Quantity,
            NetSales,
            Profit
        );
END;
GO


/*
---------------------------------------------------------
15. FactSales by Employee
---------------------------------------------------------
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_FactSales_EmployeeKey'
      AND object_id = OBJECT_ID(N'Fact.FactSales')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactSales_EmployeeKey
        ON Fact.FactSales (EmployeeKey)

        INCLUDE
        (
            OrderDateKey,
            OrderID,
            Quantity,
            NetSales,
            Profit
        );
END;
GO


/*
---------------------------------------------------------
16. FactSales by Status and Date
---------------------------------------------------------
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_FactSales_Status_Date'
      AND object_id = OBJECT_ID(N'Fact.FactSales')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactSales_Status_Date
        ON Fact.FactSales
        (
            OrderStatus,
            OrderDateKey
        )

        INCLUDE
        (
            CustomerKey,
            ProductKey,
            BranchKey,
            EmployeeKey,
            Quantity,
            NetSales,
            Profit
        );
END;
GO


/*
=========================================================
PART 3: Verify Created Indexes
=========================================================
*/

SELECT
    SCHEMA_NAME(T.schema_id) AS SchemaName,

    T.name AS TableName,

    I.name AS IndexName,

    I.type_desc AS IndexType,

    I.is_unique AS IsUnique

FROM sys.indexes AS I

INNER JOIN sys.tables AS T
    ON T.object_id = I.object_id

WHERE I.name IS NOT NULL
  AND SCHEMA_NAME(T.schema_id) IN
      (
          N'Dim',
          N'Fact'
      )

ORDER BY
    SchemaName,
    TableName,
    IndexName;
GO