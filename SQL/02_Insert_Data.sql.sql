/*
=========================================================
Insert Cities
=========================================================
*/

INSERT INTO Lookup.Cities
(
    CityName,
    Region
)
VALUES
('Riyadh','Central'),
('Jeddah','Western'),
('Makkah','Western'),
('Madinah','Western'),
('Dammam','Eastern'),
('Khobar','Eastern'),
('Tabuk','Northern'),
('Abha','Southern'),
('Hail','Northern'),
('Jazan','Southern');
GO

/*
=========================================================
Insert Branches
=========================================================
*/

INSERT INTO Sales.Branches
(
    BranchName,
    CityID,
    Address,
    Phone,
    OpeningDate,
    IsActive
)
VALUES
('Riyadh Main Branch',1,'King Fahd Road','0111111111','2020-01-15',1),

('Jeddah Branch',2,'Prince Sultan Road','0122222222','2020-05-01',1),

('Madinah Branch',4,'Quba Road','0143333333','2021-03-10',1),

('Dammam Branch',5,'King Saud Road','0134444444','2021-08-22',1),

('Abha Branch',8,'Airport Road','0175555555','2022-02-12',1);
GO

/*
=========================================================
Insert Categories
=========================================================
*/

INSERT INTO Production.Categories
(
    CategoryName,
    Description,
    IsActive
)
VALUES
('Electronics','Electronic devices and accessories',1),

('Home Appliances','Appliances for home use',1),

('Furniture','Home and office furniture',1),

('Clothing','Men and women clothing',1),

('Sports','Sports equipment',1),

('Books','Books and educational materials',1),

('Beauty','Beauty and personal care',1),

('Toys','Kids toys and games',1);
GO

/*
=========================================================
Insert Products
=========================================================
*/

INSERT INTO Production.Products
(
    ProductName,
    CategoryID,
    UnitPrice,
    UnitCost,
    StockQuantity,
    IsActive
)
VALUES

('Laptop Dell Inspiron',1,3200,2700,45,1),

('Apple iPhone 16',1,4500,3900,30,1),

('Samsung TV 55 Inch',2,2800,2300,20,1),

('Office Chair',3,650,450,60,1),

('Wooden Desk',3,1200,850,25,1),

('Men T-Shirt',4,90,45,150,1),

('Women Jacket',4,220,120,90,1),

('Football',5,80,45,120,1),

('Treadmill',5,3200,2600,12,1),

('SQL Fundamentals Book',6,150,90,70,1),

('Power BI Guide',6,180,100,50,1),

('Face Cream',7,130,70,100,1),

('Perfume',7,280,160,80,1),

('Toy Car',8,75,35,140,1),

('Building Blocks',8,140,75,95,1);
GO

/*
=========================================================
Insert Employees
=========================================================
*/

INSERT INTO HumanResources.Employees
(
    FirstName,
    LastName,
    Email,
    Phone,
    HireDate,
    Salary,
    BranchID,
    IsActive
)
VALUES

('Ahmed','Ali','ahmed.ali@novaretail.com','0501111111','2022-01-15',8500,1,1),

('Sara','Mohammed','sara.m@novaretail.com','0502222222','2021-08-10',9200,1,1),

('Khalid','Omar','khalid.o@novaretail.com','0503333333','2023-02-18',7800,2,1),

('Noura','Saad','noura.s@novaretail.com','0504444444','2022-06-11',8100,2,1),

('Faisal','Hassan','faisal.h@novaretail.com','0505555555','2020-09-01',9900,3,1),

('Mona','Salem','mona.s@novaretail.com','0506666666','2024-01-12',7200,3,1),

('Yousef','Ibrahim','yousef.i@novaretail.com','0507777777','2021-11-09',8600,4,1),

('Laila','Adel','laila.a@novaretail.com','0508888888','2023-05-20',7700,4,1),

('Omar','Nasser','omar.n@novaretail.com','0509999999','2022-03-01',8300,5,1),

('Reem','Khaled','reem.k@novaretail.com','0501234567','2024-02-15',7000,5,1);
GO

