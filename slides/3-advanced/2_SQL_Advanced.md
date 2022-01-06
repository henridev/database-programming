# 2. SQL: Advanced concepts => Subqueries, Insert-Update-Delete-Merge, Views,Common Table Expressions

## 2.1 Subqueries

> using the result of one query instead of an expression

- always executes first
- always between ()
- can be nested at 1+ level
- can return *single value* or *list of values*

### 2.1.1 Subqueries with single value

```SQL
-- grootverdieners
SELECT lastname, firstname, salary 
FROM Employees 
WHERE Salary = 
	(SELECT MAX(Salary) from Employees);

-- duurder dan gemiddelde producten
SELECT * 
FROM Products 
WHERE UnitPrice > 
	(SELECT AVG(UnitPrice) from Products);

-- product more expensive than avg beverage price
SELECT ProductID, ProductName, UnitPrice
FROM     Products
WHERE  (UnitPrice >
                      (SELECT AVG(p.UnitPrice) AS Expr1
                       FROM      Products AS p INNER JOIN
                                         Categories AS c ON c.CategoryID = p.ProductID
                       WHERE   (c.CategoryName = 'Beverages')))

-- youngest employee in us 
SELECT LastName, FirstName 
FROM Employees
WHERE Country ='USA' AND BirthDate =
  (SELECT MAX(BirthDate) FROM Employees WHERE Country ='USA')
```

### 2.1.2 Subqueries with list values

- operatrors `ANY, ALL, IN, NOT IN`
- `ANY, ALL`
  - used with relational operators that return a column of values
  - `ALL` is true if all values in subquery satisfy the condition
  - `ANY` is true if at least one value in subquery satisfy the condition

```SQL
-- find customers that have ordered already
SELECT ContactName, CustomerID
FROM     Customers
WHERE  (CustomerID IN
                      (SELECT DISTINCT CustomerID
                       FROM      Orders));

SELECT ContactName, c.CustomerID
FROM     Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID;

-- find customers that haven't ordered yet
SELECT ContactName, CustomerID
FROM     Customers
WHERE  (CustomerID NOT IN
                      (SELECT DISTINCT CustomerID
                       FROM      Orders));

SELECT ContactName, c.CustomerID
FROM     Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.CustomerID IS NULL;

-- find products more expensive than most expensive seafood
SELECT ProductID, ProductName, UnitPrice, UnitsInStock
FROM     Products
WHERE  (UnitPrice > 
                      (SELECT MAX(p.UnitPrice)
                       FROM      Products AS p INNER JOIN
                                         Categories AS c ON p.CategoryID = c.CategoryID
                       WHERE   (c.CategoryName LIKE '%sea%')))

-- find products more expensive than most expensive seafood with ALL         
SELECT ProductID, ProductName, UnitPrice, UnitsInStock
FROM     Products
WHERE  (UnitPrice > ALL
                      (SELECT p.UnitPrice
                       FROM      Products AS p INNER JOIN
                                         Categories AS c ON p.CategoryID = c.CategoryID
                       WHERE   (c.CategoryName LIKE '%sea%')))

-- find all products more expensive than one of seafood
SELECT ProductID, ProductName, UnitPrice, UnitsInStock
FROM     Products
WHERE  (UnitPrice > 
                      (SELECT MIN(p.UnitPrice)
                       FROM      Products AS p INNER JOIN
                                         Categories AS c ON p.CategoryID = c.CategoryID
                       WHERE   (c.CategoryName LIKE '%sea%')))

-- find all products more expensive than one of seafood with ANY         
SELECT ProductID, ProductName, UnitPrice, UnitsInStock
FROM     Products
WHERE  (UnitPrice > ANY
                      (SELECT p.UnitPrice
                       FROM      Products AS p INNER JOIN
                                         Categories AS c ON p.CategoryID = c.CategoryID
                       WHERE   (c.CategoryName LIKE '%sea%')))
```

### 2.1.3 Correlated subquery

- inner query depends on outer query info
- inner query search condition refers to main query
- subquery executes for each row in main query `O(n^2)`
- order execution is top to bottom not bottom to top in simple subquery `O(n)`

1. row 1 outer query passes values for row to inner query
2. inner query uses values to evaluate itself
3. inner query returns value to outer query
4. repeat for each row in outer query

```SQL
-- here subquery p2 needs p1
-- products more expensive than the avg product within their respective category
SELECT CategoryID, ProductID, ProductName, UnitPrice
FROM     Products p1
WHERE  (UnitPrice >
                      (SELECT AVG(UnitPrice) as 'avg price'
                       FROM      Products p2
					   WHERE p1.CategoryID = p2.CategoryID))

-- Give employees with a salary larger than the average salary
SELECT FirstName + ' ' + LastName as 'name', Salary
FROM     Employees e1
WHERE  (salary >
                      (SELECT AVG(Salary) as 'avg salary'
                       FROM      Employees))

-- Give the employees whose salary is larger than the average of the salary of the employees who report to the same boss.
SELECT FirstName + ' ' + LastName as 'name', Salary
FROM     Employees e1
WHERE  (salary >
                      (SELECT AVG(Salary) as 'avg salary'
                       FROM      Employees e2
					   WHERE e1.ReportsTo = e2.ReportsTo))
```

### 2.1.4 subquery and EXISTS

- `exists`: test existence of a result set
- `not exists`: test non existence of a result set

```SQL
-- find customers that have ordered already
SELECT ContactName, CustomerID
FROM     Customers AS c
WHERE EXISTS (SELECT * FROM Orders as o WHERE o.CustomerID = c.CustomerID);

-- find customers that haven't ordered yet
SELECT ContactName, CustomerID
FROM     Customers AS c
WHERE NOT EXISTS (SELECT * FROM Orders as o WHERE o.CustomerID = c.CustomerID);
```

> one question 3 answers: find customers that haven't ordered yet

```SQL
-- outer join
SELECT ContactName, CustomerID
FROM     Customers AS c
LEFT JOIN Orders AS o WHERE o.CustomerID = c.CustomerID
WHERE o.CustomerID is NULL;

-- simple subquery
SELECT ContactName, CustomerID
FROM     Customers AS c
WHERE CustomerID NOT IN (SELECT DISTINCT CustomerID FROM Orders);

-- correlated subquery
SELECT ContactName, CustomerID
FROM     Customers AS c
WHERE EXISTS (SELECT * FROM Orders as o WHERE o.CustomerID = c.CustomerID);
```

### 2.1.5 subquery and FROM-clause (instead of WHERE)

- result of query is table
- the table in the subquery must get a name
- renaming columns in derived table is optional

```SQL
-- Give per region the total sales (region USA+Canada = North America, rest = Rest of World).
SELECT CASE c.country
         WHEN 'USA' THEN 'North America'
         WHEN 'Canada' THEN 'North America'
         ELSE 'Rst'
       END              AS RegionClass,
       Count(o.orderid) AS 'order count'
FROM   customers c
       JOIN orders o
         ON c.customerid = o.customerid
GROUP  BY CASE c.country
            WHEN 'USA' THEN 'North America'
            WHEN 'Canada' THEN 'North America'
            ELSE 'Rst'
          END; 


-- with derived table
-- region class eerst creeren dan kan je erop groeperen
SELECT RegionClass,
       Count(orderId) AS 'order count'
FROM (  
      SELECT CASE c.country
         WHEN 'USA' THEN 'North America'
         WHEN 'Canada' THEN 'North America'
         ELSE 'Rst'
       END AS RegionClass, o.orderId AS orderId
       FROM Customers AS c JOIN orders AS o
       ON c.customerid = o.customerid
) AS TOTALS(RegionClass, OrderId) -- table columns now called RegionClass, OrderId
GROUP BY RegionClass
```

### 2.1.6 subquery and SELECT-clause (and FROM Clause)

- we can use scalar simple or correlated subqueries

```SQL
-- Give for each employee how much they earn more (or less) than 
-- the average salary of all employees with the same supervisor.


SELECT 
	FirstName + ' ' + LastName AS 'name', 
	Salary - (
		SELECT AVG(Salary) FROM Employees AS e2
		WHERE e2.ReportsTo = e1.ReportsTo
	)
FROM Employees AS e1

-- Give per category the price of the cheapest product and a product that has that price.

SELECT Category, LowestPrice, 
	(
	SELECT TOP 1 ProductName FROM Products AS p2 
	WHERE p2.CategoryID = Category AND p2.UnitPrice = LowestPrice
	) AS ProductName
FROM (
	SELECT CategoryID, MIN(unitPrice)
	FROM Products AS p1
	GROUP BY CategoryID
) AS MinPricePerCategory(Category, LowestPrice)

```

### 2.1.7 subquery and running total

```SQL
SELECT 
  OrderID, 
  OrderDate, 
  Freight,
  (
    SELECT SUM(Freight)
    FROM Orders
    WHERE YEAR(OrderDate) = YEAR(o.OrderDate) and OrderID <= o.OrderID
  ) As TotalFreight
FROM Orders o
ORDER BY Orderid;

SELECT 
  OrderID, 
  OrderDate, 
  Freight,
  (
    SELECT SUM(Freight)
    FROM Orders
    WHERE YEAR(OrderDate) = YEAR(o.OrderDate) and OrderDate <= o.OrderDate -- here is the clue
  ) As TotalFreight
FROM Orders o
ORDER BY Orderid;

-- OrderID	OrderDate	Freight	TotalFreight
-- 10248	2016-07-04 00:00:00.000	32.38	32.38
-- 10249	2016-07-05 00:00:00.000	11.61	43.99 (32.38 + 11.61)
-- 10250	2016-07-08 00:00:00.000	65.83	109.82
```

### 2.1.8 exercices

```SQL
-- 1. Give the id and name of the products that have not been purchased yet.
select productid, productname
from products
where productid not in (select productid from Orders);

-- 2. Select the names of the suppliers who supply products that have not been ordered yet.
select s.CompanyName 
from suppliers s join products p on s.supplierID = p.supplierID
where productID not in (select productID from OrderDetails);

-- 3. Give a list of all customers from the same country as the customer Maison Dewey
SELECT c.CompanyName, c.country
FROM     Customers as c
WHERE  (Country =
                      (SELECT Country
                       FROM      Suppliers
                       WHERE   (CompanyName = 'Maison Dewey')))



-- 4. Calculate how much is earned by the management (like 'president' or 'manager'), 
-- the submanagement
-- (like 'coordinator') and the rest
SELECT PositionType, SUM(Salary) as 'total earned'
FROM (
	SELECT 
		CASE
			WHEN Title LIKE '%president%' THEN 'management'
			WHEN Title LIKE '%manager%' THEN 'management'
			WHEN Title LIKE '%coordinator%' THEN 'submanagement'
			ELSE 'rest'
		END AS PositionType,
		Salary
	FROM Employees
) AS TOTALS(PositionType, Salary)
GROUP BY PositionType
ORDER BY SUM(Salary) DESC

-- 5. Give for each product how much the price differs from the average price of all products of the same
-- category

SELECT 
	p1.ProductName,
	UnitPrice - (SELECT AVG(UnitPrice) AS Expr1
                 FROM      Products AS p2
                 WHERE   (p1.CategoryID = CategoryID)) AS 'diff from average price'
FROM     Products AS p1
ORDER BY 'diff from average price' DESC

-- 6. Give per title the employee that was last hired
SELECT title, firstname + ' ' + lastname, HireDate
FROM employees e
WHERE HireDate = (SELECT MAX(HireDate) FROM employees WHERE title = e.title)

SELECT Title, DateOfLastHire, 
	(
	SELECT TOP 1 FirstName + ' ' + LastName as 'Name' FROM Employees AS e2 
	WHERE e2.HireDate = DateOfLastHire AND e2.Title = Title
	) AS employee
FROM (
	SELECT Title, MAX(HireDate)
	FROM Employees AS e1
	GROUP BY Title
) AS LastHirePerTitle(Title, DateOfLastHire)


-- 7. Which employee has processed most orders?
 
SELECT EmployeeID, LastName, FirstName
FROM     Employees
WHERE  (EmployeeID =
                      (SELECT employee
                       FROM      (SELECT TOP (1) EmployeeID, COUNT(OrderID) AS 'total orders processed'
                                          FROM      Orders
                                          GROUP BY EmployeeID
                                          ORDER BY 'total orders processed' DESC) AS MaxOrders(employee, orderCount)))

SELECT e.FirstName + ' ' + e.LastName AS Expr1, COUNT(*) AS Expr2
FROM     Employees AS e INNER JOIN
                  Orders AS o ON e.EmployeeID = o.EmployeeID
GROUP BY e.EmployeeID, e.LastName, e.FirstName
HAVING (COUNT(*) =
                      (SELECT TOP (1) COUNT(*) AS Expr1
                       FROM      Employees AS e INNER JOIN
                                         Orders AS o ON e.EmployeeID = o.EmployeeID
                       GROUP BY e.FirstName + ' ' + e.LastName
                       ORDER BY Expr1 DESC))

-- 8. What's the most common ContactTitle in Customers?

SELECT DISTINCT ContactTitle
FROM Customers
WHERE contactTitle = (
	SELECT TOP 1 ContactTitle FROM Customers GROUP BY ContactTitle ORDER BY Count(*) DESC
)

-- 9. Is there a supplier that has the same name as a customer?
SELECT CompanyName FROM Suppliers WHERE CompanyName IN (SELECT CompanyName FROM Customers)
```

## 2.2 DML => insert, update, delete, merge

> we see nothing new but we will see you can do it with a subquery aswell

preventing accidental destruction

```SQL
BEGIN TRANSACTION

INSERT INTO Products(ProductName)
VALUES ('TestProduct');

SELECT * FROM Products WHERE ProductID = (
  SELECT MAX(ProductID) FROM Products
)

ROLLBACK; -- end transaction restore db to previous state
-- COMMIT; --  end transaction make change permanent
```

## 2.2.1 insert

- add single row via spec
  - specify not null columns
    - Unmentioned columns get the value NULL or the DEFAULT value if any.
  - specify all columns (exclude auto generated id)
    - the values are assigned in the column order as specified by the CREATE TABLE statement.
- add selected row from other tables
  - Mandatory fields have to be specified, unless they have a DEFAULT value.
  - Constraints (see further) are validated.
  - Unmentioned columns get the value NULL or the DEFAULT value if any.

```SQL
INSERT INTO Products (ProductName, CategoryID, Discontinued)
VALUES ('Toblerone' ,3 ,0)

INSERT INTO Products
VALUES ('Sultana', null, 3 ,null, null ,null, null, null, 1)


INSERT INTO Customers(CustomerID, ContactName, ContactTitle,CompanyName)
SELECT 
  substring(FirstName,1,2) + substring(LastName,1,3), 
  FirstName + ' ' + LastName,
  Title,
  'EmployeeCompany'
FROM Employees
```

## 2.2.2 update

- update all rows of table
- update specific row in table (with where)
- update specific row in table based other table data (with where + subquery)

```SQL
-- ten percent price increase
UPDATE Products
SET UnitPrice = UnitPrice * 1.1

-- ten percent price increase for product x
UPDATE Products
SET UnitPrice = UnitPrice * 1.1
WHERE ProductName = '%Bread%'

-- ten percent price increase for usa origin products
UPDATE Products
SET UnitPrice = UnitPrice * 1.1
WHERE SupplierID IN (
  SELECT SupplierID FROM Suppliers WHERE Country = 'USA'
)
```

## 2.2.3 delete

- delete all rows of table
- delete specific row in table (with where)
- delete specific row in table based other table data (with where + subquery)

```SQL
DELETE FROM Products
WHERE ProductName = '%Bread%'

TRUNCATE TABLE Products

-- Delete the orderdetails for all orders from the most recent orderdate
DELETE FROM Products
WHERE OrderId IN (
  SELECT OrderId FROM Orders WHERE OrderDate = (SELECT MAX(OrderDate) FROM Orders)
)
```

## 2.2.4 merge

- combo of INSERT, UPDATE, DELETE
- uc: users work in excel to update a relatively large amount of records because Excel offers a better overview than their ERP tool (they can update add or delete records in excel) After uploading the edited Excel file to a temporary table, the merge statement performs all UPDATEs, INSERTs and DELETEs at once.

```SQL
/* First execute following script to simulate the Excel file that has been imported
to a temporary table ShippersUpdate */
DROP TABLE IF EXISTS ShippersUpdate;

-- Add everything from Shippers to ShippersUpdate
SELECT * INTO ShippersUpdate FROM Shippers

-- Add an extra record to ShippersUpdate
INSERT INTO ShippersUpdate VALUES ('Pickup','(503) 555-9647')

-- Update a record of ShippersUpdate
UPDATE ShippersUpdate SET Phone = '(503) 555-4512' WHERE ShipperID = 1

-- Remove a record from ShippersUpdate
DELETE FROM ShippersUpdate WHERE shipperID = 4

-- update something in target
BEGIN TRANSACTION
INSERT INTO Shippers
VALUES ('PostNL', '(503) 555-1236')
SELECT * FROM Shippers;
SELECT * FROM ShippersUpdate;


MERGE Shippers as t -- t = target
USING ShippersUpdate as s -- s = source
ON (t.ShipperID = s.ShipperID)

-- Which rows are in source and have different values for CompanyName or Phone?
-- Update those rows in target with the values coming from source
WHEN MATCHED AND t.CompanyName <> s.CompanyName OR ISNULL(t.Phone,'') <> ISNULL(s.Phone,'')
THEN UPDATE SET t.CompanyName = s.CompanyName, t.Phone=s.Phone

-- Which rows are in target and not in source?
-- Add those rows to source
WHEN NOT MATCHED BY target --> new rows
THEN INSERT (CompanyName, Phone) VALUES (s.CompanyName,s.Phone)

-- Which rows are in source and not in target?
-- Delete those rows from target
WHEN NOT MATCHED BY source --> rows to delete
THEN DELETE;

-- Check the result
SELECT * FROM Shippers
ROLLBACK;
```

## 2.2.5 exercices

```SQL
-- 1. On which day(s) the highest number of new cases was reported in Belgium?
SELECT report_date FROM CovidData
WHERE new_cases = (SELECT MAX(new_cases) FROM CovidData)

-- 2. On which day(s) the highest number of new deaths was reported for each country?
SELECT countryName, maxCases,
                      (SELECT TOP (1) report_date
                       FROM      CovidData AS cd2
                       WHERE   (MaxCasesPerCountry.countryName = country) AND (MaxCasesPerCountry.maxCases = new_cases)) AS 'report date'
FROM     (SELECT country, MAX(new_cases) AS Expr1
                  FROM      CovidData
                  GROUP BY country) AS MaxCasesPerCountry(countryName, maxCases)
Order By 'report date' DESC


-- 3. Which country(ies) was(were) the first to start vaccinations?

SELECT country, MIN(report_date) AS Expr1
FROM     CovidData
WHERE  (total_vaccinations > 0)
GROUP BY country
ORDER BY MIN(report_date)

SELECT country, report_date
FROM CovidData
WHERE total_vaccinations IS NOT NULL AND report_date = (SELECT MIN(report_date) FROM CovidData WHERE total_vaccinations IS NOT NULL)


-- 4. Give for each country the percentage of fully vaccinated people
-- based on the most recent data on the fully vaccinated people for that country
-- Order the results in a descending way
-- You could try to solve this taking into account that - for now 
-- the number of fully vaccinated people is an always increasing number.
-- But once the vaccination campaign is done and old people are dying 
-- and new babies are born, it's possible this won't be the case any more.


SELECT lastReporting, countryName,
                      (SELECT TOP (1) (people_fully_vaccinated * 1.0 / c.population * 1.0)
                       FROM      CovidData AS cd2
					   JOIN		 Countries as c on cd2.country = c.country
                       WHERE   (LastReportDatesPerCountry.lastReporting = report_date) AND (LastReportDatesPerCountry.countryName = cd2.country)) AS percentageFullVaccination
FROM     (SELECT MAX(report_date) AS 'last report date', country
                  FROM      CovidData
                  GROUP BY country) AS LastReportDatesPerCountry(lastReporting, countryName)
ORDER BY percentageFullVaccination DESC

SELECT cd.country, cd.people_fully_vaccinated * 1.0 / c.population
FROM CovidData  cd INNER JOIN Countries c ON c.country = cd.country
WHERE people_fully_vaccinated IS NOT NULL AND report_date = (SELECT MAX(report_date) FROM CovidData WHERE country = cd.country AND people_fully_vaccinated IS NOT NULL)
ORDER BY 2 DESC

SELECT cd.country, MAX(cd.people_fully_vaccinated * 1.0 / c.population)
FROM CovidData  cd INNER JOIN Countries c ON c.country = cd.country
GROUP BY  cd.country
ORDER BY 2 DESC

-- 5. Assume that all people in Belgium got fully vaccinated from elder to younger. 
-- We don't take into account people on priority lists like doctors, nurses, ...
-- On which day all Belgians of 70 or older were fully vaccinated?

SELECT MIN(report_date)
FROM CovidData
WHERE country = 'Belgium' AND people_fully_vaccinated >= (SELECT aged_70_older * population / 100 FROM Countries WHERE country = 'Belgium')

-- 6. Give an overview of the cumulative sum of Corona deaths for each country
-- Give country, report_date, new_deaths and the cumulative sum
-- Order by country and report_date

SELECT 
  cd1.country, 
  cd1.report_date,  
  cd1.new_deaths, 
  (
    SELECT SUM(cd2.new_deaths)
    FROM CovidData as cd2
    WHERE cd1.country = cd2.country and cd1.report_date >= cd2.report_date
  ) As 'total deaths'
FROM CovidData cd1
ORDER BY cd1.country, cd1.report_date;

-- 7. Give for each continent the countries in which the life_expectancy
-- is higher than the average life_expectancy of that continent

SELECT c1.country, c1.life_expectancy FROM Countries AS c1 WHERE life_expectancy > 
	(SELECT AVG(life_expectancy) FROM Countries AS c2  WHERE c1.continent = c2.continent)

-- 8. Which country(ies) have the highest value for median_age
SELECT country, median_age
FROM countries
WHERE median_age = (SELECT MAX(median_age) FROM countries)
```

## 2.3 Views

### 2.3.1 Introduction

- a saved `SELECT` statement
- virtual table composed of other tables &/OR views
- no data storage for each referal underlying `SELECT` is executed

PROS:

- hide DB complexity
  - hide complex DB design
  - make large and complex queries accesible and reusable
  - can be partial solution for bigger problems eg. `SELECT AVG(COUNT()) FROM table => SELECT AVG(aantal) FROM ViewWithAantal`
- secures data access
- organise data for export to other apps

```SQL
CREATE VIEW view_name [(column_list)] AS select_statement
[with check option]
```

- \#(column_list) = \#column in select
  - no columns specified => taken from select
  - mandatory if select contains calculations or joins in which some column names are duplicate
- select can't contain an `ORDER BY` => kan gebeuren als je select op view uitvoert
- [with check option]: in case of mutation through view (CUD) check if new data conforms to the view conditions eg. (view met alle producten van categorie 1 wijzig je 1 ervan naar categorie 2 dan verdwijnt deze uit view => with check option checkt dit)

### 2.3.2 CRUD

```SQL
-- create view
CREATE VIEW v_sales_people AS
	SELECT EmployeeID, LastName, FirstName, Title, TitleOfCourtesy, BirthDate, HireDate, Address, City, Region, PostalCode, Country, HomePhone, Extension, Photo, Notes, ReportsTo, PhotoPath, Salary
	FROM     Employees
	WHERE  (ReportsTo IS NOT NULL) AND (Title LIKE '%sales%');

-- verander column names via script view as => alter to => clipboard
ALTER VIEW [dbo].[v_sales_people](eid, achternaam, voornaam, titel, salaris)AS
	SELECT   EmployeeID, LastName, FirstName, Title, Salary
	FROM     Employees
	WHERE  (ReportsTo IS NOT NULL) AND (Title LIKE '%sales%')
GO

-- gebruik view
SELECT eid from v_sales_people

-- verwijder view
DROP VIEW v_sales_people
```

### 2.3.3 Partial solution for complex problems

```SQL
DROP VIEW IF EXISTS v_orders_per_employee_per_year;
GO -- new batch

-- create view  with the number of orders per employee per year
CREATE VIEW v_orders_per_employee_per_year 
AS
	SELECT  EmployeeID, YEAR(OrderDate) as orderYear, COUNT(OrderID) as orderCount
	FROM    Orders
	group by  EmployeeID, YEAR(OrderDate);
	
SELECT orderYear FROM v_orders_per_employee_per_year ORDER BY EmployeeID, orderYear;
GO -- new batch

-- Calculate per employee and per year the running total of processed orders.
SELECT 
	EmployeeID, orderYear, orderCount,
	(
		SELECT SUM(orderCount) 
		FROM v_orders_per_employee_per_year
		WHERE v1.EmployeeID = EmployeeID AND v1.orderYear >= orderYear
	) as totalNumberOfOrders
FROM v_orders_per_employee_per_year as v1
ORDER BY EmployeeID, orderYear
```

> Drawback of using views in this way: views are stored in the database and might create a mess if you have hundreds of them. We'll try to solve this using cte's (is not saved like views)

### 2.3.4 working with updatable view

we have en **updatable view** if select statement does NOT have:

- `DISTINCT` or `TOP` clause
- Statistical functions
- calculated values
- `GROUP BY` statement
- a union
- join

else we have a **read-only view**

> it's common sense to see when a view is able to translate updates to underlying records or not

- `UPDATE`
  - max one table at once
  - check option inactive => row can dissapear
  - check option active => error if row would dissapear
- `INSERT`
  - max one table at once
  - mandatory columns need to appear in view and insert
    - identity columns with null or default constraint can be omitted
- `DELETE`
  - max one table at once

#### 2.3.4.1 check option explained

- sometimes view reveals partial data of table
- a simple view is updatable which means data no visible through view could be updated
- such data could make view inconsistent => `WITH CHECK OPTION` clause makes sure view stays consistent when it is created or modified
  - In other words, whenever you update or insert a row of the base tables through a view,
  - SQLServer ensures that the insert or update operation is conformed with the definition of the view.

```SQL
DROP VIEW IF EXISTS productsOfCategory1;
GO
DROP VIEW IF EXISTS productsOfCategory1Bis;
GO
-- Create a view without "with check option"
CREATE VIEW productsOfCategory1
	AS SELECT * FROM Products WHERE CategoryID = 1
GO

-- Insert product from CategoryID 2 => although Wokkels is from CategoryID = 2, it can be added through the
-- view
INSERT INTO productsOfCategory1 (ProductName, CategoryID)
VALUES ('Lays Wokkels', 2)
SELECT * FROM Products WHERE ProductName LIKE '%Wokkels%'
DELETE FROM Products
WHERE ProductName LIKE '%Wokkels%'
GO

-- Create a view with "with check option"
CREATE VIEW productsOfCategory1Bis
  AS SELECT * FROM Products WHERE CategoryID = 1
  WITH CHECK OPTION
GO

-- Insert product from producttype 2 => because Wokkels is from CategoryID = 2, 
-- it can't be inserted through the view
INSERT INTO productsOfCategory1Bis (ProductName, CategoryID)
VALUES ('Lays Wokkels', 2)
```

### 2.3.5 views in SQL management studio

- can be made through gui if simple enough (not possible if views contains subqueries or common table expressions) [link](https://www.sqlshack.com/how-to-create-a-view-in-sql-server)
- can be adjusted easily via right clicking on the name of the view and:
  - Script View as...
  - ALTER to...
  - New Query Editor Window
  
### 2.3.6 exercices

```SQL
-- Exercise 1
-- The company wants to weekly check the stock of their products.
-- If the stock is below 15, they'd like to order more to fulfill the need.
-- (1.1) Create a QUERY that shows the ProductId, ProductName and the name of the supplier, 
-- do not forget the WHERE clause.
-- (1.2) Turn this SELECT statement into a VIEW called: vw_products_to_order.
-- (1.3) Query the VIEW to see the results.

CREATE VIEW vw_products_to_order
  AS SELECT ProductID, ProductName, s.CompanyName 
		FROM Products p JOIN Suppliers s 
		ON p.SupplierID = s.SupplierID 
		WHERE p.UnitsInStock < 15 
  WITH CHECK OPTION
GO;

SELECT * FROM vw_products_to_order;
GO;
-- Exercise 2
-- The company has to increase prices of certain products.
-- To make it seem the prices are not increasing
-- dramatically they're planning to spread the price increase over multiple years. 
-- In total they'd like a 10% price for certain products. 
-- The list of impacted products can grow over the coming years.
-- We'd like to keep all the logic of selecting the correct products in 1 SQL View, 
-- in programming terms 'keeping it DRY'.
-- The updating of the items is not part of the view itself.
-- The products in scope are all the products with the term 'Bröd' or 'Biscuit'.
-- (2.1) Create a simple SQL Query to get the correct resultset
-- (2.2) Turn this SELECT statement into a VIEW called: vw_price_increasing_products.
-- (2.3) Query the VIEW to see the results.
-- (2.4) Increase the price of the resultset of the VIEW: vw_price_increasing_products by 2%.
-- Use a transaction

BEGIN TRANSACTION
GO;

CREATE VIEW vw_price_increasing_products
  AS SELECT *
		FROM Products p
		WHERE p.ProductName LIKE '%Bröd%' OR p.ProductName LIKE '%Biscuit%'
  WITH CHECK OPTION
GO;

UPDATE vw_price_increasing_products
 SET UnitPrice = UnitPrice * 1.02

ROLLBACK;
```

## 2.4 Common table expressions !!Examen

net als subqueries en views gebruikt om deel problemen op te lossen

### 2.4.1 CTE WITH Component

using with component subqueries can get their own name and be (re)used in the rest of the query (possibly multiple times!)

2 main applications:

- Simplify SQL-instructions, e.g. simplified alternative for simple subqueries or avoid repetition of SQL constructs (2.4.3)
- Traverse recursively hierarchical (2.4.4, 2.4.5) and network structures

```SQL
-- Give the average number of orders for all customers

SELECT AVG(ordersPlaced) * 1.0 as 'avg order per customer' FROM (
	SELECT CustomerID, COUNT(OrderID)  * 1.0 as 'orders placed' FROM Orders GROUP BY CustomerID
) AS OrdersPerCustomer(cid, ordersPlaced)

WITH OrdersPerCustomer(cid, ordersPlaced) AS (
	SELECT CustomerID, COUNT(OrderID)  * 1.0 as 'orders placed' FROM Orders GROUP BY CustomerID
)

SELECT AVG(ordersPlaced) * 1.0 as 'avg order per customer' FROM OrdersPerCustomer 
```

### 2.4.2 CTE VS View & CTE VS Subqueries

VS View:

- BOTH are virtual tables which derive their content from underlying select statements
- CTE only exist during Select while Views get saved and remain visible for other users and applications

VS Subqueries:

- BOTH are virtual tables which derive their content from underlying select statements
- CTE is reusable
- Subquery has to be defined where it is used
- CTE defined on top of query
- simple subqueries can always be replaced by CTE

### 2.4.3 CTE to simplify queries

```SQL
-- Give per category the minimum price and all products with that minimum price

WITH MinPricePerCategory(cid, minPrice) AS (
	SELECT CategoryID, MIN(UnitPrice) FROM Products GROUP BY CategoryID
)

SELECT p.ProductName, mpc.minPrice, mpc.cid
FROM Products p
JOIN MinPricePerCategory mpc ON mpc.cid = p.CategoryID AND mpc.minPrice = p.UnitPrice
```

### 2.4.3.1 CTE having more than one WITH

```SQL
-- Step 1: Calculate the total revenue per year
WITH revenuePerYear(yearOfOrder, revenue) 
AS 
(
	SELECT YEAR(o.OrderDate), SUM(od.UnitPrice * od.Quantity)
	FROM     OrderDetails AS od INNER JOIN
					  Orders AS o ON od.OrderID = o.OrderID
	GROUP BY YEAR(o.OrderDate)
), -- just a comma not a second with

-- Step 2: Calculate the total revenue per customer per year
revenuePerCustomerPerYear(customerId, yearOfOrder, revenue) AS (
	SELECT o.CustomerID, YEAR(o.OrderDate) AS yearOfOrder, SUM(od.UnitPrice * od.Quantity) AS revenue
	FROM     OrderDetails AS od INNER JOIN
					  Orders AS o ON od.OrderID = o.OrderID
	GROUP BY o.CustomerID, YEAR(o.OrderDate)
)


SELECT 
	rpcpy.customerId, 
	rpcpy.yearOfOrder, 
	FORMAT(rpcpy.revenue * 1.0 / rpy.revenue * 1.0, 'P') as 'share of year revenue'
FROM     revenuePerYear AS rpy INNER JOIN
                  revenuePerCustomerPerYear AS rpcpy ON rpy.yearOfOrder = rpcpy.yearOfOrder
ORDER BY 2 ASC, 3 DESC
```

### 2.4.4 Recursive select

> **recursive** = continue to execute table expression until condition is reached

example problems:

- Who are the friends of my friends etc. (in a social network)?
- What is the hierarchy of an organisation ?
- Find the parts and subparts of a product (Bill of materials).

Summary how it works: the 1st (non-recursive) expression is executed onceand the 2nd expression is executed until it does not return any more results.

```SQL
-- integers from 1 to 5
WITH numbers(number) AS (
  -- BASIS STAP
	SELECT 1 -- 1: SQL searches the table expressions that don't contain recursivity and executes them one by one. 
		UNION all
      -- INDUCTIE STAP 
      -- 2: Execute all recursive expressoins. The numbers table, that got a value of 1 in step 1, is used.This row is added to the numbers table.
      -- 3: Now the recursion starts: the 2nd expression is re-executed, giving as result: 3
      -- Remark: not all rows added in the previous steps are processed, **but only those rows (1 row in this example)**, that were added in the previous step (step 2).
      -- 4: Since step 3 also gave a result, the recursive expression is executed again, producing as intermediate result: 4
      -- 5: And this happens again: 5
      -- 6: If the expression is now processed again, it does not return a result, since in the previous step no rows were added that correspond to the condition number < 5.Here SQL stops the processing of the table expressionand the final result is known.
			SELECT number + 1
			FROM numbers
      -- STOP CONDITIE
			WHERE number < 5
)

SELECT * FROM numbers
```

properties of recursive WITH:

- The with component consists of (at least) 2 expressions, combined with `union all`
- A temporary table is consulted in the second expression
- At least one of the expressions may not refer to the temporary table

> standard the max recursion depth is 100 can be changed with maxrecursion option

```SQL
WITH numbers(number) AS (
	SELECT 1
		UNION all
			SELECT number + 1
			FROM numbers
			WHERE number < 999
)

SELECT * FROM numbers
OPTION (maxrecursion 1000);

```

example: Give the total revenue per month in 2016 Not all months occur

```SQL
SELECT 
	YEAR(o.OrderDate) * 100 + MONTH(o.OrderDate) AS RevenueMonth, 
	SUM(od.UnitPrice * od.Quantity) AS Revenue
FROM 
	Orders AS o 
	INNER JOIN OrderDetails AS od 
	ON o.OrderID = od.OrderID
WHERE  (YEAR(o.OrderDate) = 2016)
GROUP BY YEAR(o.OrderDate) * 100 + MONTH(o.OrderDate);

-- generate all months via cte
WITH Months AS (
	SELECT 201601 AS RevenueMonth
            UNION ALL
            SELECT RevenueMonth + 1
            FROM     Months
            WHERE  (RevenueMonth < 201612)
)

SELECT RevenueMonth FROM Months
```

```SQL
-- generate all months via cte
WITH Months(RevenueMonth) AS (
	SELECT 201601 AS RevenueMonth
            UNION ALL
            SELECT RevenueMonth + 1
            FROM     Months
            WHERE  (RevenueMonth < 201612)
),

Revenues(RevenueMonth, revenue) AS (
	SELECT 
		YEAR(o.OrderDate) * 100 + MONTH(o.OrderDate) AS RevenueMonth, 
		SUM(od.UnitPrice * od.Quantity) AS Revenue
	FROM 
		Orders AS o 
		INNER JOIN OrderDetails AS od 
		ON o.OrderID = od.OrderID
	WHERE  (YEAR(o.OrderDate) = 2016)
	GROUP BY YEAR(o.OrderDate) * 100 + MONTH(o.OrderDate)
)

SELECT m.RevenueMonth, ISNULL(r.Revenue, 0) As Revenue
FROM Months m 
LEFT JOIN Revenues r 
ON m.RevenueMonth = r.RevenueMonth
```

### 2.4.5 Traverse recursively hierarchical structure

```SQL
WITH Bosses(boss, emp) AS (
	-- BASIS employee die aan niemand rapporteert
	SELECT ReportsTo, EmployeeID
    FROM      Employees
    WHERE   (ReportsTo IS NULL)
    UNION ALL
		-- INDUCTIE stap
		SELECT e.ReportsTo, e.EmployeeID -- selecteer zelfde col
		FROM     Employees AS e INNER JOIN -- in join recursief verwijzen naar vorige emp als baas
                 Bosses AS b ON e.ReportsTo = b.emp 
)

SELECT boss, emp
FROM     Bosses
ORDER BY boss, emp -- zonder orde rby toont het ons volgorde dat het van stack gehaald zal worden
```

draw organigram

```SQL
WITH Bosses (boss, emp, title, level, path)
AS
(
  SELECT ReportsTo, EmployeeID, Title, 1, convert(varchar(max), Title)
  FROM Employees
  WHERE ReportsTo IS NULL
  UNION ALL
    SELECT 
      e.ReportsTo, e.EmployeeID, e.Title, 
      b.level + 1, convert(varchar(max), b.path + '<--' + e.title)
    FROM Employees e 
    INNER JOIN Bosses b ON e.ReportsTo = b.emp
)

SELECT * FROM Bosses
ORDER BY boss, emp;
```

### 2.4.6 Exercices

```SQL
-- 1: Give per region the number of orders 
-- (region USA + Canada = North America, rest = Rest of World). Use cte's.

WITH orderRegions(orderId, Region) AS (
	SELECT
		o.orderId,
		CASE c.Country
			WHEN 'USA' THEN 'North America'
			WHEN 'Canada' THEN 'North America'
			ELSE 'Rest of World'
		END	AS Region
	FROM Orders AS o
	JOIN Customers AS c
	ON o.CustomerID = c.CustomerID
)

SELECT oreg.Region as region, COUNT(o.OrderID) AS orderCount
FROM     Orders AS o INNER JOIN
                  orderRegions AS oreg ON o.OrderID = oreg.orderId
GROUP BY oreg.Region

-- 2 Make a histogram of the number of orders per customer, 
-- so show how many times each number occurs. 
--E.g.in the graph below: 
-- 1 customer placed 1 order, 2 customers placed 2 orders, 7 customers placed 3 orders, etc.

/*
nrNumberOfCustomers
11
22
37
46
510
68
77
...
*/

WITH ordersPerCustomer(CustomerID, orderCount) AS (
	SELECT
		CustomerID,
		Count(OrderID)
	FROM Orders
	GROUP BY CustomerID
)

SELECT orderCount, COUNT(CustomerID) as 'amount of customers'
FROM     ordersPerCustomer
GROUP BY orderCount

-- 3. Give the customers of the Country in which most customers live
WITH CustomerPerCountry(Country, customerCount) AS (
	SELECT
		Country,
		Count(CustomerID)
	FROM Customers 
	GROUP BY Country
),

MaxCustomers(maxCustomerCount) AS (
	SELECT MAX(customerCount) as 'amount of customers'
	FROM     CustomerPerCountry
)

SELECT cc.Country,  cc.customerCount
FROM CustomerPerCountry  cc
JOIN MaxCustomers mc
ON cc.customerCount = mc.maxCustomerCount;

-- 5. What is the total number of customers and suppliers?

WITH cust(total) 
AS 
(
	SELECT Count(CustomerID)
	FROM Customers 
),
supp(total) 
AS 
(
	SELECT Count(SupplierID)
	FROM Suppliers 
)


SELECT supp.total + cust.total  as 'total'
FROM supp CROSS JOIN cust

-- 6. Give per title the eldest employee

WITH eldest(title, birthdate) AS (
	SELECT title, MIN(BirthDate)
	FROM Employees
	GROUP BY Title
)

SELECT e.title, e.FirstName + ' ' + e.LastName as fullName, el.birthdate
FROM eldest el
LEFT JOIN Employees e 
ON el.title = e.Title AND el.birthdate = e.BirthDate

-- 7. Give per title the employee that earns most

WITH ballers(title, salary) AS (
	SELECT title, MAX(Salary)
	FROM Employees
	GROUP BY Title
)

SELECT e.title, e.FirstName + ' ' + e.LastName as fullName, el.salary
FROM ballers el
LEFT JOIN Employees e 
ON el.title = e.Title AND el.salary = e.Salary

-- 8. Give the titles for which the eldest employee is also the employee who earns most

WITH eldest(title, birthdate) AS (
	SELECT title, MIN(BirthDate)
	FROM Employees
	GROUP BY Title
),

eldestEmployees(title, fullName, birthdate) AS (
	SELECT e.title, e.FirstName + ' ' + e.LastName as fullName, el.birthdate
	FROM eldest el
	LEFT JOIN Employees e 
	ON el.title = e.Title AND el.birthdate = e.BirthDate
),

ballers(title, salary) AS (
	SELECT title, MAX(Salary)
	FROM Employees
	GROUP BY Title
),

ballerEmployees(title, fullName, salary) AS (
	SELECT e.title, e.FirstName + ' ' + e.LastName as fullName, el.salary
	FROM ballers el
	LEFT JOIN Employees e 
	ON el.title = e.Title AND el.salary = e.Salary
)

SELECT be.title, be.fullName, be.salary, ee.birthdate 
FROM ballerEmployees be
LEFT JOIN eldestEmployees ee ON be.fullName = ee.fullName
WHERE ee.birthdate IS NOT NULL

-- OR

WITH eldestPerTitle(title, min_birthdate) AS
(SELECT title, min(birthdate)
FROM employees
GROUP BY title),

mostEarningPerTitle(title, max_salary) AS
(SELECT title, max(salary)
FROM employees
GROUP BY title)

SELECT employeeid, ept.title, ept.min_birthdate, mept.max_salary
FROM Employees e JOIN eldestPerTitle ept
ON e.title = ept.title
JOIN mostEarningPerTitle mept ON e.title = mept.title
WHERE e.BirthDate = ept.min_birthdate AND e.salary = mept.max_salary

-- 9. Execute the following script:
CREATE TABLE Parts
(
[Super] CHAR(3) NOT NULL,
[Sub] CHAR(3) NOT NULL,
[Amount] INT NOT NULL,
PRIMARY KEY(Super, Sub)
);
INSERT INTO Parts VALUES ('O1','O2',10);
INSERT INTO Parts VALUES ('O1','O3',5);
INSERT INTO Parts VALUES ('O1','O4',10);
INSERT INTO Parts VALUES ('O2','O5',25);
INSERT INTO Parts VALUES ('O2','O6',5);
INSERT INTO Parts VALUES ('O3','O7',10);
INSERT INTO Parts VALUES ('O6','O8',15);
INSERT INTO Parts VALUES ('O8','O11',5);
INSERT INTO Parts VALUES ('O9','O10',20);
INSERT INTO Parts VALUES ('O10','O11',25);


/*
SUPER SUB PAD
O2 O5 O2 <-O5
O2 O6 O2 <-O6
O6 O8 O2 <-O6 <-O8
O8 O11 O2 <-O6 <-O8 <-O11
*/

-- Show all parts that are directly or indirectly part of O2,
-- so all parts of which O2 is composed.
-- Add an extra column with the path as shown:


WITH PartsConnected (super, sub, level, Paths)
AS
(
  SELECT Super, Sub, 1, CAST(CONCAT(Super,'<-',Sub)AS NVARCHAR(MAX)) as Paths
  FROM Parts
  WHERE Super = 'O2' 
  UNION ALL
    SELECT 
      p.Super, p.Sub, pc.level + 1, CONCAT(pc.Paths,'<-',p.Sub)
    FROM Parts p 
    JOIN PartsConnected pc ON p.Super = pc.sub
)

SELECT * FROM PartsConnected;
```

```SQL
-- Give the names of all countries for which a larger percentage of people
-- was vaccinated (not fully vaccinated) than for Belgium on 1 april 2021

WITH vacinationRate(country, vaccinationRate) AS (
	SELECT c.country, cd.people_fully_vaccinated * 1.0 / c.population
	FROM CovidData cd
	JOIN Countries c
	ON cd.country = c.country
	WHERE report_date = '04/11/2021'
), 

vacinationRateBelgium(vaccinationRate) AS (
	SELECT vaccinationRate
	FROM vacinationRate
	WHERE country = 'Belgium'
)

SELECT country, vr.vaccinationRate
FROM vacinationRate vr
CROSS JOIN vacinationRateBelgium vrb
WHERE vr.vaccinationRate > vrb.vaccinationRate


WITH cte_1 (percentage_vaccinated_Belgium)
AS
(SELECT cd.people_vaccinated * 1.0 / c.population
FROM CovidData cd JOIN Countries c ON cd.country = c.country
WHERE report_date = '2021-04-01' and cd.country = 'Belgium')

SELECT cd.country, cd.people_vaccinated * 1.0 / c.population
FROM CovidData cd JOIN Countries c ON cd.country = c.country JOIN cte_1 ON cd.people_vaccinated * 1.0 / c.population > percentage_vaccinated_Belgium
WHERE report_date = '2021-04-01'



-- Give for each month the percentage of fully vaccinated people in Belgium 
--- at the end of the month

/*
12	2020	0.00%
1	2021	0.23%
2	2021	2.93%
3	2021	4.86%
4	2021	7.48%
5	2021	19.10%
6	2021	35.01%
7	2021	59.28%
8	2021	70.06%
*/

WITH vacinationRate(reportDate, reportMonth, reportYear) AS (
	SELECT MAX(cd.report_date), MONTH(report_date), YEAR(report_date)
	FROM CovidData cd
	JOIN Countries c
	ON cd.country = c.country
	WHERE c.country = 'Belgium'
	GROUP BY MONTH(report_date), YEAR(report_date)
)

SELECT reportMonth, reportYear, reportDate, FORMAT(cd.people_fully_vaccinated * 1.0 / c.population, 'P') as 'vaccination rate'
FROM vacinationRate
JOIN CovidData cd
ON cd.report_date = reportDate
JOIN Countries c
ON c.country = cd.country
WHERE cd.country = 'Belgium' AND cd.people_fully_vaccinated IS NOT NULL

WITH cte_end_month([month], [year], endday)
AS
(SELECT month(report_date), year(report_date), MAX(report_date)
FROM covidData
WHERE country = 'Belgium'
GROUP BY month(report_date), year(report_date))

SELECT [month], [year], FORMAT(cd.people_fully_vaccinated * 1.0 / c.population, 'P')
FROM coviddata cd JOIN countries c ON cd.country = c.country
JOIN cte_end_month cte ON cte.endday = cd.report_date
WHERE cd.country = 'Belgium' AND cd.people_fully_vaccinated IS NOT NULL


-- What is the percentage of the total amount of new_cases that died in the following periods in Belgium
-- march 2020 - may 2020 / june 2020 - august 2020 / september 2020 - november 2020 / december 2020 - february 2021 / march 2021 - may 2021 / june 2021 - august 2021

/*
march 2020 - may 2020	16.22%
june 2020 - august 2020	1.59%
september 2020 - november 2020	1.37%
december 2020 - february 2021	2.80%
march 2021 - may 2021	0.99%
june 2021 - august 2021	0.35%
*/


WITH cte_1 (report_date, new_cases, new_deaths, periode)
AS
(SELECT report_date, new_cases, new_deaths,
CASE 
WHEN report_date BETWEEN '2020-03-01' AND '2020-05-31' THEN 'march 2020 - may 2020'
WHEN report_date BETWEEN '2020-06-01' AND '2020-08-31' THEN 'june 2020 - august 2020'
WHEN report_date BETWEEN '2020-09-01' AND '2020-11-30' THEN 'september 2020 - november 2020'
WHEN report_date BETWEEN '2020-12-01' AND '2021-02-28' THEN 'december 2020 - february 2021'
WHEN report_date BETWEEN '2021-03-01' AND '2021-05-31' THEN 'march 2021 - may 2021'
WHEN report_date BETWEEN '2021-06-01' AND '2021-08-31' THEN 'june 2021 - august 2021'
END AS periode
FROM CovidData
WHERE country = 'Belgium')

SELECT periode, FORMAT(SUM(new_deaths * 1.0) / SUM(new_cases * 1.0), 'P') As sterfpercentage
FROM cte_1
WHERE periode IS NOT NULL
GROUP BY periode
ORDER BY SUM(new_deaths * 1.0) / SUM(new_cases * 1.0) DESC

-- Which country(ies) was(were) the first to have 50% of the population fully vaccinated

WITH vacinationRate(earliestDate) AS (
	SELECT 
		MIN(report_date)
	FROM CovidData cd
	JOIN Countries c
	ON cd.country = c.country
	WHERE cd.people_fully_vaccinated * 1.0 / c.population > 0.5
)

SELECT cd.country 
FROM CovidData as cd
JOIN Countries c
ON cd.country = c.country
JOIN vacinationRate vr
ON vr.earliestDate = cd.report_date
WHERE cd.people_fully_vaccinated * 1.0 / c.population > 0.5
```
