/*
=========================================================
Project Name : Nova Retail Analytics Platform
File Name    : 09_Load_DWH.sql
Source       : NovaRetail_OLTP
Target       : NovaRetail_DWH
Description  : Load dimensions and sales fact table
=========================================================
*/

USE NovaRetail_DWH;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY

    BEGIN TRANSACTION;

    /*
    =====================================================
    1. Validate Source and Target Databases
    =====================================================
    */

    IF DB_ID(N'NovaRetail_OLTP') IS NULL
    BEGIN
        ;THROW 51001,
        'Source database NovaRetail_OLTP does not exist.',
        1;
    END;

    IF OBJECT_ID(N'Dim.DimDate', N'U') IS NULL
       OR OBJECT_ID(N'Dim.DimCustomer', N'U') IS NULL
       OR OBJECT_ID(N'Dim.DimProduct', N'U') IS NULL
       OR OBJECT_ID(N'Dim.DimBranch', N'U') IS NULL
       OR OBJECT_ID(N'Dim.DimEmployee', N'U') IS NULL
       OR OBJECT_ID(N'Fact.FactSales', N'U') IS NULL
    BEGIN
        ;THROW 51002,
        'DWH tables are missing. Run 08_Create_DWH.sql first.',
        1;
    END;


    /*
    =====================================================
    2. Get Source Order Date Range
    =====================================================
    */

    DECLARE @MinimumOrderDate DATE;
    DECLARE @MaximumOrderDate DATE;

    SELECT
        @MinimumOrderDate =
            MIN(CAST(OrderDate AS DATE)),

        @MaximumOrderDate =
            MAX(CAST(OrderDate AS DATE))

    FROM NovaRetail_OLTP.Sales.Orders;


    IF @MinimumOrderDate IS NULL
       OR @MaximumOrderDate IS NULL
    BEGIN
        ;THROW 51003,
        'No source orders were found.',
        1;
    END;


    /*
    =====================================================
    3. Load Date Dimension

    Monday    = 1
    Tuesday   = 2
    ...
    Sunday    = 7
    =====================================================
    */

    ;WITH DateSeries AS
    (
        SELECT
            @MinimumOrderDate AS FullDate

        UNION ALL

        SELECT
            DATEADD(DAY, 1, FullDate)

        FROM DateSeries

        WHERE FullDate < @MaximumOrderDate
    ),

    DateAttributes AS
    (
        SELECT
            FullDate,

            (
                (
                    DATEDIFF
                    (
                        DAY,
                        CAST('19000101' AS DATE),
                        FullDate
                    ) % 7
                ) + 1
            ) AS DayOfWeekNumber

        FROM DateSeries
    )

    INSERT INTO Dim.DimDate
    (
        DateKey,
        FullDate,
        CalendarYear,
        CalendarQuarter,
        MonthNumber,
        MonthName,
        YearMonth,
        DayOfMonth,
        DayOfWeekNumber,
        DayName,
        IsWeekend
    )

    SELECT
        CONVERT
        (
            INT,
            CONVERT(CHAR(8), D.FullDate, 112)
        ) AS DateKey,

        D.FullDate,

        YEAR(D.FullDate) AS CalendarYear,

        DATEPART
        (
            QUARTER,
            D.FullDate
        ) AS CalendarQuarter,

        MONTH(D.FullDate) AS MonthNumber,

        CHOOSE
        (
            MONTH(D.FullDate),
            N'January',
            N'February',
            N'March',
            N'April',
            N'May',
            N'June',
            N'July',
            N'August',
            N'September',
            N'October',
            N'November',
            N'December'
        ) AS MonthName,

        CONVERT
        (
            CHAR(7),
            D.FullDate,
            120
        ) AS YearMonth,

        DAY(D.FullDate) AS DayOfMonth,

        D.DayOfWeekNumber,

        CHOOSE
        (
            D.DayOfWeekNumber,
            N'Monday',
            N'Tuesday',
            N'Wednesday',
            N'Thursday',
            N'Friday',
            N'Saturday',
            N'Sunday'
        ) AS DayName,

        CASE
            WHEN D.DayOfWeekNumber IN (6, 7)
                THEN 1
            ELSE 0
        END AS IsWeekend

    FROM DateAttributes AS D

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM Dim.DimDate AS ExistingDate

        WHERE ExistingDate.FullDate = D.FullDate
    )

    OPTION (MAXRECURSION 0);


    /*
    =====================================================
    4. Update Existing Customer Dimension Records
       Type 1 Dimension Update
    =====================================================
    */

    UPDATE TargetCustomer

    SET
        TargetCustomer.FirstName =
            SourceCustomer.FirstName,

        TargetCustomer.LastName =
            SourceCustomer.LastName,

        TargetCustomer.CustomerName =
            CONCAT
            (
                SourceCustomer.FirstName,
                N' ',
                SourceCustomer.LastName
            ),

        TargetCustomer.Email =
            SourceCustomer.Email,

        TargetCustomer.Phone =
            SourceCustomer.Phone,

        TargetCustomer.CityID =
            SourceCustomer.CityID,

        TargetCustomer.CityName =
            SourceCity.CityName,

        TargetCustomer.Region =
            SourceCity.Region,

        TargetCustomer.RegistrationDate =
            SourceCustomer.RegistrationDate,

        TargetCustomer.IsActive =
            SourceCustomer.IsActive,

        TargetCustomer.DWLoadDate =
            SYSDATETIME()

    FROM Dim.DimCustomer AS TargetCustomer

    INNER JOIN NovaRetail_OLTP.Sales.Customers
        AS SourceCustomer

        ON SourceCustomer.CustomerID =
           TargetCustomer.CustomerID

    INNER JOIN NovaRetail_OLTP.Lookup.Cities
        AS SourceCity

        ON SourceCity.CityID =
           SourceCustomer.CityID;


    /*
    =====================================================
    5. Insert New Customer Dimension Records
    =====================================================
    */

    INSERT INTO Dim.DimCustomer
    (
        CustomerID,
        FirstName,
        LastName,
        CustomerName,
        Email,
        Phone,
        CityID,
        CityName,
        Region,
        RegistrationDate,
        IsActive
    )

    SELECT
        C.CustomerID,

        C.FirstName,

        C.LastName,

        CONCAT
        (
            C.FirstName,
            N' ',
            C.LastName
        ) AS CustomerName,

        C.Email,

        C.Phone,

        C.CityID,

        CT.CityName,

        CT.Region,

        C.RegistrationDate,

        C.IsActive

    FROM NovaRetail_OLTP.Sales.Customers AS C

    INNER JOIN NovaRetail_OLTP.Lookup.Cities AS CT
        ON CT.CityID = C.CityID

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM Dim.DimCustomer AS D

        WHERE D.CustomerID = C.CustomerID
    );


    /*
    =====================================================
    6. Update Existing Product Dimension Records
    =====================================================
    */

    UPDATE TargetProduct

    SET
        TargetProduct.ProductName =
            SourceProduct.ProductName,

        TargetProduct.CategoryID =
            SourceProduct.CategoryID,

        TargetProduct.CategoryName =
            SourceCategory.CategoryName,

        TargetProduct.CurrentUnitPrice =
            SourceProduct.UnitPrice,

        TargetProduct.UnitCost =
            SourceProduct.UnitCost,

        TargetProduct.StockQuantity =
            SourceProduct.StockQuantity,

        TargetProduct.IsActive =
            SourceProduct.IsActive,

        TargetProduct.DWLoadDate =
            SYSDATETIME()

    FROM Dim.DimProduct AS TargetProduct

    INNER JOIN NovaRetail_OLTP.Production.Products
        AS SourceProduct

        ON SourceProduct.ProductID =
           TargetProduct.ProductID

    INNER JOIN NovaRetail_OLTP.Production.Categories
        AS SourceCategory

        ON SourceCategory.CategoryID =
           SourceProduct.CategoryID;


    /*
    =====================================================
    7. Insert New Product Dimension Records
    =====================================================
    */

    INSERT INTO Dim.DimProduct
    (
        ProductID,
        ProductName,
        CategoryID,
        CategoryName,
        CurrentUnitPrice,
        UnitCost,
        StockQuantity,
        IsActive
    )

    SELECT
        P.ProductID,

        P.ProductName,

        P.CategoryID,

        C.CategoryName,

        P.UnitPrice,

        P.UnitCost,

        P.StockQuantity,

        P.IsActive

    FROM NovaRetail_OLTP.Production.Products AS P

    INNER JOIN NovaRetail_OLTP.Production.Categories AS C
        ON C.CategoryID = P.CategoryID

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM Dim.DimProduct AS D

        WHERE D.ProductID = P.ProductID
    );


    /*
    =====================================================
    8. Update Existing Branch Dimension Records
    =====================================================
    */

    UPDATE TargetBranch

    SET
        TargetBranch.BranchName =
            SourceBranch.BranchName,

        TargetBranch.CityID =
            SourceBranch.CityID,

        TargetBranch.CityName =
            SourceCity.CityName,

        TargetBranch.Region =
            SourceCity.Region,

        TargetBranch.Address =
            SourceBranch.Address,

        TargetBranch.Phone =
            SourceBranch.Phone,

        TargetBranch.OpeningDate =
            SourceBranch.OpeningDate,

        TargetBranch.IsActive =
            SourceBranch.IsActive,

        TargetBranch.DWLoadDate =
            SYSDATETIME()

    FROM Dim.DimBranch AS TargetBranch

    INNER JOIN NovaRetail_OLTP.Sales.Branches
        AS SourceBranch

        ON SourceBranch.BranchID =
           TargetBranch.BranchID

    INNER JOIN NovaRetail_OLTP.Lookup.Cities
        AS SourceCity

        ON SourceCity.CityID =
           SourceBranch.CityID;


    /*
    =====================================================
    9. Insert New Branch Dimension Records
    =====================================================
    */

    INSERT INTO Dim.DimBranch
    (
        BranchID,
        BranchName,
        CityID,
        CityName,
        Region,
        Address,
        Phone,
        OpeningDate,
        IsActive
    )

    SELECT
        B.BranchID,

        B.BranchName,

        B.CityID,

        C.CityName,

        C.Region,

        B.Address,

        B.Phone,

        B.OpeningDate,

        B.IsActive

    FROM NovaRetail_OLTP.Sales.Branches AS B

    INNER JOIN NovaRetail_OLTP.Lookup.Cities AS C
        ON C.CityID = B.CityID

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM Dim.DimBranch AS D

        WHERE D.BranchID = B.BranchID
    );


    /*
    =====================================================
    10. Update Existing Employee Dimension Records
    =====================================================
    */

    UPDATE TargetEmployee

    SET
        TargetEmployee.FirstName =
            SourceEmployee.FirstName,

        TargetEmployee.LastName =
            SourceEmployee.LastName,

        TargetEmployee.EmployeeName =
            CONCAT
            (
                SourceEmployee.FirstName,
                N' ',
                SourceEmployee.LastName
            ),

        TargetEmployee.Email =
            SourceEmployee.Email,

        TargetEmployee.Phone =
            SourceEmployee.Phone,

        TargetEmployee.HireDate =
            SourceEmployee.HireDate,

        TargetEmployee.Salary =
            SourceEmployee.Salary,

        TargetEmployee.BranchID =
            SourceEmployee.BranchID,

        TargetEmployee.BranchName =
            SourceBranch.BranchName,

        TargetEmployee.IsActive =
            SourceEmployee.IsActive,

        TargetEmployee.DWLoadDate =
            SYSDATETIME()

    FROM Dim.DimEmployee AS TargetEmployee

    INNER JOIN NovaRetail_OLTP.HumanResources.Employees
        AS SourceEmployee

        ON SourceEmployee.EmployeeID =
           TargetEmployee.EmployeeID

    INNER JOIN NovaRetail_OLTP.Sales.Branches
        AS SourceBranch

        ON SourceBranch.BranchID =
           SourceEmployee.BranchID;


    /*
    =====================================================
    11. Insert New Employee Dimension Records
    =====================================================
    */

    INSERT INTO Dim.DimEmployee
    (
        EmployeeID,
        FirstName,
        LastName,
        EmployeeName,
        Email,
        Phone,
        HireDate,
        Salary,
        BranchID,
        BranchName,
        IsActive
    )

    SELECT
        E.EmployeeID,

        E.FirstName,

        E.LastName,

        CONCAT
        (
            E.FirstName,
            N' ',
            E.LastName
        ) AS EmployeeName,

        E.Email,

        E.Phone,

        E.HireDate,

        E.Salary,

        E.BranchID,

        B.BranchName,

        E.IsActive

    FROM NovaRetail_OLTP.HumanResources.Employees AS E

    INNER JOIN NovaRetail_OLTP.Sales.Branches AS B
        ON B.BranchID = E.BranchID

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM Dim.DimEmployee AS D

        WHERE D.EmployeeID = E.EmployeeID
    );


    /*
    =====================================================
    12. Refresh Sales Fact Table
    =====================================================
    */

    TRUNCATE TABLE Fact.FactSales;


    /*
    =====================================================
    13. Load Sales Fact Table
    =====================================================
    */

    INSERT INTO Fact.FactSales
    (
        OrderDetailID,
        OrderID,
        OrderDateKey,
        CustomerKey,
        ProductKey,
        BranchKey,
        EmployeeKey,
        OrderDateTime,
        OrderHour,
        OrderStatus,
        Quantity,
        UnitPrice,
        UnitCost,
        DiscountPercent,
        GrossSales,
        DiscountAmount,
        NetSales,
        TotalCost,
        Profit
    )

    SELECT
        OD.OrderDetailID,

        O.OrderID,

        DD.DateKey,

        DC.CustomerKey,

        DP.ProductKey,

        DB.BranchKey,

        DE.EmployeeKey,

        CAST
        (
            O.OrderDate
            AS DATETIME2(0)
        ) AS OrderDateTime,

        DATEPART
        (
            HOUR,
            O.OrderDate
        ) AS OrderHour,

        O.OrderStatus,

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

    FROM NovaRetail_OLTP.Sales.OrderDetails AS OD

    INNER JOIN NovaRetail_OLTP.Sales.Orders AS O
        ON O.OrderID = OD.OrderID

    INNER JOIN NovaRetail_OLTP.Production.Products AS P
        ON P.ProductID = OD.ProductID

    INNER JOIN Dim.DimDate AS DD
        ON DD.FullDate =
           CAST(O.OrderDate AS DATE)

    INNER JOIN Dim.DimCustomer AS DC
        ON DC.CustomerID = O.CustomerID

    INNER JOIN Dim.DimProduct AS DP
        ON DP.ProductID = OD.ProductID

    INNER JOIN Dim.DimBranch AS DB
        ON DB.BranchID = O.BranchID

    INNER JOIN Dim.DimEmployee AS DE
        ON DE.EmployeeID = O.EmployeeID;


    /*
    =====================================================
    14. Validate Loaded Data
    =====================================================
    */

    DECLARE @SourceCustomerCount BIGINT;
    DECLARE @SourceProductCount BIGINT;
    DECLARE @SourceBranchCount BIGINT;
    DECLARE @SourceEmployeeCount BIGINT;
    DECLARE @SourceSalesCount BIGINT;

    SELECT
        @SourceCustomerCount = COUNT_BIG(*)
    FROM NovaRetail_OLTP.Sales.Customers;

    SELECT
        @SourceProductCount = COUNT_BIG(*)
    FROM NovaRetail_OLTP.Production.Products;

    SELECT
        @SourceBranchCount = COUNT_BIG(*)
    FROM NovaRetail_OLTP.Sales.Branches;

    SELECT
        @SourceEmployeeCount = COUNT_BIG(*)
    FROM NovaRetail_OLTP.HumanResources.Employees;

    SELECT
        @SourceSalesCount = COUNT_BIG(*)
    FROM NovaRetail_OLTP.Sales.OrderDetails;


    IF
    (
        SELECT COUNT_BIG(*)
        FROM Dim.DimCustomer
    ) < @SourceCustomerCount
    BEGIN
        ;THROW 51004,
        'Customer dimension row count validation failed.',
        1;
    END;


    IF
    (
        SELECT COUNT_BIG(*)
        FROM Dim.DimProduct
    ) < @SourceProductCount
    BEGIN
        ;THROW 51005,
        'Product dimension row count validation failed.',
        1;
    END;


    IF
    (
        SELECT COUNT_BIG(*)
        FROM Dim.DimBranch
    ) < @SourceBranchCount
    BEGIN
        ;THROW 51006,
        'Branch dimension row count validation failed.',
        1;
    END;


    IF
    (
        SELECT COUNT_BIG(*)
        FROM Dim.DimEmployee
    ) < @SourceEmployeeCount
    BEGIN
        ;THROW 51007,
        'Employee dimension row count validation failed.',
        1;
    END;


    IF
    (
        SELECT COUNT_BIG(*)
        FROM Fact.FactSales
    ) <> @SourceSalesCount
    BEGIN
        ;THROW 51008,
        'FactSales row count does not match the source.',
        1;
    END;


    COMMIT TRANSACTION;

END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;

END CATCH;
GO


/*
=========================================================
15. ETL Load Summary
=========================================================
*/

SELECT
    'Dim.DimDate' AS TableName,
    COUNT_BIG(*) AS TotalRows
FROM Dim.DimDate

UNION ALL

SELECT
    'Dim.DimCustomer',
    COUNT_BIG(*)
FROM Dim.DimCustomer

UNION ALL

SELECT
    'Dim.DimProduct',
    COUNT_BIG(*)
FROM Dim.DimProduct

UNION ALL

SELECT
    'Dim.DimBranch',
    COUNT_BIG(*)
FROM Dim.DimBranch

UNION ALL

SELECT
    'Dim.DimEmployee',
    COUNT_BIG(*)
FROM Dim.DimEmployee

UNION ALL

SELECT
    'Fact.FactSales',
    COUNT_BIG(*)
FROM Fact.FactSales;
GO

/*
=========================================================
16. Preview Fact Table
=========================================================
*/

SELECT TOP (20)
    *
FROM Fact.FactSales
ORDER BY SalesKey;
GO


/*
=========================================================
17. Preview Star Schema Relationships
=========================================================
*/

SELECT TOP (20)
    F.OrderID,
    D.FullDate,
    C.CustomerName,
    P.ProductName,
    B.BranchName,
    E.EmployeeName,
    F.OrderStatus,
    F.Quantity,
    F.NetSales,
    F.Profit

FROM Fact.FactSales AS F

INNER JOIN Dim.DimDate AS D
    ON D.DateKey = F.OrderDateKey

INNER JOIN Dim.DimCustomer AS C
    ON C.CustomerKey = F.CustomerKey

INNER JOIN Dim.DimProduct AS P
    ON P.ProductKey = F.ProductKey

INNER JOIN Dim.DimBranch AS B
    ON B.BranchKey = F.BranchKey

INNER JOIN Dim.DimEmployee AS E
    ON E.EmployeeKey = F.EmployeeKey

ORDER BY
    F.OrderID,
    F.SalesKey;
GO