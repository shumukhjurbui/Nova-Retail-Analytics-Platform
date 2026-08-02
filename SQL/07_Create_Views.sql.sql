/*
=========================================================
Project Name : Nova Retail Analytics Platform
File Name    : 07_Create_Views.sql
Database     : NovaRetail_OLTP
Description  : Create analytical views for reporting
=========================================================
*/

USE NovaRetail_OLTP;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO


/*
=========================================================
1. Create Analytics Schema
=========================================================
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = N'Analytics'
)
BEGIN
    EXEC
    (
        N'CREATE SCHEMA Analytics AUTHORIZATION dbo;'
    );
END;
GO


/*
=========================================================
2. Detailed Sales View

Grain:
One row for every order detail/product line
=========================================================
*/

CREATE OR ALTER VIEW Analytics.vw_SalesDetails
AS

SELECT
    OD.OrderDetailID,

    O.OrderID,

    O.OrderDate,

    CAST(O.OrderDate AS DATE) AS OrderDateOnly,

    YEAR(O.OrderDate) AS SalesYear,

    MONTH(O.OrderDate) AS SalesMonthNumber,

    DATENAME(MONTH, O.OrderDate) AS SalesMonthName,

    CONCAT
    (
        YEAR(O.OrderDate),
        '-',
        RIGHT
        (
            '0' + CAST(MONTH(O.OrderDate) AS VARCHAR(2)),
            2
        )
    ) AS SalesYearMonth,

    DATEPART(QUARTER, O.OrderDate) AS SalesQuarter,

    DATENAME(WEEKDAY, O.OrderDate) AS SalesDayName,

    DATEPART(HOUR, O.OrderDate) AS SalesHour,

    O.OrderStatus,

    CASE
        WHEN O.OrderStatus = N'Completed'
            THEN 1
        ELSE 0
    END AS IsCompletedOrder,

    C.CustomerID,

    CONCAT
    (
        C.FirstName,
        N' ',
        C.LastName
    ) AS CustomerName,

    CustomerCity.CityID AS CustomerCityID,

    CustomerCity.CityName AS CustomerCityName,

    CustomerCity.Region AS CustomerRegion,

    C.RegistrationDate,

    B.BranchID,

    B.BranchName,

    BranchCity.CityID AS BranchCityID,

    BranchCity.CityName AS BranchCityName,

    BranchCity.Region AS BranchRegion,

    E.EmployeeID,

    CONCAT
    (
        E.FirstName,
        N' ',
        E.LastName
    ) AS EmployeeName,

    P.ProductID,

    P.ProductName,

    CAT.CategoryID,

    CAT.CategoryName,

    OD.Quantity,

    OD.UnitPrice,

    P.UnitCost,

    OD.DiscountPercent,

    CAST
    (
        OD.Quantity
        * OD.UnitPrice
        AS DECIMAL(18,2)
    ) AS GrossSales,

    CAST
    (
        OD.Quantity
        * OD.UnitPrice
        * OD.DiscountPercent / 100.0
        AS DECIMAL(18,2)
    ) AS DiscountAmount,

    CAST
    (
        OD.Quantity
        * OD.UnitPrice
        * (1 - OD.DiscountPercent / 100.0)
        AS DECIMAL(18,2)
    ) AS NetSales,

    CAST
    (
        OD.Quantity
        * P.UnitCost
        AS DECIMAL(18,2)
    ) AS TotalCost,

    CAST
    (
        OD.Quantity
        * OD.UnitPrice
        * (1 - OD.DiscountPercent / 100.0)
        -
        OD.Quantity
        * P.UnitCost
        AS DECIMAL(18,2)
    ) AS Profit

FROM Sales.OrderDetails AS OD

INNER JOIN Sales.Orders AS O
    ON O.OrderID = OD.OrderID

INNER JOIN Sales.Customers AS C
    ON C.CustomerID = O.CustomerID

INNER JOIN Lookup.Cities AS CustomerCity
    ON CustomerCity.CityID = C.CityID

INNER JOIN Sales.Branches AS B
    ON B.BranchID = O.BranchID

INNER JOIN Lookup.Cities AS BranchCity
    ON BranchCity.CityID = B.CityID

INNER JOIN HumanResources.Employees AS E
    ON E.EmployeeID = O.EmployeeID

INNER JOIN Production.Products AS P
    ON P.ProductID = OD.ProductID

INNER JOIN Production.Categories AS CAT
    ON CAT.CategoryID = P.CategoryID;
GO


/*
=========================================================
3. Order Summary View

Grain:
One row for every order
=========================================================
*/

CREATE OR ALTER VIEW Analytics.vw_OrderSummary
AS

SELECT
    OrderID,

    OrderDate,

    OrderDateOnly,

    SalesYear,

    SalesMonthNumber,

    SalesMonthName,

    SalesYearMonth,

    SalesQuarter,

    SalesDayName,

    SalesHour,

    OrderStatus,

    IsCompletedOrder,

    CustomerID,

    CustomerName,

    CustomerCityName,

    CustomerRegion,

    BranchID,

    BranchName,

    BranchCityName,

    BranchRegion,

    EmployeeID,

    EmployeeName,

    COUNT(*) AS ProductLines,

    SUM(Quantity) AS TotalUnits,

    CAST
    (
        SUM(GrossSales)
        AS DECIMAL(18,2)
    ) AS GrossSales,

    CAST
    (
        SUM(DiscountAmount)
        AS DECIMAL(18,2)
    ) AS DiscountAmount,

    CAST
    (
        SUM(NetSales)
        AS DECIMAL(18,2)
    ) AS NetSales,

    CAST
    (
        SUM(TotalCost)
        AS DECIMAL(18,2)
    ) AS TotalCost,

    CAST
    (
        SUM(Profit)
        AS DECIMAL(18,2)
    ) AS Profit

FROM Analytics.vw_SalesDetails

GROUP BY
    OrderID,
    OrderDate,
    OrderDateOnly,
    SalesYear,
    SalesMonthNumber,
    SalesMonthName,
    SalesYearMonth,
    SalesQuarter,
    SalesDayName,
    SalesHour,
    OrderStatus,
    IsCompletedOrder,
    CustomerID,
    CustomerName,
    CustomerCityName,
    CustomerRegion,
    BranchID,
    BranchName,
    BranchCityName,
    BranchRegion,
    EmployeeID,
    EmployeeName;
GO


/*
=========================================================
4. Product Performance View

Completed orders only
=========================================================
*/

CREATE OR ALTER VIEW Analytics.vw_ProductPerformance
AS

SELECT
    ProductID,

    ProductName,

    CategoryID,

    CategoryName,

    COUNT(DISTINCT OrderID) AS CompletedOrders,

    SUM(Quantity) AS UnitsSold,

    CAST
    (
        SUM(GrossSales)
        AS DECIMAL(18,2)
    ) AS GrossSales,

    CAST
    (
        SUM(DiscountAmount)
        AS DECIMAL(18,2)
    ) AS DiscountAmount,

    CAST
    (
        SUM(NetSales)
        AS DECIMAL(18,2)
    ) AS NetSales,

    CAST
    (
        SUM(TotalCost)
        AS DECIMAL(18,2)
    ) AS TotalCost,

    CAST
    (
        SUM(Profit)
        AS DECIMAL(18,2)
    ) AS Profit,

    CAST
    (
        SUM(Profit) * 100.0
        / NULLIF(SUM(NetSales), 0)
        AS DECIMAL(10,2)
    ) AS ProfitMarginPercent

FROM Analytics.vw_SalesDetails

WHERE OrderStatus = N'Completed'

GROUP BY
    ProductID,
    ProductName,
    CategoryID,
    CategoryName;
GO


/*
=========================================================
5. Inventory Status View
=========================================================
*/

CREATE OR ALTER VIEW Analytics.vw_InventoryStatus
AS

SELECT
    P.ProductID,

    P.ProductName,

    C.CategoryID,

    C.CategoryName,

    P.UnitPrice,

    P.UnitCost,

    P.StockQuantity,

    CAST
    (
        P.StockQuantity
        * P.UnitCost
        AS DECIMAL(18,2)
    ) AS InventoryCostValue,

    CAST
    (
        P.StockQuantity
        * P.UnitPrice
        AS DECIMAL(18,2)
    ) AS PotentialSalesValue,

    CASE
        WHEN P.StockQuantity = 0
            THEN N'Out of Stock'

        WHEN P.StockQuantity <= 20
            THEN N'Low Stock'

        WHEN P.StockQuantity <= 50
            THEN N'Medium Stock'

        ELSE N'Healthy Stock'
    END AS StockStatus,

    P.IsActive

FROM Production.Products AS P

INNER JOIN Production.Categories AS C
    ON C.CategoryID = P.CategoryID;
GO


/*
=========================================================
6. Verify Views
=========================================================
*/

SELECT
    COUNT(*) AS SalesDetailRows
FROM Analytics.vw_SalesDetails;
GO

SELECT
    COUNT(*) AS OrderSummaryRows
FROM Analytics.vw_OrderSummary;
GO

SELECT
    COUNT(*) AS ProductPerformanceRows
FROM Analytics.vw_ProductPerformance;
GO

SELECT
    COUNT(*) AS InventoryRows
FROM Analytics.vw_InventoryStatus;
GO

