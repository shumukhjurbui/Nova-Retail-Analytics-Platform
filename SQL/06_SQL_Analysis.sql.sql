/*
=========================================================
Project Name : Nova Retail Analytics Platform
File Name    : 06_SQL_Analysis.sql
Database     : NovaRetail_OLTP
Description  : Business and sales analysis queries
=========================================================
*/

USE NovaRetail_OLTP;
GO

SET NOCOUNT ON;
GO


/*
=========================================================
1. Overall Business KPIs
Completed orders only
=========================================================
*/

SELECT
    COUNT(DISTINCT O.OrderID) AS TotalCompletedOrders,

    COUNT(DISTINCT O.CustomerID) AS ActiveCustomers,

    SUM(OD.Quantity) AS TotalUnitsSold,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
        )
        AS DECIMAL(18,2)
    ) AS GrossSales,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * OD.DiscountPercent / 100.0
        )
        AS DECIMAL(18,2)
    ) AS TotalDiscount,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
        )
        AS DECIMAL(18,2)
    ) AS NetSales,

    CAST
    (
        SUM
        (
            OD.Quantity
            * P.UnitCost
        )
        AS DECIMAL(18,2)
    ) AS TotalCost,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
            -
            OD.Quantity
            * P.UnitCost
        )
        AS DECIMAL(18,2)
    ) AS TotalProfit

FROM Sales.Orders AS O

INNER JOIN Sales.OrderDetails AS OD
    ON OD.OrderID = O.OrderID

INNER JOIN Production.Products AS P
    ON P.ProductID = OD.ProductID

WHERE O.OrderStatus = N'Completed';
GO


/*
=========================================================
2. Order Status Distribution
=========================================================
*/

SELECT
    OrderStatus,

    COUNT(*) AS TotalOrders,

    CAST
    (
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,2)
    ) AS PercentageOfOrders

FROM Sales.Orders

GROUP BY OrderStatus

ORDER BY TotalOrders DESC;
GO


/*
=========================================================
3. Monthly Sales Trend
Completed orders only
=========================================================
*/

SELECT
    YEAR(O.OrderDate) AS SalesYear,

    MONTH(O.OrderDate) AS SalesMonth,

    DATENAME(MONTH, O.OrderDate) AS MonthName,

    COUNT(DISTINCT O.OrderID) AS TotalOrders,

    SUM(OD.Quantity) AS UnitsSold,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
        )
        AS DECIMAL(18,2)
    ) AS NetSales,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
            -
            OD.Quantity
            * P.UnitCost
        )
        AS DECIMAL(18,2)
    ) AS Profit

FROM Sales.Orders AS O

INNER JOIN Sales.OrderDetails AS OD
    ON OD.OrderID = O.OrderID

INNER JOIN Production.Products AS P
    ON P.ProductID = OD.ProductID

WHERE O.OrderStatus = N'Completed'

GROUP BY
    YEAR(O.OrderDate),
    MONTH(O.OrderDate),
    DATENAME(MONTH, O.OrderDate)

ORDER BY
    SalesYear,
    SalesMonth;
GO


/*
=========================================================
4. Category Performance
=========================================================
*/

SELECT
    C.CategoryID,

    C.CategoryName,

    COUNT(DISTINCT O.OrderID) AS TotalOrders,

    SUM(OD.Quantity) AS UnitsSold,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
        )
        AS DECIMAL(18,2)
    ) AS NetSales,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
            -
            OD.Quantity
            * P.UnitCost
        )
        AS DECIMAL(18,2)
    ) AS Profit,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
            -
            OD.Quantity
            * P.UnitCost
        )
        * 100.0
        /
        NULLIF
        (
            SUM
            (
                OD.Quantity
                * OD.UnitPrice
                * (1 - OD.DiscountPercent / 100.0)
            ),
            0
        )
        AS DECIMAL(10,2)
    ) AS ProfitMarginPercent

FROM Sales.Orders AS O

INNER JOIN Sales.OrderDetails AS OD
    ON OD.OrderID = O.OrderID

INNER JOIN Production.Products AS P
    ON P.ProductID = OD.ProductID

INNER JOIN Production.Categories AS C
    ON C.CategoryID = P.CategoryID

WHERE O.OrderStatus = N'Completed'

GROUP BY
    C.CategoryID,
    C.CategoryName

ORDER BY NetSales DESC;
GO


/*
=========================================================
5. Top 10 Products by Net Sales
=========================================================
*/

SELECT TOP (10)
    P.ProductID,

    P.ProductName,

    C.CategoryName,

    SUM(OD.Quantity) AS UnitsSold,

    COUNT(DISTINCT O.OrderID) AS NumberOfOrders,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
        )
        AS DECIMAL(18,2)
    ) AS NetSales,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
            -
            OD.Quantity
            * P.UnitCost
        )
        AS DECIMAL(18,2)
    ) AS Profit

FROM Sales.Orders AS O

INNER JOIN Sales.OrderDetails AS OD
    ON OD.OrderID = O.OrderID

INNER JOIN Production.Products AS P
    ON P.ProductID = OD.ProductID

INNER JOIN Production.Categories AS C
    ON C.CategoryID = P.CategoryID

WHERE O.OrderStatus = N'Completed'

GROUP BY
    P.ProductID,
    P.ProductName,
    C.CategoryName

ORDER BY NetSales DESC;
GO


/*
=========================================================
6. Product Ranking by Units Sold
=========================================================
*/

WITH ProductSales AS
(
    SELECT
        P.ProductID,

        P.ProductName,

        SUM(OD.Quantity) AS UnitsSold

    FROM Sales.Orders AS O

    INNER JOIN Sales.OrderDetails AS OD
        ON OD.OrderID = O.OrderID

    INNER JOIN Production.Products AS P
        ON P.ProductID = OD.ProductID

    WHERE O.OrderStatus = N'Completed'

    GROUP BY
        P.ProductID,
        P.ProductName
)

SELECT
    ProductID,

    ProductName,

    UnitsSold,

    DENSE_RANK() OVER
    (
        ORDER BY UnitsSold DESC
    ) AS SalesRank

FROM ProductSales

ORDER BY SalesRank;
GO


/*
=========================================================
7. Branch Performance
=========================================================
*/

SELECT
    B.BranchID,

    B.BranchName,

    C.CityName,

    COUNT(DISTINCT O.OrderID) AS TotalOrders,

    COUNT(DISTINCT O.CustomerID) AS UniqueCustomers,

    SUM(OD.Quantity) AS UnitsSold,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
        )
        AS DECIMAL(18,2)
    ) AS NetSales,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
            -
            OD.Quantity
            * P.UnitCost
        )
        AS DECIMAL(18,2)
    ) AS Profit

FROM Sales.Orders AS O

INNER JOIN Sales.Branches AS B
    ON B.BranchID = O.BranchID

INNER JOIN Lookup.Cities AS C
    ON C.CityID = B.CityID

INNER JOIN Sales.OrderDetails AS OD
    ON OD.OrderID = O.OrderID

INNER JOIN Production.Products AS P
    ON P.ProductID = OD.ProductID

WHERE O.OrderStatus = N'Completed'

GROUP BY
    B.BranchID,
    B.BranchName,
    C.CityName

ORDER BY NetSales DESC;
GO


/*
=========================================================
8. Employee Sales Performance
=========================================================
*/

SELECT
    E.EmployeeID,

    CONCAT
    (
        E.FirstName,
        N' ',
        E.LastName
    ) AS EmployeeName,

    B.BranchName,

    COUNT(DISTINCT O.OrderID) AS CompletedOrders,

    COUNT(DISTINCT O.CustomerID) AS ServedCustomers,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
        )
        AS DECIMAL(18,2)
    ) AS NetSales,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
            -
            OD.Quantity
            * P.UnitCost
        )
        AS DECIMAL(18,2)
    ) AS Profit

FROM Sales.Orders AS O

INNER JOIN HumanResources.Employees AS E
    ON E.EmployeeID = O.EmployeeID

INNER JOIN Sales.Branches AS B
    ON B.BranchID = E.BranchID

INNER JOIN Sales.OrderDetails AS OD
    ON OD.OrderID = O.OrderID

INNER JOIN Production.Products AS P
    ON P.ProductID = OD.ProductID

WHERE O.OrderStatus = N'Completed'

GROUP BY
    E.EmployeeID,
    E.FirstName,
    E.LastName,
    B.BranchName

ORDER BY NetSales DESC;
GO


/*
=========================================================
9. Sales by Customer City
=========================================================
*/

SELECT
    C.CityName,

    C.Region,

    COUNT(DISTINCT CU.CustomerID) AS TotalCustomers,

    COUNT(DISTINCT O.OrderID) AS TotalOrders,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
        )
        AS DECIMAL(18,2)
    ) AS NetSales

FROM Sales.Orders AS O

INNER JOIN Sales.Customers AS CU
    ON CU.CustomerID = O.CustomerID

INNER JOIN Lookup.Cities AS C
    ON C.CityID = CU.CityID

INNER JOIN Sales.OrderDetails AS OD
    ON OD.OrderID = O.OrderID

WHERE O.OrderStatus = N'Completed'

GROUP BY
    C.CityName,
    C.Region

ORDER BY NetSales DESC;
GO


/*
=========================================================
10. Top 10 Customers by Spending
=========================================================
*/

SELECT TOP (10)
    C.CustomerID,

    CONCAT
    (
        C.FirstName,
        N' ',
        C.LastName
    ) AS CustomerName,

    CT.CityName,

    COUNT(DISTINCT O.OrderID) AS CompletedOrders,

    SUM(OD.Quantity) AS UnitsPurchased,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
        )
        AS DECIMAL(18,2)
    ) AS TotalSpending

FROM Sales.Customers AS C

INNER JOIN Lookup.Cities AS CT
    ON CT.CityID = C.CityID

INNER JOIN Sales.Orders AS O
    ON O.CustomerID = C.CustomerID

INNER JOIN Sales.OrderDetails AS OD
    ON OD.OrderID = O.OrderID

WHERE O.OrderStatus = N'Completed'

GROUP BY
    C.CustomerID,
    C.FirstName,
    C.LastName,
    CT.CityName

ORDER BY TotalSpending DESC;
GO


/*
=========================================================
11. Average Order Value
=========================================================
*/

WITH OrderTotals AS
(
    SELECT
        O.OrderID,

        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
        ) AS OrderValue

    FROM Sales.Orders AS O

    INNER JOIN Sales.OrderDetails AS OD
        ON OD.OrderID = O.OrderID

    WHERE O.OrderStatus = N'Completed'

    GROUP BY O.OrderID
)

SELECT
    COUNT(*) AS TotalCompletedOrders,

    CAST
    (
        AVG(OrderValue)
        AS DECIMAL(18,2)
    ) AS AverageOrderValue,

    CAST
    (
        MIN(OrderValue)
        AS DECIMAL(18,2)
    ) AS MinimumOrderValue,

    CAST
    (
        MAX(OrderValue)
        AS DECIMAL(18,2)
    ) AS MaximumOrderValue

FROM OrderTotals;
GO


/*
=========================================================
12. Discount Analysis
=========================================================
*/

SELECT
    OD.DiscountPercent,

    COUNT(*) AS DetailRows,

    SUM(OD.Quantity) AS UnitsSold,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
        )
        AS DECIMAL(18,2)
    ) AS GrossSales,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * OD.DiscountPercent / 100.0
        )
        AS DECIMAL(18,2)
    ) AS DiscountAmount,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
        )
        AS DECIMAL(18,2)
    ) AS NetSales

FROM Sales.Orders AS O

INNER JOIN Sales.OrderDetails AS OD
    ON OD.OrderID = O.OrderID

WHERE O.OrderStatus = N'Completed'

GROUP BY OD.DiscountPercent

ORDER BY OD.DiscountPercent;
GO


/*
=========================================================
13. Sales by Day of Week
=========================================================
*/

SELECT
    DATEPART(WEEKDAY, O.OrderDate) AS DayNumber,

    DATENAME(WEEKDAY, O.OrderDate) AS DayName,

    COUNT(DISTINCT O.OrderID) AS TotalOrders,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
        )
        AS DECIMAL(18,2)
    ) AS NetSales

FROM Sales.Orders AS O

INNER JOIN Sales.OrderDetails AS OD
    ON OD.OrderID = O.OrderID

WHERE O.OrderStatus = N'Completed'

GROUP BY
    DATEPART(WEEKDAY, O.OrderDate),
    DATENAME(WEEKDAY, O.OrderDate)

ORDER BY DayNumber;
GO


/*
=========================================================
14. Sales by Hour
=========================================================
*/

SELECT
    DATEPART(HOUR, O.OrderDate) AS SalesHour,

    COUNT(DISTINCT O.OrderID) AS TotalOrders,

    CAST
    (
        SUM
        (
            OD.Quantity
            * OD.UnitPrice
            * (1 - OD.DiscountPercent / 100.0)
        )
        AS DECIMAL(18,2)
    ) AS NetSales

FROM Sales.Orders AS O

INNER JOIN Sales.OrderDetails AS OD
    ON OD.OrderID = O.OrderID

WHERE O.OrderStatus = N'Completed'

GROUP BY DATEPART(HOUR, O.OrderDate)

ORDER BY SalesHour;
GO


/*
=========================================================
15. Inventory Status
=========================================================
*/

SELECT
    P.ProductID,

    P.ProductName,

    C.CategoryName,

    P.StockQuantity,

    P.UnitCost,

    CAST
    (
        P.StockQuantity * P.UnitCost
        AS DECIMAL(18,2)
    ) AS InventoryCostValue,

    CAST
    (
        P.StockQuantity * P.UnitPrice
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
    END AS StockStatus

FROM Production.Products AS P

INNER JOIN Production.Categories AS C
    ON C.CategoryID = P.CategoryID

ORDER BY
    P.StockQuantity,
    P.ProductName;
GO


/*
=========================================================
16. Cancellation and Return Rate by Branch
=========================================================
*/

SELECT
    B.BranchName,

    COUNT(*) AS TotalOrders,

    SUM
    (
        CASE
            WHEN O.OrderStatus = N'Cancelled'
                THEN 1
            ELSE 0
        END
    ) AS CancelledOrders,

    SUM
    (
        CASE
            WHEN O.OrderStatus = N'Returned'
                THEN 1
            ELSE 0
        END
    ) AS ReturnedOrders,

    CAST
    (
        SUM
        (
            CASE
                WHEN O.OrderStatus = N'Cancelled'
                    THEN 1
                ELSE 0
            END
        )
        * 100.0
        / COUNT(*)
        AS DECIMAL(5,2)
    ) AS CancellationRatePercent,

    CAST
    (
        SUM
        (
            CASE
                WHEN O.OrderStatus = N'Returned'
                    THEN 1
                ELSE 0
            END
        )
        * 100.0
        / COUNT(*)
        AS DECIMAL(5,2)
    ) AS ReturnRatePercent

FROM Sales.Orders AS O

INNER JOIN Sales.Branches AS B
    ON B.BranchID = O.BranchID

GROUP BY B.BranchName

ORDER BY CancellationRatePercent DESC;
GO