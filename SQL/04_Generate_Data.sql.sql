/*
=========================================================
Project Name : Nova Retail Analytics Platform
File Name    : 04_Generate_Data.sql
Database     : NovaRetail_OLTP
Description  : Generate deterministic transactional data
=========================================================
*/

USE NovaRetail_OLTP;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY

    BEGIN TRANSACTION;

    /*
    =====================================================
    1. Prevent duplicate generation
    =====================================================
    */

    IF EXISTS (SELECT 1 FROM Sales.OrderDetails)
       OR EXISTS (SELECT 1 FROM Sales.Orders)
       OR EXISTS (SELECT 1 FROM Sales.Customers)
    BEGIN
        ;THROW 50001,
        'Customers, orders, or order details are not empty. Clean them before running this file.',
        1;
    END;


    /*
    =====================================================
    2. Check required master data
    =====================================================
    */

    IF (SELECT COUNT(*) FROM Lookup.Cities) < 10
    BEGIN
        ;THROW 50002, 'Cities data is missing.', 1;
    END;

    IF (SELECT COUNT(*) FROM Sales.Branches WHERE IsActive = 1) < 5
    BEGIN
        ;THROW 50003, 'Active branches data is missing.', 1;
    END;

    IF (SELECT COUNT(*) FROM Production.Products WHERE IsActive = 1) < 15
    BEGIN
        ;THROW 50004, 'Active products data is missing.', 1;
    END;

    IF (SELECT COUNT(*) FROM HumanResources.Employees WHERE IsActive = 1) < 10
    BEGIN
        ;THROW 50005, 'Active employees data is missing.', 1;
    END;


    /*
    =====================================================
    3. Generate exactly 200 customers
    =====================================================
    */

    ;WITH FirstNames AS
    (
        SELECT FirstNameID, FirstName
        FROM
        (
            VALUES
                (1,  N'Ahmed'),
                (2,  N'Mohammed'),
                (3,  N'Abdullah'),
                (4,  N'Khalid'),
                (5,  N'Omar'),
                (6,  N'Faisal'),
                (7,  N'Yousef'),
                (8,  N'Ibrahim'),
                (9,  N'Salman'),
                (10, N'Nawaf'),
                (11, N'Sara'),
                (12, N'Noura'),
                (13, N'Reem'),
                (14, N'Laila'),
                (15, N'Huda'),
                (16, N'Abeer'),
                (17, N'Razan'),
                (18, N'Fatimah'),
                (19, N'Mona'),
                (20, N'Amal')
        ) AS F(FirstNameID, FirstName)
    ),

    LastNames AS
    (
        SELECT LastNameID, LastName
        FROM
        (
            VALUES
                (1,  N'AlHarbi'),
                (2,  N'AlQahtani'),
                (3,  N'AlOtaibi'),
                (4,  N'AlMutairi'),
                (5,  N'AlZahrani'),
                (6,  N'AlGhamdi'),
                (7,  N'AlShammari'),
                (8,  N'AlAnazi'),
                (9,  N'AlDosari'),
                (10, N'AlJuhani')
        ) AS L(LastNameID, LastName)
    ),

    CityMap AS
    (
        SELECT
            CityID,

            ROW_NUMBER() OVER
            (
                ORDER BY CityID
            ) AS CitySequence

        FROM Lookup.Cities
    )

    INSERT INTO Sales.Customers
    (
        FirstName,
        LastName,
        Email,
        Phone,
        CityID,
        RegistrationDate,
        IsActive
    )

    SELECT
        F.FirstName,

        L.LastName,

        LOWER
        (
            CONCAT
            (
                F.FirstName,
                '.',
                L.LastName,
                RIGHT
                (
                    '000' + CAST(C.CustomerNumber AS VARCHAR(3)),
                    3
                ),
                '@novacustomer.com'
            )
        ) AS Email,

        CONCAT
        (
            '05',
            RIGHT
            (
                '00000000'
                + CAST(10000000 + C.CustomerNumber AS VARCHAR(8)),
                8
            )
        ) AS Phone,

        CM.CityID,

        DATEADD
        (
            DAY,
            (C.CustomerNumber * 13) % 730,
            CAST('2023-01-01' AS DATE)
        ) AS RegistrationDate,

        1 AS IsActive

    FROM FirstNames AS F

    CROSS JOIN LastNames AS L

    CROSS APPLY
    (
        VALUES
        (
            ((F.FirstNameID - 1) * 10) + L.LastNameID
        )
    ) AS C(CustomerNumber)

    INNER JOIN CityMap AS CM
        ON CM.CitySequence =
           ((C.CustomerNumber - 1) % 10) + 1;


    /*
    =====================================================
    4. Create temporary maps
    =====================================================
    */

    SELECT
        ROW_NUMBER() OVER
        (
            ORDER BY CustomerID
        ) AS CustomerSequence,

        CustomerID,
        RegistrationDate

    INTO #CustomerMap

    FROM Sales.Customers;


    SELECT
        ROW_NUMBER() OVER
        (
            ORDER BY BranchID
        ) AS BranchSequence,

        BranchID

    INTO #BranchMap

    FROM Sales.Branches

    WHERE IsActive = 1;


    SELECT
        BranchID,
        COUNT(*) AS EmployeeCount

    INTO #EmployeeCounts

    FROM HumanResources.Employees

    WHERE IsActive = 1

    GROUP BY BranchID;


    SELECT
        BranchID,
        EmployeeID,

        ROW_NUMBER() OVER
        (
            PARTITION BY BranchID
            ORDER BY EmployeeID
        ) AS EmployeeSequence

    INTO #EmployeeMap

    FROM HumanResources.Employees

    WHERE IsActive = 1;


    IF EXISTS
    (
        SELECT 1

        FROM #BranchMap AS B

        LEFT JOIN #EmployeeCounts AS EC
            ON EC.BranchID = B.BranchID

        WHERE EC.BranchID IS NULL
    )
    BEGIN
        ;THROW 50006,
        'At least one active branch does not have an active employee.',
        1;
    END;


    DECLARE @CustomerCount INT;
    DECLARE @BranchCount INT;
    DECLARE @OrderEndDate DATE;

    SELECT
        @CustomerCount = COUNT(*)
    FROM #CustomerMap;

    SELECT
        @BranchCount = COUNT(*)
    FROM #BranchMap;

    SET @OrderEndDate = '2026-07-31';


    /*
    =====================================================
    5. Generate exactly 2,000 orders
    =====================================================
    */

    ;WITH Digits AS
    (
        SELECT Digit
        FROM
        (
            VALUES
                (0), (1), (2), (3), (4),
                (5), (6), (7), (8), (9)
        ) AS D(Digit)
    ),

    Numbers AS
    (
        SELECT
            D0.Digit
            + (D1.Digit * 10)
            + (D2.Digit * 100)
            + (D3.Digit * 1000)
            + 1 AS Number

        FROM Digits AS D0
        CROSS JOIN Digits AS D1
        CROSS JOIN Digits AS D2
        CROSS JOIN Digits AS D3

        WHERE
            D0.Digit
            + (D1.Digit * 10)
            + (D2.Digit * 100)
            + (D3.Digit * 1000) < 2000
    ),

    OrderSource AS
    (
        SELECT
            Number,

            1 + (((Number * 73) - 1) % @CustomerCount)
                AS CustomerSequence,

            1 + (((Number * 7) - 1) % @BranchCount)
                AS BranchSequence,

            (Number * 37) % 100
                AS StatusRoll

        FROM Numbers
    )

    INSERT INTO Sales.Orders
    (
        CustomerID,
        EmployeeID,
        BranchID,
        OrderDate,
        OrderStatus
    )

    SELECT
        C.CustomerID,

        E.EmployeeID,

        B.BranchID,

        DATEADD
        (
            MINUTE,
            (O.Number * 97) % 1440,

            DATEADD
            (
                DAY,

                (O.Number * 29)
                %
                (
                    DATEDIFF
                    (
                        DAY,
                        C.RegistrationDate,
                        @OrderEndDate
                    ) + 1
                ),

                CAST(C.RegistrationDate AS DATETIME)
            )
        ) AS OrderDate,

        CASE
            WHEN O.StatusRoll < 82 THEN N'Completed'
            WHEN O.StatusRoll < 90 THEN N'Pending'
            WHEN O.StatusRoll < 96 THEN N'Cancelled'
            ELSE N'Returned'
        END AS OrderStatus

    FROM OrderSource AS O

    INNER JOIN #CustomerMap AS C
        ON C.CustomerSequence = O.CustomerSequence

    INNER JOIN #BranchMap AS B
        ON B.BranchSequence = O.BranchSequence

    INNER JOIN #EmployeeCounts AS EC
        ON EC.BranchID = B.BranchID

    INNER JOIN #EmployeeMap AS E
        ON E.BranchID = B.BranchID

       AND E.EmployeeSequence =
           1 + ((O.Number - 1) % EC.EmployeeCount);


    /*
    =====================================================
    6. Create order and product maps
    =====================================================
    */

    SELECT
        ROW_NUMBER() OVER
        (
            ORDER BY OrderID
        ) AS OrderSequence,

        OrderID

    INTO #OrderMap

    FROM Sales.Orders;


    SELECT
        ROW_NUMBER() OVER
        (
            ORDER BY ProductID
        ) AS ProductSequence,

        ProductID,
        UnitPrice

    INTO #ProductMap

    FROM Production.Products

    WHERE IsActive = 1;


    DECLARE @ProductCount INT;

    SELECT
        @ProductCount = COUNT(*)
    FROM #ProductMap;


    /*
    =====================================================
    7. Generate exactly 7,000 order details

       1,000 orders have 3 products
       1,000 orders have 4 products
    =====================================================
    */

    ;WITH DetailNumbers AS
    (
        SELECT DetailNumber
        FROM
        (
            VALUES
                (1),
                (2),
                (3),
                (4)
        ) AS D(DetailNumber)
    ),

    DetailSlots AS
    (
        SELECT
            O.OrderSequence,
            O.OrderID,
            D.DetailNumber

        FROM #OrderMap AS O

        CROSS JOIN DetailNumbers AS D

        WHERE D.DetailNumber <=
              3 + (O.OrderSequence % 2)
    ),

    DetailSource AS
    (
        SELECT
            OrderSequence,
            OrderID,
            DetailNumber,

            1 +
            (
                (
                    (OrderSequence * 7)
                    + (DetailNumber * 4)
                    - 1
                ) % @ProductCount
            ) AS ProductSequence,

            (
                (OrderSequence * 17)
                + (DetailNumber * 23)
            ) % 100 AS DiscountRoll

        FROM DetailSlots
    )

    INSERT INTO Sales.OrderDetails
    (
        OrderID,
        ProductID,
        Quantity,
        UnitPrice,
        DiscountPercent
    )

    SELECT
        D.OrderID,

        P.ProductID,

        1 +
        (
            (
                D.OrderSequence
                * D.DetailNumber
                * 11
            ) % 4
        ) AS Quantity,

        P.UnitPrice,

        CASE
            WHEN D.DiscountRoll < 60 THEN 0
            WHEN D.DiscountRoll < 78 THEN 5
            WHEN D.DiscountRoll < 90 THEN 10
            WHEN D.DiscountRoll < 97 THEN 15
            ELSE 20
        END AS DiscountPercent

    FROM DetailSource AS D

    INNER JOIN #ProductMap AS P
        ON P.ProductSequence = D.ProductSequence;


    /*
    =====================================================
    8. Validate generated row counts
    =====================================================
    */

    IF (SELECT COUNT(*) FROM Sales.Customers) <> 200
    BEGIN
        ;THROW 50007,
        'Customer generation failed. Expected exactly 200 customers.',
        1;
    END;

    IF (SELECT COUNT(*) FROM Sales.Orders) <> 2000
    BEGIN
        ;THROW 50008,
        'Order generation failed. Expected exactly 2000 orders.',
        1;
    END;

    IF (SELECT COUNT(*) FROM Sales.OrderDetails) <> 7000
    BEGIN
        ;THROW 50009,
        'Order detail generation failed. Expected exactly 7000 rows.',
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
9. Verify final results
=========================================================
*/

SELECT
    (SELECT COUNT(*) FROM Sales.Customers)
        AS TotalCustomers,

    (SELECT COUNT(*) FROM Sales.Orders)
        AS TotalOrders,

    (SELECT COUNT(*) FROM Sales.OrderDetails)
        AS TotalOrderDetails;
GO