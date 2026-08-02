/*
=========================================================
Project Name : Nova Retail Analytics Platform
Database     : NovaRetail_OLTP
Author       : Your Name
SQL Server   : Microsoft SQL Server
Version      : 1.0
Description  : Create OLTP Database Structure
=========================================================
*/

-- Create Database
CREATE DATABASE NovaRetail_OLTP;
GO

-- Switch to Database
USE NovaRetail_OLTP;
GO

-- Create Schemas

CREATE SCHEMA Lookup;
GO

CREATE SCHEMA Sales;
GO

CREATE SCHEMA Production;
GO

CREATE SCHEMA HumanResources;
GO

CREATE TABLE Lookup.Cities
(
    CityID INT IDENTITY(1,1) NOT NULL,
    CityName NVARCHAR(100) NOT NULL,
    Region NVARCHAR(50) NOT NULL,

    CONSTRAINT PK_Cities
        PRIMARY KEY CLUSTERED (CityID),

    CONSTRAINT UQ_Cities_CityName
        UNIQUE (CityName)
);
GO

CREATE TABLE Sales.Branches
(
    BranchID INT IDENTITY(1,1) NOT NULL,
    BranchName NVARCHAR(100) NOT NULL,
    CityID INT NOT NULL,
    Address NVARCHAR(250) NOT NULL,
    Phone VARCHAR(20) NULL,
    OpeningDate DATE NOT NULL,
    IsActive BIT NOT NULL
        CONSTRAINT DF_Branches_IsActive DEFAULT (1),

    CONSTRAINT PK_Branches
        PRIMARY KEY CLUSTERED (BranchID),

    CONSTRAINT FK_Branches_Cities
        FOREIGN KEY (CityID)
        REFERENCES Lookup.Cities(CityID)
);
GO

/*
=========================================================
Table: Production.Categories
Description: Stores product categories
=========================================================
*/

CREATE TABLE Production.Categories
(
    CategoryID INT IDENTITY(1,1) NOT NULL,

    CategoryName NVARCHAR(100) NOT NULL,

    Description NVARCHAR(300) NULL,

    IsActive BIT NOT NULL
        CONSTRAINT DF_Categories_IsActive
        DEFAULT (1),

    CONSTRAINT PK_Categories
        PRIMARY KEY CLUSTERED (CategoryID),

    CONSTRAINT UQ_Categories_CategoryName
        UNIQUE (CategoryName)
);
GO

/*
=========================================================
Table: Production.Products
Description: Stores products information
=========================================================
*/

CREATE TABLE Production.Products
(
    ProductID INT IDENTITY(1,1) NOT NULL,

    ProductName NVARCHAR(150) NOT NULL,

    CategoryID INT NOT NULL,

    UnitPrice DECIMAL(10,2) NOT NULL,

    UnitCost DECIMAL(10,2) NOT NULL,

    StockQuantity INT NOT NULL
        CONSTRAINT DF_Products_Stock DEFAULT (0),

    IsActive BIT NOT NULL
        CONSTRAINT DF_Products_IsActive DEFAULT (1),

    CONSTRAINT PK_Products
        PRIMARY KEY CLUSTERED (ProductID),

    CONSTRAINT FK_Products_Categories
        FOREIGN KEY (CategoryID)
        REFERENCES Production.Categories(CategoryID)
);
GO

/*
=========================================================
Table: HumanResources.Employees
Description: Stores employees information
=========================================================
*/

CREATE TABLE HumanResources.Employees
(
    EmployeeID INT IDENTITY(1,1) NOT NULL,

    FirstName NVARCHAR(100) NOT NULL,

    LastName NVARCHAR(100) NOT NULL,

    Email NVARCHAR(150) NOT NULL,

    Phone VARCHAR(20) NULL,

    HireDate DATE NOT NULL,

    Salary DECIMAL(10,2) NOT NULL,

    BranchID INT NOT NULL,

    IsActive BIT NOT NULL
        CONSTRAINT DF_Employees_IsActive DEFAULT (1),

    CONSTRAINT PK_Employees
        PRIMARY KEY CLUSTERED (EmployeeID),

    CONSTRAINT UQ_Employees_Email
        UNIQUE (Email),

    CONSTRAINT FK_Employees_Branches
        FOREIGN KEY (BranchID)
        REFERENCES Sales.Branches(BranchID)
);
GO

/*
=========================================================
Table: Sales.Customers
Description: Stores customer information
=========================================================
*/

CREATE TABLE Sales.Customers
(
    CustomerID INT IDENTITY(1,1) NOT NULL,

    FirstName NVARCHAR(100) NOT NULL,

    LastName NVARCHAR(100) NOT NULL,

    Email NVARCHAR(150) NOT NULL,

    Phone VARCHAR(20) NULL,

    CityID INT NOT NULL,

    RegistrationDate DATE NOT NULL,

    IsActive BIT NOT NULL
        CONSTRAINT DF_Customers_IsActive DEFAULT (1),

    CONSTRAINT PK_Customers
        PRIMARY KEY CLUSTERED (CustomerID),

    CONSTRAINT UQ_Customers_Email
        UNIQUE (Email),

    CONSTRAINT FK_Customers_Cities
        FOREIGN KEY (CityID)
        REFERENCES Lookup.Cities(CityID)
);
GO

/*
=========================================================
Table: Sales.Orders
Description: Stores sales orders
=========================================================
*/

CREATE TABLE Sales.Orders
(
    OrderID INT IDENTITY(1,1) NOT NULL,

    CustomerID INT NOT NULL,

    EmployeeID INT NOT NULL,

    BranchID INT NOT NULL,

    OrderDate DATETIME NOT NULL,

    OrderStatus NVARCHAR(30) NOT NULL,

    CONSTRAINT PK_Orders
        PRIMARY KEY CLUSTERED (OrderID),

    CONSTRAINT FK_Orders_Customers
        FOREIGN KEY (CustomerID)
        REFERENCES Sales.Customers(CustomerID),

    CONSTRAINT FK_Orders_Employees
        FOREIGN KEY (EmployeeID)
        REFERENCES HumanResources.Employees(EmployeeID),

    CONSTRAINT FK_Orders_Branches
        FOREIGN KEY (BranchID)
        REFERENCES Sales.Branches(BranchID)
);
GO

/*
=========================================================
Table: Sales.OrderDetails
Description: Stores products for each order
=========================================================
*/

CREATE TABLE Sales.OrderDetails
(
    OrderDetailID INT IDENTITY(1,1) NOT NULL,

    OrderID INT NOT NULL,

    ProductID INT NOT NULL,

    Quantity INT NOT NULL,

    UnitPrice DECIMAL(10,2) NOT NULL,

    DiscountPercent DECIMAL(5,2) NOT NULL
        CONSTRAINT DF_OrderDetails_Discount DEFAULT (0),

    CONSTRAINT PK_OrderDetails
        PRIMARY KEY CLUSTERED (OrderDetailID),

    CONSTRAINT FK_OrderDetails_Orders
        FOREIGN KEY (OrderID)
        REFERENCES Sales.Orders(OrderID),

    CONSTRAINT FK_OrderDetails_Products
        FOREIGN KEY (ProductID)
        REFERENCES Production.Products(ProductID)
);
GO

