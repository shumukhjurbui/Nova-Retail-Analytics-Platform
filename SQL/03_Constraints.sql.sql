ALTER TABLE Production.Products
ADD CONSTRAINT CK_Products_UnitPrice
CHECK (UnitPrice >= 0);
GO

ALTER TABLE Production.Products
ADD CONSTRAINT CK_Products_UnitCost
CHECK (UnitCost >= 0);
GO

ALTER TABLE Production.Products
ADD CONSTRAINT CK_Products_Stock
CHECK (StockQuantity >= 0);
GO

ALTER TABLE HumanResources.Employees
ADD CONSTRAINT CK_Employees_Salary
CHECK (Salary > 0);
GO

ALTER TABLE Sales.OrderDetails
ADD CONSTRAINT CK_OrderDetails_Quantity
CHECK (Quantity > 0);
GO

ALTER TABLE Sales.OrderDetails
ADD CONSTRAINT CK_OrderDetails_UnitPrice
CHECK (UnitPrice >= 0);
GO

ALTER TABLE Sales.OrderDetails
ADD CONSTRAINT CK_OrderDetails_Discount
CHECK
(
    DiscountPercent >= 0
    AND DiscountPercent <= 100
);
GO

