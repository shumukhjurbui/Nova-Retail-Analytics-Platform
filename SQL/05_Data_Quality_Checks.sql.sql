/*
=========================================================
Project Name : Nova Retail Analytics Platform
File Name    : 05_Data_Quality_Checks.sql
Database     : NovaRetail_OLTP
Description  : Validate data quality and table relationships
=========================================================
*/

USE NovaRetail_OLTP;
GO

SET NOCOUNT ON;
GO


/*
=========================================================
1. Check row counts
=========================================================
*/

SELECT
    'Lookup.Cities' AS TableName,
    COUNT_BIG(*) AS TotalRows
FROM Lookup.Cities

UNION ALL

SELECT
    'Sales.Branches',
    COUNT_BIG(*)
FROM Sales.Branches

UNION ALL

SELECT
    'Production.Categories',
    COUNT_BIG(*)
FROM Production.Categories

UNION ALL

SELECT
    'Production.Products',
    COUNT_BIG(*)
FROM Production.Products

UNION ALL

SELECT
    'HumanResources.Employees',
    COUNT_BIG(*)
FROM HumanResources.Employees

UNION ALL

SELECT
    'Sales.Customers',
    COUNT_BIG(*)
FROM Sales.Customers

UNION ALL

SELECT
    'Sales.Orders',
    COUNT_BIG(*)
FROM Sales.Orders

UNION ALL

SELECT
    'Sales.OrderDetails',
    COUNT_BIG(*)
FROM Sales.OrderDetails;
GO


/*
=========================================================
2. Check duplicate customer emails
Expected result: 0 rows
=========================================================
*/

SELECT
    Email,
    COUNT(*) AS DuplicateCount
FROM Sales.Customers
GROUP BY Email
HAVING COUNT(*) > 1;
GO


/*
=========================================================
3. Check duplicate employee emails
Expected result: 0 rows
=========================================================
*/

SELECT
    Email,
    COUNT(*) AS DuplicateCount
FROM HumanResources.Employees
GROUP BY Email
HAVING COUNT(*) > 1;
GO


/*
=========================================================
4. Check orders without valid customers
Expected result: 0
=========================================================
*/

SELECT
    COUNT(*) AS InvalidOrdersWithoutCustomer
FROM Sales.Orders AS O

LEFT JOIN Sales.Customers AS C
    ON C.CustomerID = O.CustomerID

WHERE C.CustomerID IS NULL;
GO


/*
=========================================================
5. Check orders without valid employees
Expected result: 0
=========================================================
*/

SELECT
    COUNT(*) AS InvalidOrdersWithoutEmployee
FROM Sales.Orders AS O

LEFT JOIN HumanResources.Employees AS E
    ON E.EmployeeID = O.EmployeeID

WHERE E.EmployeeID IS NULL;
GO


/*
=========================================================
6. Check orders without valid branches
Expected result: 0
=========================================================
*/

SELECT
    COUNT(*) AS InvalidOrdersWithoutBranch
FROM Sales.Orders AS O

LEFT JOIN Sales.Branches AS B
    ON B.BranchID = O.BranchID

WHERE B.BranchID IS NULL;
GO


/*
=========================================================
7. Check order details without valid orders
Expected result: 0
=========================================================
*/

SELECT
    COUNT(*) AS InvalidDetailsWithoutOrder
FROM Sales.OrderDetails AS OD

LEFT JOIN Sales.Orders AS O
    ON O.OrderID = OD.OrderID

WHERE O.OrderID IS NULL;
GO


/*
=========================================================
8. Check order details without valid products
Expected result: 0
=========================================================
*/

SELECT
    COUNT(*) AS InvalidDetailsWithoutProduct
FROM Sales.OrderDetails AS OD

LEFT JOIN Production.Products AS P
    ON P.ProductID = OD.ProductID

WHERE P.ProductID IS NULL;
GO


/*
=========================================================
9. Check orders created before customer registration
Expected result: 0
=========================================================
*/

SELECT
    COUNT(*) AS OrdersBeforeRegistration
FROM Sales.Orders AS O

INNER JOIN Sales.Customers AS C
    ON C.CustomerID = O.CustomerID

WHERE CAST(O.OrderDate AS DATE) < C.RegistrationDate;
GO


/*
=========================================================
10. Check employee and order branch consistency
Expected result: 0
=========================================================
*/

SELECT
    COUNT(*) AS EmployeeBranchMismatch
FROM Sales.Orders AS O

INNER JOIN HumanResources.Employees AS E
    ON E.EmployeeID = O.EmployeeID

WHERE O.BranchID <> E.BranchID;
GO


/*
=========================================================
11. Check orders without order details
Expected result: 0
=========================================================
*/

SELECT
    COUNT(*) AS OrdersWithoutDetails
FROM Sales.Orders AS O

LEFT JOIN Sales.OrderDetails AS OD
    ON OD.OrderID = O.OrderID

WHERE OD.OrderID IS NULL;
GO


/*
=========================================================
12. Check duplicate products inside the same order
Expected result: 0 rows
=========================================================
*/

SELECT
    OrderID,
    ProductID,
    COUNT(*) AS DuplicateCount
FROM Sales.OrderDetails
GROUP BY
    OrderID,
    ProductID
HAVING COUNT(*) > 1;
GO


/*
=========================================================
13. Check invalid financial and quantity values
Expected result: all values equal 0
=========================================================
*/

SELECT
    SUM
    (
        CASE
            WHEN Quantity <= 0 THEN 1
            ELSE 0
        END
    ) AS InvalidQuantityRows,

    SUM
    (
        CASE
            WHEN UnitPrice < 0 THEN 1
            ELSE 0
        END
    ) AS InvalidPriceRows,

    SUM
    (
        CASE
            WHEN DiscountPercent < 0
              OR DiscountPercent > 100
            THEN 1
            ELSE 0
        END
    ) AS InvalidDiscountRows

FROM Sales.OrderDetails;
GO


/*
=========================================================
14. Check product values
Expected result: all values equal 0
=========================================================
*/

SELECT
    SUM
    (
        CASE
            WHEN UnitPrice < 0 THEN 1
            ELSE 0
        END
    ) AS InvalidProductPrices,

    SUM
    (
        CASE
            WHEN UnitCost < 0 THEN 1
            ELSE 0
        END
    ) AS InvalidProductCosts,

    SUM
    (
        CASE
            WHEN StockQuantity < 0 THEN 1
            ELSE 0
        END
    ) AS InvalidStockQuantities

FROM Production.Products;
GO


/*
=========================================================
15. Check order status distribution
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
16. Check number of products per order
Expected minimum: 3
Expected maximum: 4
Expected average: 3.50
=========================================================
*/

WITH ProductsPerOrder AS
(
    SELECT
        OrderID,
        COUNT(*) AS ProductCount
    FROM Sales.OrderDetails
    GROUP BY OrderID
)

SELECT
    MIN(ProductCount) AS MinimumProductsPerOrder,

    MAX(ProductCount) AS MaximumProductsPerOrder,

    CAST
    (
        AVG(CAST(ProductCount AS DECIMAL(10,2)))
        AS DECIMAL(10,2)
    ) AS AverageProductsPerOrder

FROM ProductsPerOrder;
GO


/*
=========================================================
17. Check order date range
=========================================================
*/

SELECT
    MIN(OrderDate) AS FirstOrderDate,
    MAX(OrderDate) AS LastOrderDate
FROM Sales.Orders;
GO