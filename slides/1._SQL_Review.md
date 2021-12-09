# 1. SQL: basic concepts revisited + some extra advanced concepts

## 1.1 Introduction

- gebruiken hiervoor SQL server management studio van Microsoft
- gebruiken hiervoor meestal Nortwind databank als voorbeeld
- SQL bestaat uit 3 subtalen + features
  - DDL: `CREATE, ALTER, DROP`
  - DML: `SELECT, INSERT, UPDATE`
  - DCL: `GRANT, REVOKE, DENY`
  - operatoren, functies, control flows

The following statement:

```SQL
SELECT foo FROM bar JOIN quux WHERE x = y;
```

is made up of the following clauses:

- WHERE x = y
- SELECT foo
- FROM bar
- JOIN quux

## 1.2 Working with 1 table => SELECT, statistical functions, group by

```SQL
SELECT [ALL | DISTINCT] {*|  expression [, expression ...]}
FROM table name
[WHERE conditions(s)]
[GROUP BY column name [, column name ...]
[HAVING conditions(s)]
[ORDER BY {column name |seq nr}{ASC|DESC}[,...]
```

- SELECT clause: specifies the columns to show in the ouput.
- DISTINCT filters out duplicate lines–FROM clause: table name
- WHERE clause : filter condition on individual lines in the output
- GROUP BY : grouping of data
- HAVING clause : filter condition on groups
- ORDER BY clause : sorting

### 1.2.1 SELECT

- `SELECT *` = select all columns from table
- `SELECT col1, col2` = select specific columns from table

example:

```SQL
SELECT * 
FROM Products 
WHERE ProductName LIKE '_[a-s]%'
AND NOT CategoryID = 1;

SELECT * 
FROM Products 
WHERE UnitsInStock BETWEEN 0 AND 5
AND ReorderLevel in (0,5);
```

options:

- comparison operators: `=, >, >=, <, <=, <>`
- intervals: `BETWEEN, NOT BETWEEN`
- list values: `IN, NOT IN`
- unknown values: `IS NULL, IS NOT NULL`
- wildcards: `LIKE {pattern}`
  - %: 0,1,more char seq
  - _: 1 char
  - []: 1 char from range
  - ^[]: each char not in range
- logical operators: `OR, AND, NOT`

! `<>` ipv `!=` for NEQ

#### 1.2.1.1 SELECT ... ORDER BY

```SQL
SELECT * 
FROM Products 
ORDER BY UnitsInStock DESC;
```

#### 1.2.1.2 SELECT DISTINCT / ALL

> filters out duplicates lines in the output

#### 1.2.1.3 SELECT ALIASES

> The AS keyword allows you to give a column a new title

#### 1.2.1.4 EXERCICES

```SQL
-- 1. Give the names of all products containing the word 'bröd' or with a name of 7 characters.
SELECT ProductName AS 'Name of Product'
FROM Products 
WHERE ProductName LIKE '%bröd%' OR  ProductName LIKE '_______';

-- 2. Show the productnameand the reorderlevelof all products with a level between 10 and 50 (boundaries included)
SELECT ProductName AS 'Name of Product', ReorderLevel AS 'reorder level'
FROM Products 
WHERE ReorderLevel BETWEEN 10 AND 50;
```

#### 1.2.1.5 SELECT with calculated results

```SQL
SELECT ProductName, UnitPrice * UnitsInStock as InventoryValue
FROM Products 
WHERE UnitPrice * UnitsInStock BETWEEN 10 AND 500;
```

#### 1.2.1.5 SELECT with functions

- String functions: `left, right, len, ltrim, rtrim, substring, replace, ..`
- DateTime functions: `DateAdd, DateDiff, DatePart, Day, Month, Year`
  - GETDATE(): returns current date and time in DATETIME format specified
- Arithmetic functions: `round, floor, ceiling, cos, sin, ...`
- Aggregate functions: `AVG, SUM, ..`
- `ISNULL`: replaces NULL values with specified value
- Reference document: [link](msdn.microsoft.com/en-us/library/ms174318.aspx)

| String function      | SQL Server                                       |
| ----------- | -----------                                      |
| concatenate | `SELECT CONCAT(Address,' ',City) FROM Employees` |
| substring   | `SELECT SUBSTRING(Address, 1, 5) FROM Employees` |
| left part   | `SELECT LEFT(Address,5) FROM Employees` |
| right part   | `SELECT RIGHT(Address,5) FROM Employees` |
| length   | `SELECT LEN(Address) FROM Employees` |
| lowercase   | `SELECT LOWER(Address) FROM Employees` |
| uppercase   | `SELECT UPPER(Address) FROM Employees` |
| remove spaces  | `SELECT RTRIM(LTRIM(Address)) FROM Employees` |

| DateTime function      | SQL Server                                       |
| ----------- | -----------                                      |
| System date | `SELECT GETDATE()` `SELECT GETUTCDATE()` `SELECT SYSDATETIME()` `SELECT SYSDATETIMEOFFSET()` |
| Add years, months, days to date    | `SELECT DATEADD (year, 2, GETDATE())` |
| Number of years, months, days between 2 dates | `SELECT DATEDIFF(day,BIRTHDATE,GETDATE()) As NumberOfDays FROM Employees` |
| Day of the month   | `SELECT DAY(GETDATE())` |
| Month of the year   | `SELECT DATEADD (month, 2, GETDATE())` |
| year  | `SELECT DATEADD (day, 2, GETDATE())` |

| function      | SQL Server                                       |
| ----------- | -----------                                      |
| Absolute value  | `SELECT ABS(-10) -- 10` |
| Round to give number of decimals   | `SELECT ROUND(10.75, 1) -- 10.8` |
| Largest integer thas is lower   | `SELECT FLOOR(10.75) -- 10` |
| Smallest integer that is higher    | `SELECT CEILING(10.75) -- 11` |

```SQL
SELECT LOWER(ProductName) as 'product', ISNULL(UnitPrice, 0.0) as 'unit price'
FROM Products 
ORDER BY UnitPrice ASC;
```

#### 1.2.1.6 SELECT with data type conversion

- **implicit conversion** => eg. UnitsInStock * 0.5 UnitInStock (int) is automatically converted to decimal
- **explicit conversion**
  - `CAST (<value expression> as <data type>)`
  - `CONVERT (<data type, <expression> [, <style>])`
  - `FORMAT (<date column>, <format>)`

```SQL
PRINT CAST(-25.25 AS INTEGER); -- -25
SELECT CONVERT(VARCHAR,getdate(),106) As Today; -- 08 Dec 2021
SELECT * FROM Orders 
WHERE FORMAT(ShippedDate, 'MM/dd/yyyy') < '12/25/2016';
```

#### 1.2.1.7 SELECT with case function

```SQL
SELECT CONVERT(varchar(20), ProductName) As 'Shortened ProductName',
	CASE
		WHEN UnitPrice IS NULL THEN 'Not yet priced'
		WHEN UnitPrice < 10 THEN 'Very Reasonable Price'
		WHEN UnitPrice >= 10 and UnitPrice < 20 THEN 'Affordable'
		ELSE 'Expensive!'
		END AS 'Price Category'
FROM Products
ORDER BY UnitPrice
```

#### 1.2.1.8 SELECT and strings

- String operator: Concatenate

```SQL
SELECT STR(ProductID) + ',' + ProductName AS Product
FROM Products
```

- Use of literal text (literals)

```SQL
SELECT ProductName, '$' As Currency, Unitprice
FROM Products
```

### 1.2.2 Groupby + statistical functions

#### 1.2.2.1 statistical functions

functions:

- `SUM(expression)`
- `AVG(expression)`
- `MIN(expression)`
- `MAX(expression)`
- `COUNT(*|[DISTINCT] column name): count`
- MS Transact SQL expressions
  - `STDEV(expression)`
  - `VAR(expression)`
  - `TOP num column name`

> 1 answer per column never used in where clause

```SQL
SELECT SUM(UnitsInStock * UnitPrice) as 'Total Inventory Value'
FROM Products
--- 74050.85

SELECT AVG(UnitPrice) as 'Average unit price'
FROM Products
--- 28.8663

SELECT COUNT(*) as NumberOfProducts FROM Products;
--- number of rows
SELECT COUNT(CategoryID) as NumberOfCategoryID FROM Products;
--- number of rows with not null in category
SELECT COUNT(DISTINCT CategoryID) as NumberOfCategoryID FROM Products;
--- number of distinct not null categories

SELECT MIN(UnitPrice) AS Minimum, MAX(UnitPrice)AS Maximum 
FROM Products

--- 5 most expensive products
SELECT TOP 5 ProductName, UnitPrice
FROM Products
ORDER BY UnitPrice DESC
```

> because there is 1 result (1 row), each select expression must contain a statistical function. gebruikt met group by zijn meerdere resultaten mogelijk
> statistical functions disregard NULL values except for `COUNT(*)`

#### 1.2.2.1 group by and having

- per group a row
- statistical functions can be applied per group
- having is the where for group characteristics
- Statistical functions can only be used in SELECT, HAVING, ORDER BY -not in WHERE, GROUP BY

```SQL
--- Show the categories that contain more than 10 products with UnitPrice > 15
SELECT CategoryID, COUNT(ProductID) As NumberOfProductsPerCategory
FROM Products WHERE UnitPrice > 10
GROUP BY CategoryID HAVING COUNT(ProductID)> 10
```

#### 1.2.2.3 exercices

```SQL
-- 1. Count the amount of products (columnname 'amount of products'),
-- AND the amount of products in stock (= unitsinstock not empty) (columnname 'Units in stock')

SELECT 
	COUNT(DISTINCT ProductID) as 'amount of products', 
	SUM(UnitsInStock) as 'Units in stock'
FROM Products;

-- 2. How many employees have a function of Sales Representative (columnname 'Number of Sales Representative')?

SELECT 
	COUNT(DISTINCT EmployeeID) as 'Number of Sales Representative'
FROM Employees;

-- 3. Give the date of birth of the youngest employee (columnname 'Birthdate youngest') and the oldest (columnname 'Birthdate oldest').

SELECT 
	MAX(DISTINCT BirthDate) as 'Birthdate youngest',
	MIN(DISTINCT BirthDate) as 'Birthdate oldest'
FROM Employees;

-- 4. What's the number of employees who will retire (at 65) within the first 20 years?

SELECT 
	COUNT(DISTINCT EmployeeID) as 'employees retired within 20 years'
FROM Employees
WHERE DATEDIFF(year, BirthDate, DATEADD(year, 20, GETDATE())) >= 65;

SELECT 
	COUNT(DISTINCT EmployeeID) as 'employees retired within 20 years'
FROM Employees
WHERE DATEDIFF(year, BirthDate, GETDATE()) >= 45;

-- 5. Show a list of different countries where 2 of more suppliers are from. Order alphabeticaly.

SELECT Country, COUNT(SupplierID) as 'supplier count'
FROM Suppliers
GROUP BY Country
HAVING COUNT(SupplierID) >= 2;

-- 6. Which suppliers offer at least 5 products with a price less than 100 dollar? 
-- Show supplierId and the number of different products.
-- The supplier with the highest number of products comes first.

SELECT SupplierID, SUM(ProductID) as '# products offered under 100$'
FROM Products
WHERE UnitPrice < 100
GROUP BY SupplierID
HAVING SUM(ProductID) >= 5
ORDER BY SUM(ProductID) DESC;
```

## 1.3 Working with >1 tables => join, union, subquery, correlated subquery's

- join:
  - inner join (default)
  - outer join
  - cross join
- union
- subquery
  - simple nested query
  - correlated subquery
  - operator EXISTS
- set operator
- common table expressions

<img src="https://res.cloudinary.com/dri8yyakb/image/upload/v1638966480/joins_hddwzm.png"/>

### 1.3.1 Inner JOIN

> Joins rows from one table with rows from another table based on common criteria in the corresponding tables.

```SQL
SELECT expresion
FROM table1 JOIN table2 ON table1.columnRefA = table2.columnA

SELECT ProductId, CategoryName
FROM Products JOIN Categories 
ON Products.CategoryID = Categories.CategoryID

-- new style
SELECT ProductId, CategoryName
FROM Products p JOIN Categories c 
ON p.CategoryID = c.CategoryID

-- 2 tables joined
SELECT ProductId, CategoryName, SupplierName
FROM Products p 
JOIN Categories c ON p.CategoryID = c.CategoryID
JOIN Suppliers s ON p.SupplierID = s.SupplierID

-- self join (employees and who they report to)
SELECT e1.EmployeeID, e1.Firstname + ' ' + e1.LastName As Employee,
e2.Firstname + ' ' + e2.LastName As ReportsTo
FROM Employees e1 JOIN Employees e2
ON e1.ReportsTo = e2.EmployeeID

-- old style (WITHOUT WHERE IT BECOMES A CROSS JOIN)
SELECT ProductId, CategoryName
FROM Products p, Categories c 
WHERE p.CategoryID = c.CategoryID
```

### 1.3.2 Outer JOIN: left,right, full

```SQL
-- left join (shipments per shipper)
SELECT s.ShipperID, s.CompanyName, COUNT(OrderID) As NumberOfShippings
FROM Shippers s JOIN Orders o
ON s.shipperID = o.shipVia
GROUP BY s.ShipperID, s.CompanyName

SELECT s.ShipperID, s.CompanyName, COUNT(OrderID) As NumberOfShippings
FROM Shippers s LEFT JOIN Orders o
ON s.shipperID = o.shipVia
GROUP BY s.ShipperID, s.CompanyName

-- right join (employees to who no one reports)
SELECT e1.Firstname + ' ' + e1.LastName As Employee,
e2.Firstname + ' ' + e2.LastName As ReportsTo
FROM Employees e1 RIGHT JOIN Employees e2
ON e1.ReportsTo = e2.EmployeeID
WHERE e1.Firstname + ' ' + e1.LastName IS NULL

-- full join (order withour shipper and shipper without orders)
SELECT o.OrderID, s.ShipperID, s.CompanyName
FROM Shippers s FULL OUTER JOIN Orders o
ON s.shipperID = o.shipVia
```

### 1.3.3 Cross JOIN

- generates all possible combos
- row count table a X row count table B

```SQL
-- each employee has to contact reach customer
SELECT e.EmployeeID, e.FirstName + ' ' + e.LastName, e.Title,
c.CompanyName, c.ContactName, c.ContactTitle, c.Phone
FROM Employees e CROSS JOIN Customers c
```

### 1.3.4 Set operators: UNION, INTERSECT, EXCEPT

### 1.3.4.1 UNION

- combines result 2 or + queries
- both selects have equal amount columns and compatible datatypes
- no duplicates else `UNION ALL`
- Column names or expressions can't be used in the `ORDER BY` if they differ between the two SELECTs. In this case use column numbers for sorting.

```SQL
-- all employees and customers
SELECT LastName + ' ' + FirstName as Name, City, Postalcode
FROM Employees
UNION
SELECT CompanyName, City, Postalcode
FROM Customers
```

### 1.3.4.2 INTERSECT

> takes doorsnede

```SQL
-- tegelijk leverancier en klant
SELECT City, Country FROM Customers
INTERSECT
SELECT City, Country FROM Suppliers
```

### 1.3.4.3 EXCEPT

> takes all except doorsnede

```SQL
-- producten nooit besteld
SELECT ProductID
FROM Products
EXCEPT
SELECT ProductID
FROM OrderDetails
```

### 1.3.4 Exercices

```SQL
-- 1. Which suppliers (SupplierID and CompanyName) deliver Dairy Products?

SELECT DISTINCT CompanyName 
FROM Suppliers s
JOIN Products p ON s.SupplierID = p.ProductID
JOIN Categories c ON c.CategoryID = p.CategoryID
WHERE c.CategoryName = 'Dairy Products'; 

-- 2. Give for each supplier the number of orders that contain products of that supplier.
-- Show supplierID, companyname and the number of orders.
-- Order by companyname.

SELECT DISTINCT s.supplierID, s.CompanyName, COUNT(od.OrderID) as 'number of orders containing product of this supplier'
FROM OrderDetails od
JOIN Products p ON p.ProductID = od.ProductID
JOIN Suppliers s ON s.SupplierID = p.SupplierID
GROUP BY s.supplierID, s.CompanyName
ORDER BY s.CompanyName;

-- 3. What’s for each category the lowest UnitPrice? Show category name and unit price.

SELECT DISTINCT c.CategoryName, MIN(p.UnitPrice) as 'cheapest product in category'
FROM Categories c
JOIN Products p ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryID, c.CategoryName;

-- 4. Give for each ordered product: productname, the least (columnname 'Min amount ordered') and the most
-- ordered (columnname 'Max amount ordered'). Order by productname.

SELECT DISTINCT p.ProductName, MIN(od.Quantity) as 'Min amount ordered', MAX(od.Quantity) as 'Max amount ordered'
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductName
ORDER BY p.ProductName;

-- 5. Give a summary for each employee with orderID, employeeID and employeename.
-- Make sure that the list also contains employees who don’t have orders yet.

SELECT o.OrderID, e.EmployeeID, e.FirstName + ' ' + e.LastName as 'name'
FROM Employees e
LEFT JOIN Orders o ON o.EmployeeID = e.EmployeeID;
```

```SQL
-- Always give new columns an appropriate name 

-- How many countries can be found in the dataset?
SELECT COUNT(DISTINCT country) AS 'country count'
FROM     Countries;

-- Give the total population per continent
SELECT continent, SUM(1.0 * population) AS 'total population'
FROM     Countries
GROUP BY continent;

-- Which country with more than 1 000 000 inhabitants, has the highest life expectancy?
SELECT TOP 1 country, life_expectancy AS 'max life expectancy'
FROM     Countries
WHERE population > 1000000
ORDER BY life_expectancy DESC;

-- Calculate the average life_expectancy for each continent
-- Take into account the population for each country
SELECT continent, SUM(1.0 * life_expectancy * population) / SUM(1.0 * population) AS 'average life span'
FROM     Countries
GROUP BY continent;


-- Give the country with the highest number of Corona deaths
SELECT TOP 1 country, sum(new_deaths) AS 'corona deaths'
FROM     CovidData
GROUP BY country
ORDER BY 2 DESC;

-- On which day was 50% of the Belgians fully vaccinated?
SELECT TOP (1) c.country, cd.people_fully_vaccinated * 1.0 / c.population * 1.0 AS 'fully vaccinated rate', cd.report_date
FROM     CovidData AS cd INNER JOIN
                  Countries AS c ON c.country = cd.country
WHERE  (c.country = 'Belgium') AND (cd.people_fully_vaccinated * 1.0 / c.population * 1.0 > 0.5)
ORDER BY cd.people_fully_vaccinated

SELECT MIN(cd.report_date) AS Expr1
FROM     CovidData AS cd INNER JOIN
                  Countries AS c ON c.country = cd.country AND cd.people_fully_vaccinated >= c.population / 2
WHERE  (cd.country = 'Belgium')

-- On which day the first Belgian received a vaccin?
SELECT TOP (1) c.country, cd.people_fully_vaccinated * 1.0 / c.population * 1.0 AS 'fully vaccinated rate', cd.report_date
FROM     CovidData AS cd INNER JOIN
                  Countries AS c ON c.country = cd.country
WHERE  (c.country = 'Belgium') AND (cd.people_fully_vaccinated * 1.0 / c.population * 1.0 > 0)
ORDER BY cd.people_fully_vaccinated

-- On which day the first Corona death was reported in Europe?
SELECT TOP 10 cd.country, new_deaths, report_date AS 'corona deaths'
FROM     CovidData AS cd INNER JOIN
                  Countries AS c ON c.country = cd.country
WHERE c.continent = 'Europe' AND new_deaths is not null and new_deaths > 0
ORDER BY new_deaths asc, report_date asc;

SELECT MIN(report_date)
FROM CovidData  cd INNER JOIN Countries c ON c.country = cd.country
WHERE new_deaths IS NOT NULL AND continent = 'Europe'

-- What is the estimated total amount of smokers in Belgium?
-- Subtract 2 000 000 children from the total Belgian population
SELECT (male_smokers * 0.5 + female_smokers * 0.5) / 100.0 * (population - 2000000) as 'total smokers', population - 2000000
FROM     Countries
WHERE country = 'Belgium';

-- The first lockdown in Belgium started on 18 march 2020. Give all the data until 21 days afterwards
-- to be able to check if the lockdown had any effect.
SELECT *
FROM CovidData
WHERE country = 'Belgium' and report_date between '2020-03-18' and DATEADD (day, 21, '2020-03-18')

-- In which month (month + year) the number of deaths was the highest in Belgium?
SELECT YEAR(report_date) As 'Reported year', MONTH(report_date) As 'Reported month', SUM(new_deaths) As 'Total number of deaths'
FROM CovidData
WHERE country = 'Belgium'
GROUP BY YEAR(report_date), MONTH(report_date)
ORDER BY 3 DESC
```
