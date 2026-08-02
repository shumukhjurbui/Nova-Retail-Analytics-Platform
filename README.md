# Nova Retail Analytics Platform

## Project Overview

Nova Retail Analytics Platform is an end-to-end retail data analytics project built using SQL Server and Power BI.

The project simulates a retail company with multiple branches, customers, employees, products, sales orders, and inventory data.

It demonstrates the complete data analytics workflow:

- Designing an OLTP database
- Generating realistic transactional data using T-SQL
- Performing data quality checks
- Writing business analysis queries
- Creating analytical views
- Building a Data Warehouse
- Implementing a Star Schema
- Developing an ETL process
- Creating performance indexes
- Building an interactive Power BI dashboard

---

## Business Objectives

The main goal of this project is to analyze retail performance and answer business questions such as:

- What are the total sales and profits?
- Which products generate the highest revenue?
- Which categories perform best?
- Which branches generate the most sales?
- Who are the highest-spending customers?
- Which employees achieve the highest sales?
- How do sales change over time?
- What is the order completion rate?
- What are the cancellation and return rates?
- Which products have low inventory levels?

---

## Tools and Technologies

- Microsoft SQL Server
- SQL Server Management Studio
- T-SQL
- Power BI Desktop
- Power Query
- DAX
- GitHub

---

## Project Architecture

The project contains two SQL Server databases.

### 1. OLTP Database

```text
NovaRetail_OLTP
```

This database stores operational retail data.

Main tables:

- `Lookup.Cities`
- `Sales.Branches`
- `Sales.Customers`
- `Sales.Orders`
- `Sales.OrderDetails`
- `Production.Categories`
- `Production.Products`
- `HumanResources.Employees`

### 2. Data Warehouse

```text
NovaRetail_DWH
```

This database uses a Star Schema designed for reporting and analytics.

Dimension tables:

- `Dim.DimDate`
- `Dim.DimCustomer`
- `Dim.DimProduct`
- `Dim.DimBranch`
- `Dim.DimEmployee`

Fact table:

- `Fact.FactSales`

The grain of `Fact.FactSales` is:

> One row for every product line inside a sales order.

---

## Data Volume

The project generates:

- 10 cities
- 5 branches
- 8 product categories
- 15 products
- 10 employees
- 200 customers
- 2,000 sales orders
- 7,000 order detail records

The transactional data is generated using T-SQL instead of manually inserting thousands of records.

---

## SQL Files

The SQL scripts should be executed in the following order:

| File | Description |
|---|---|
| `01_Create_OLTP.sql` | Creates the OLTP database, schemas, tables, primary keys, and foreign keys |
| `02_Insert_Data.sql` | Inserts cities, branches, categories, products, and employees |
| `03_Constraints.sql` | Adds data validation constraints |
| `04_Generate_Data.sql` | Generates customers, orders, and order details |
| `05_Data_Quality_Checks.sql` | Validates data quality and table relationships |
| `06_SQL_Analysis.sql` | Contains business and sales analysis queries |
| `07_Create_Views.sql` | Creates analytical reporting views |
| `08_Create_DWH.sql` | Creates the Data Warehouse and Star Schema |
| `09_Load_DWH.sql` | Extracts, transforms, and loads data into the DWH |
| `10_Create_Indexes.sql` | Creates performance indexes for OLTP and DWH tables |

---

## Data Quality Checks

The project includes validation queries for:

- Duplicate customer emails
- Duplicate employee emails
- Invalid foreign key relationships
- Orders without customers
- Orders without employees
- Orders without branches
- Order details without valid products
- Orders created before customer registration
- Employee and branch mismatches
- Orders without order details
- Duplicate products inside the same order
- Invalid quantities
- Negative prices
- Invalid discounts
- Invalid stock quantities

---

## SQL Analysis

The SQL analysis includes:

- Overall business KPIs
- Order status distribution
- Monthly sales trends
- Category performance
- Top products by net sales
- Product ranking using window functions
- Branch performance
- Employee sales performance
- Sales by customer city
- Top customers by spending
- Average order value
- Discount analysis
- Sales by day of week
- Sales by hour
- Inventory status
- Cancellation and return rates

---

## ETL Process

The ETL workflow transfers data from:

```text
NovaRetail_OLTP
```

to:

```text
NovaRetail_DWH
```

The process includes:

### Extract

Data is extracted from the OLTP tables.

### Transform

The transformation process:

- Combines operational tables
- Generates surrogate keys
- Calculates gross sales
- Calculates discount amounts
- Calculates net sales
- Calculates total cost
- Calculates profit
- Creates date attributes

### Load

The transformed data is loaded into dimension and fact tables.

The ETL script also validates row counts after the loading process.

---

## Power BI Data Model

Power BI connects to the `NovaRetail_DWH` database using Import mode.

The model contains five one-to-many relationships:

```text
DimDate[DateKey]
1 ─────────── * FactSales[OrderDateKey]

DimCustomer[CustomerKey]
1 ─────────── * FactSales[CustomerKey]

DimProduct[ProductKey]
1 ─────────── * FactSales[ProductKey]

DimBranch[BranchKey]
1 ─────────── * FactSales[BranchKey]

DimEmployee[EmployeeKey]
1 ─────────── * FactSales[EmployeeKey]
```

The relationship direction is single from each dimension table to the fact table.

---

## DAX Measures

The Power BI report includes the following measures:

- Total Orders
- Completed Orders
- Pending Orders
- Cancelled Orders
- Returned Orders
- Completion Rate
- Purchasing Customers
- Total Units Sold
- Gross Sales
- Total Discount
- Net Sales
- Total Cost
- Total Profit
- Profit Margin
- Discount Rate
- Average Order Value
- Average Units per Order

---

## Dashboard Pages

### Executive Sales Overview

This page provides an executive summary of retail performance.

It includes:

- Net Sales
- Total Profit
- Profit Margin
- Total Orders
- Average Order Value
- Total Units Sold
- Monthly Net Sales Trend
- Net Sales by Category
- Net Sales by Branch
- Top 5 Products by Net Sales
- Order Status Distribution

Filters:

- Year
- Branch
- Category
- Order Status

![Executive Sales Overview](images/executive-sales-overview.png)

---

### Product & Customer Analysis

This page provides detailed analysis of products, customers, cities, and employees.

It includes:

- Product Performance Details
- Top 10 Customers by Spending
- Net Sales by Customer City
- Top 5 Employees by Net Sales

Filters:

- Year
- Branch
- Category
- Customer City

![Product and Customer Analysis](images/product-customer-analysis.png)

---

## Key Business Insights

The dashboard helps management:

- Identify the most profitable products
- Compare branch sales performance
- Monitor order completion and cancellation rates
- Recognize high-value customers
- Evaluate employee performance
- Detect low-stock products
- Track monthly sales trends
- Analyze category profitability
- Improve inventory and sales decisions

---

## Project Folder Structure

```text
Nova-Retail-Analytics-Platform
│
├── sql
│   ├── 01_Create_OLTP.sql
│   ├── 02_Insert_Data.sql
│   ├── 03_Constraints.sql
│   ├── 04_Generate_Data.sql
│   ├── 05_Data_Quality_Checks.sql
│   ├── 06_SQL_Analysis.sql
│   ├── 07_Create_Views.sql
│   ├── 08_Create_DWH.sql
│   ├── 09_Load_DWH.sql
│   └── 10_Create_Indexes.sql
│
├── power-bi
│   └── Nova_Retail_Analytics_Dashboard.pbix
│
├── images
│   ├── executive-sales-overview.png
│   └── product-customer-analysis.png
│
│
└── README.md
```

---

## How to Run the Project

1. Open SQL Server Management Studio.
2. Execute the SQL files in numerical order.
3. Confirm that both databases were created:
   - `NovaRetail_OLTP`
   - `NovaRetail_DWH`
4. Run the data quality checks.
5. Open the Power BI file.
6. Update the SQL Server data source if required.
7. Refresh the Power BI model.

---

## Skills Demonstrated

This project demonstrates practical knowledge of:

- Relational database design
- Database normalization
- Primary and foreign keys
- Constraints
- T-SQL data generation
- Joins and aggregations
- Common Table Expressions
- Window functions
- Analytical SQL
- Data quality validation
- Views
- Data Warehousing
- Star Schema design
- ETL development
- Indexing
- Power Query
- DAX
- Data modeling
- Dashboard design
- Business analysis

---

## Author

Shumukh Jurbui
Data Analyst Portfolio Project
