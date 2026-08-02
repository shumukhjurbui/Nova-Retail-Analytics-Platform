/*
=========================================================
Project Name : Nova Retail Analytics Platform
File Name    : 08_Create_DWH.sql
Database     : NovaRetail_DWH
Description  : Create Data Warehouse Star Schema
=========================================================
*/


/*
=========================================================
1. Create Data Warehouse Database
=========================================================
*/

USE master;
GO

IF DB_ID(N'NovaRetail_DWH') IS NULL
BEGIN
    EXEC
    (
        N'CREATE DATABASE NovaRetail_DWH;'
    );
END;
GO


/*
=========================================================
2. Switch to Data Warehouse
=========================================================
*/

USE NovaRetail_DWH;
GO


/*
=========================================================
3. Create Schemas
=========================================================
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = N'Dim'
)
BEGIN
    EXEC
    (
        N'CREATE SCHEMA Dim AUTHORIZATION dbo;'
    );
END;
GO


IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = N'Fact'
)
BEGIN
    EXEC
    (
        N'CREATE SCHEMA Fact AUTHORIZATION dbo;'
    );
END;
GO


/*
=========================================================
4. Create Date Dimension
=========================================================
*/

IF OBJECT_ID(N'Dim.DimDate', N'U') IS NULL
BEGIN

    CREATE TABLE Dim.DimDate
    (
        DateKey INT NOT NULL,

        FullDate DATE NOT NULL,

        CalendarYear SMALLINT NOT NULL,

        CalendarQuarter TINYINT NOT NULL,

        MonthNumber TINYINT NOT NULL,

        MonthName NVARCHAR(20) NOT NULL,

        YearMonth CHAR(7) NOT NULL,

        DayOfMonth TINYINT NOT NULL,

        DayOfWeekNumber TINYINT NOT NULL,

        DayName NVARCHAR(20) NOT NULL,

        IsWeekend BIT NOT NULL,

        CONSTRAINT PK_DimDate
            PRIMARY KEY CLUSTERED (DateKey),

        CONSTRAINT UQ_DimDate_FullDate
            UNIQUE (FullDate),

        CONSTRAINT CK_DimDate_Quarter
            CHECK (CalendarQuarter BETWEEN 1 AND 4),

        CONSTRAINT CK_DimDate_Month
            CHECK (MonthNumber BETWEEN 1 AND 12),

        CONSTRAINT CK_DimDate_Day
            CHECK (DayOfMonth BETWEEN 1 AND 31)
    );

END;
GO


/*
=========================================================
5. Create Customer Dimension
=========================================================
*/

IF OBJECT_ID(N'Dim.DimCustomer', N'U') IS NULL
BEGIN

    CREATE TABLE Dim.DimCustomer
    (
        CustomerKey INT IDENTITY(1,1) NOT NULL,

        CustomerID INT NOT NULL,

        FirstName NVARCHAR(100) NOT NULL,

        LastName NVARCHAR(100) NOT NULL,

        CustomerName NVARCHAR(201) NOT NULL,

        Email NVARCHAR(150) NOT NULL,

        Phone VARCHAR(20) NULL,

        CityID INT NOT NULL,

        CityName NVARCHAR(100) NOT NULL,

        Region NVARCHAR(50) NOT NULL,

        RegistrationDate DATE NOT NULL,

        IsActive BIT NOT NULL,

        DWLoadDate DATETIME2(0) NOT NULL
            CONSTRAINT DF_DimCustomer_DWLoadDate
            DEFAULT (SYSDATETIME()),

        CONSTRAINT PK_DimCustomer
            PRIMARY KEY CLUSTERED (CustomerKey),

        CONSTRAINT UQ_DimCustomer_CustomerID
            UNIQUE (CustomerID)
    );

END;
GO


/*
=========================================================
6. Create Product Dimension
=========================================================
*/

IF OBJECT_ID(N'Dim.DimProduct', N'U') IS NULL
BEGIN

    CREATE TABLE Dim.DimProduct
    (
        ProductKey INT IDENTITY(1,1) NOT NULL,

        ProductID INT NOT NULL,

        ProductName NVARCHAR(150) NOT NULL,

        CategoryID INT NOT NULL,

        CategoryName NVARCHAR(100) NOT NULL,

        CurrentUnitPrice DECIMAL(10,2) NOT NULL,

        UnitCost DECIMAL(10,2) NOT NULL,

        StockQuantity INT NOT NULL,

        IsActive BIT NOT NULL,

        DWLoadDate DATETIME2(0) NOT NULL
            CONSTRAINT DF_DimProduct_DWLoadDate
            DEFAULT (SYSDATETIME()),

        CONSTRAINT PK_DimProduct
            PRIMARY KEY CLUSTERED (ProductKey),

        CONSTRAINT UQ_DimProduct_ProductID
            UNIQUE (ProductID),

        CONSTRAINT CK_DimProduct_UnitPrice
            CHECK (CurrentUnitPrice >= 0),

        CONSTRAINT CK_DimProduct_UnitCost
            CHECK (UnitCost >= 0),

        CONSTRAINT CK_DimProduct_Stock
            CHECK (StockQuantity >= 0)
    );

END;
GO


/*
=========================================================
7. Create Branch Dimension
=========================================================
*/

IF OBJECT_ID(N'Dim.DimBranch', N'U') IS NULL
BEGIN

    CREATE TABLE Dim.DimBranch
    (
        BranchKey INT IDENTITY(1,1) NOT NULL,

        BranchID INT NOT NULL,

        BranchName NVARCHAR(100) NOT NULL,

        CityID INT NOT NULL,

        CityName NVARCHAR(100) NOT NULL,

        Region NVARCHAR(50) NOT NULL,

        Address NVARCHAR(250) NOT NULL,

        Phone VARCHAR(20) NULL,

        OpeningDate DATE NOT NULL,

        IsActive BIT NOT NULL,

        DWLoadDate DATETIME2(0) NOT NULL
            CONSTRAINT DF_DimBranch_DWLoadDate
            DEFAULT (SYSDATETIME()),

        CONSTRAINT PK_DimBranch
            PRIMARY KEY CLUSTERED (BranchKey),

        CONSTRAINT UQ_DimBranch_BranchID
            UNIQUE (BranchID)
    );

END;
GO


/*
=========================================================
8. Create Employee Dimension
=========================================================
*/

IF OBJECT_ID(N'Dim.DimEmployee', N'U') IS NULL
BEGIN

    CREATE TABLE Dim.DimEmployee
    (
        EmployeeKey INT IDENTITY(1,1) NOT NULL,

        EmployeeID INT NOT NULL,

        FirstName NVARCHAR(100) NOT NULL,

        LastName NVARCHAR(100) NOT NULL,

        EmployeeName NVARCHAR(201) NOT NULL,

        Email NVARCHAR(150) NOT NULL,

        Phone VARCHAR(20) NULL,

        HireDate DATE NOT NULL,

        Salary DECIMAL(10,2) NOT NULL,

        BranchID INT NOT NULL,

        BranchName NVARCHAR(100) NOT NULL,

        IsActive BIT NOT NULL,

        DWLoadDate DATETIME2(0) NOT NULL
            CONSTRAINT DF_DimEmployee_DWLoadDate
            DEFAULT (SYSDATETIME()),

        CONSTRAINT PK_DimEmployee
            PRIMARY KEY CLUSTERED (EmployeeKey),

        CONSTRAINT UQ_DimEmployee_EmployeeID
            UNIQUE (EmployeeID),

        CONSTRAINT CK_DimEmployee_Salary
            CHECK (Salary > 0)
    );

END;
GO


/*
=========================================================
9. Create Sales Fact Table

Grain:
One row for every order detail/product line
=========================================================
*/

IF OBJECT_ID(N'Fact.FactSales', N'U') IS NULL
BEGIN

    CREATE TABLE Fact.FactSales
    (
        SalesKey BIGINT IDENTITY(1,1) NOT NULL,

        OrderDetailID INT NOT NULL,

        OrderID INT NOT NULL,

        OrderDateKey INT NOT NULL,

        CustomerKey INT NOT NULL,

        ProductKey INT NOT NULL,

        BranchKey INT NOT NULL,

        EmployeeKey INT NOT NULL,

        OrderDateTime DATETIME2(0) NOT NULL,

        OrderHour TINYINT NOT NULL,

        OrderStatus NVARCHAR(30) NOT NULL,

        Quantity INT NOT NULL,

        UnitPrice DECIMAL(10,2) NOT NULL,

        UnitCost DECIMAL(10,2) NOT NULL,

        DiscountPercent DECIMAL(5,2) NOT NULL,

        GrossSales DECIMAL(18,2) NOT NULL,

        DiscountAmount DECIMAL(18,2) NOT NULL,

        NetSales DECIMAL(18,2) NOT NULL,

        TotalCost DECIMAL(18,2) NOT NULL,

        Profit DECIMAL(18,2) NOT NULL,

        DWLoadDate DATETIME2(0) NOT NULL
            CONSTRAINT DF_FactSales_DWLoadDate
            DEFAULT (SYSDATETIME()),

        CONSTRAINT PK_FactSales
            PRIMARY KEY CLUSTERED (SalesKey),

        CONSTRAINT UQ_FactSales_OrderDetailID
            UNIQUE (OrderDetailID),

        CONSTRAINT FK_FactSales_DimDate
            FOREIGN KEY (OrderDateKey)
            REFERENCES Dim.DimDate(DateKey),

        CONSTRAINT FK_FactSales_DimCustomer
            FOREIGN KEY (CustomerKey)
            REFERENCES Dim.DimCustomer(CustomerKey),

        CONSTRAINT FK_FactSales_DimProduct
            FOREIGN KEY (ProductKey)
            REFERENCES Dim.DimProduct(ProductKey),

        CONSTRAINT FK_FactSales_DimBranch
            FOREIGN KEY (BranchKey)
            REFERENCES Dim.DimBranch(BranchKey),

        CONSTRAINT FK_FactSales_DimEmployee
            FOREIGN KEY (EmployeeKey)
            REFERENCES Dim.DimEmployee(EmployeeKey),

        CONSTRAINT CK_FactSales_OrderHour
            CHECK (OrderHour BETWEEN 0 AND 23),

        CONSTRAINT CK_FactSales_Quantity
            CHECK (Quantity > 0),

        CONSTRAINT CK_FactSales_UnitPrice
            CHECK (UnitPrice >= 0),

        CONSTRAINT CK_FactSales_UnitCost
            CHECK (UnitCost >= 0),

        CONSTRAINT CK_FactSales_Discount
            CHECK (DiscountPercent BETWEEN 0 AND 100),

        CONSTRAINT CK_FactSales_GrossSales
            CHECK (GrossSales >= 0),

        CONSTRAINT CK_FactSales_DiscountAmount
            CHECK (DiscountAmount >= 0),

        CONSTRAINT CK_FactSales_NetSales
            CHECK (NetSales >= 0),

        CONSTRAINT CK_FactSales_TotalCost
            CHECK (TotalCost >= 0)
    );

END;
GO


/*
=========================================================
10. Verify Created Tables
=========================================================
*/

SELECT
    S.name AS SchemaName,

    T.name AS TableName

FROM sys.tables AS T

INNER JOIN sys.schemas AS S
    ON S.schema_id = T.schema_id

WHERE S.name IN
(
    N'Dim',
    N'Fact'
)

ORDER BY
    S.name,
    T.name;
GO