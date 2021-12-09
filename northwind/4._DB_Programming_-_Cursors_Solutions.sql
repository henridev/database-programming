/************************/
/******* Cursors ********/
/************************/

/*
SQL statements are processing complete resultsets and not individual rows. 
Cursors allow to process individual rows to perform complex row specific 
operations that can't (easily) be performed with a single SELECT, UPDATE or DELETE statement.
A cursor is a database object that refers to the result of a query. 
It allows to specify the row from the resultset you wish to process.

A cursor is a database object that refers to the result of a query. 
It allows to specify the row from the resultset you wish to process.

5 important cursor related statements
- DECLARE CURSOR – creates and defines the cursor
- OPEN – opens the declared cursor
- FETCH – fetches 1 row
- CLOSE – closes the cursor (counterpart of OPEN)
- DEALLOCATE – remove the cursor definition (counterpart of DECLARE)


*/


DECLARE @supplierID INT, @companyName NVARCHAR(30), @city NVARCHAR(15)

-- declare cursor
DECLARE suppliers_cursor CURSOR 
FOR
SELECT SupplierID, CompanyName, City
FROM Suppliers
WHERE Country = 'USA'

-- open cursor
OPEN suppliers_cursor

-- fetch data
FETCH NEXT FROM suppliers_cursor INTO @supplierID, @companyName, @city

WHILE @@FETCH_STATUS = 0 
BEGIN 
	PRINT 'Supplier: ' + str(@SupplierID) + ' ' + @companyName + ' ' + @city
  	FETCH NEXT FROM suppliers_cursor INTO @supplierID, @companyName, @city
END 

-- close cursor
CLOSE suppliers_cursor

-- deallocate cursor
DEALLOCATE suppliers_cursor

-- Exercise
-- Give an overview of all contactNames in Suppliers 
-- that are some kind of manager

/*
- Exotic Liquids > Charlotte Cooper > Purchasing Manager
- Tokyo Traders > Yoshi Nagase > Marketing Manager
- Pavlova, Ltd. > Ian Devling > Marketing Manager
- Refrescos Americanas LTDA > Carlos Diaz > Marketing Manager
- Heli Süßwaren GmbH & Co. KG > Petra Winkler > Sales Manager
- Norske Meierier > Beate Vileid > Marketing Manager
- Aux joyeux ecclésiastiques > Guylène Nodier > Sales Manager
- Lyngbysild > Niels Petersen > Sales Manager
- Zaanse Snoepfabriek > Dirk Luchte > Accounting Manager
...
*/

DECLARE @companyName nvarchar(40), @contactName NVARCHAR(30), @contactTitle NVARCHAR(30)

-- declare cursor
DECLARE contact_cursor CURSOR 
FOR
SELECT CompanyName, ContactName, ContactTitle
FROM Suppliers
WHERE ContactTitle LIKE '%manager%'

-- open cursor
OPEN contact_cursor

-- fetch data
FETCH NEXT FROM contact_cursor INTO  @companyName, @contactName, @contactTitle

WHILE @@FETCH_STATUS = 0 
BEGIN 
	PRINT '- ' + @companyName + ' > ' + @contactName + ' > ' + @contactTitle
  	FETCH NEXT FROM contact_cursor INTO @companyName, @contactName, @contactTitle
END 

-- close cursor
CLOSE contact_cursor

-- deallocate cursor
DEALLOCATE contact_cursor


/************************/
/****  Nested cursors  **/
/************************/

DECLARE @supplierID INT, @companyName NVARCHAR(30), @city NVARCHAR(15)
DECLARE @productID INT, @productName NVARCHAR(40), @unitPrice MONEY

-- declare cursor
DECLARE suppliers_cursor CURSOR 
FOR
SELECT SupplierID, CompanyName, City
FROM Suppliers
WHERE Country = 'USA'

-- open cursor
OPEN suppliers_cursor

-- fetch data
FETCH NEXT FROM suppliers_cursor INTO @supplierID, @companyName, @city

WHILE @@FETCH_STATUS = 0 
BEGIN 
	PRINT 'Supplier: ' + str(@SupplierID) + ' ' + @companyName + ' ' + @city
	--  begin inner cursor
	DECLARE products_cursor CURSOR 	FOR
	SELECT ProductID, ProductName, UnitPrice FROM Products WHERE SupplierID = @supplierID

	-- open cursor
	OPEN products_cursor

	-- fetch data
	FETCH NEXT FROM products_cursor INTO @productID, @productName, @unitPrice

	WHILE @@FETCH_STATUS = 0 
	BEGIN
		PRINT '- ' + STR(@productID) + ' ' + @productName + ' ' + STR(@unitPrice) + 'EUR'
		FETCH NEXT FROM products_cursor INTO @productID, @productName, @unitPrice
	END

	CLOSE products_cursor

	-- deallocate cursor
	DEALLOCATE products_cursor

	-- end inner cursor
  	FETCH NEXT FROM suppliers_cursor INTO @supplierID, @companyName, @city
END 

-- close cursor
CLOSE suppliers_cursor

-- deallocate cursor
DEALLOCATE suppliers_cursor


/************************/
/** Cursor for update  **/
/************************/

BEGIN TRANSACTION
SELECT count(shipperID) FROM Shippers

DECLARE @shipperID INT, @companyName NVARCHAR(40)

-- declare cursor
DECLARE shippers_cursor CURSOR FOR
SELECT ShipperID, CompanyName FROM Shippers

-- open cursor
OPEN shippers_cursor

-- fetch data
FETCH NEXT FROM shippers_cursor INTO @shipperID, @companyName

WHILE @@FETCH_STATUS = 0 
BEGIN
	PRINT '- ' + STR(@shipperID) + ' ' + @companyName
	IF @shipperID > 4
		DELETE FROM Shippers WHERE CURRENT OF shippers_cursor

	FETCH NEXT FROM shippers_cursor INTO @shipperID, @companyName
END

CLOSE shippers_cursor
DEALLOCATE shippers_cursor


SELECT count(shipperID) FROM Shippers
ROLLBACK

/*************************/
/********Exercises *******/
/*************************/

-- Exercise 1
-- Create the following overview of the number of products per category
/**
Category:          1 Beverages -->         13
Category:          2 Condiments -->         13
Category:          3 Confections -->         13
Category:          4 Dairy Products -->         10
Category:          5 Grains/Cereals -->          7
Category:          6 Meat/Poultry -->          6
Category:          7 Produce -->          5
Category:          8 Seafood -->         12
**/


DECLARE @categoryID INT, @categoryName NVARCHAR(15), @numberOfProducts INT

-- declare cursor
DECLARE categories_cursor CURSOR 
FOR
SELECT c.CategoryID, CategoryName, COUNT(ProductID)
FROM Categories c JOIN Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryID, CategoryName


-- open cursor
OPEN categories_cursor

-- fetch data
FETCH NEXT FROM categories_cursor INTO @categoryID, @categoryName, @numberOfProducts

WHILE @@FETCH_STATUS = 0 
BEGIN 
	PRINT 'Category: ' + str(@CategoryID) + ' ' + @categoryName + ' --> ' + STR(@numberOfProducts)
  	FETCH NEXT FROM categories_cursor INTO  @categoryID, @categoryName, @numberOfProducts
END 

-- close cursor
CLOSE categories_cursor

-- deallocate cursor
DEALLOCATE categories_cursor



-- Exercise 2
-- Give an overview of the employees per country. Use a nested cursor.
/*

* UK
    -          5 Steven Buchanan London
    -          6 Michael Suyama London
    -          7 Robert King London
    -          9 Anne Dodsworth London
* USA
    -          1 Nancy Davolio Seattle
    -          2 Andrew Fuller Tacoma
    -          3 Janet Leverling Kirkland
    -          4 Margaret Peacock Redmond
    -          8 Laura Callahan Seattle
*/

DECLARE @country NVARCHAR(30)
DECLARE @employeeID INT, @fullName NVARCHAR(50), @city NVARCHAR(15)

-- declare cursor
DECLARE country_cursor CURSOR 
FOR
SELECT DISTINCT country
FROM employees


-- open cursor
OPEN country_cursor

-- fetch data
FETCH NEXT FROM country_cursor INTO @country

WHILE @@FETCH_STATUS = 0 
BEGIN 
	PRINT '* ' + @country
	--  begin inner cursor
	DECLARE employees_cursor CURSOR 	FOR
	SELECT EmployeeID, firstname + ' ' + lastname, city FROM Employees WHERE country = @country

	-- open cursor
	OPEN employees_cursor

	-- fetch data
	FETCH NEXT FROM employees_cursor INTO @employeeID, @fullName, @city

	WHILE @@FETCH_STATUS = 0 
	BEGIN
		PRINT '    - ' + STR(@employeeID) + ' ' + @fullName + ' ' + @city
		FETCH NEXT FROM employees_cursor INTO @employeeID, @fullName, @city
	END

	CLOSE employees_cursor

	-- deallocate cursor
	DEALLOCATE employees_cursor

	-- end inner cursor
	FETCH NEXT FROM country_cursor INTO @country
END 

-- close cursor
CLOSE country_cursor

-- deallocate cursor
DEALLOCATE country_cursor


-- Exercise 3
/*
Create an overview of bosses and employees who have
to report to this boss and 
also give the number of employees who have to report to this boss.
Use a nested cursor.

* Andrew Fuller
    -          1 Nancy Davolio
    -          3 Janet Leverling
    -          4 Margaret Peacock
    -          5 Steven Buchanan
    -          8 Laura Callahan
Total number of employees =          5
* Steven Buchanan
    -          6 Michael Suyama
    -          7 Robert King
    -          9 Anne Dodsworth
Total number of employees =          3
*/

DECLARE @reportsTo INT, @bossName NVARCHAR(50)
DECLARE @employeeID INT, @fullName NVARCHAR(50)
DECLARE @numberOfEmployees INT = 0

-- declare cursor
DECLARE boss_cursor CURSOR 
FOR
SELECT DISTINCT reportsTo
FROM employees
WHERE reportsTO IS NOT NULL


-- open cursor
OPEN boss_cursor

-- fetch data
FETCH NEXT FROM boss_cursor INTO @reportsTo

WHILE @@FETCH_STATUS = 0 
BEGIN 
	-- What's the name of the name
	SELECT @bossName = firstName + ' ' + lastName FROM employees WHERE employeeID = @reportsTo
	PRINT '* ' + @bossName
	
	SET @numberOfEmployees = 0
	
	--  begin inner cursor

	DECLARE employees_cursor CURSOR FOR
	SELECT EmployeeID, firstname + ' ' + lastname FROM Employees WHERE reportsTo = @reportsTo

	-- open cursor
	OPEN employees_cursor

	-- fetch data
	FETCH NEXT FROM employees_cursor INTO @employeeID, @fullName

	WHILE @@FETCH_STATUS = 0 
	BEGIN
		PRINT '    - ' + STR(@employeeID) + ' ' + @fullName
		SET @numberOfEmployees += 1
		FETCH NEXT FROM employees_cursor INTO @employeeID, @fullName
	END

	CLOSE employees_cursor

	-- deallocate cursor
	DEALLOCATE employees_cursor
	PRINT 'Total number of employees = ' + STR(@numberOfEmployees)

	-- end inner cursor
	FETCH NEXT FROM boss_cursor INTO @reportsTo
END 

-- close cursor
CLOSE boss_cursor

-- deallocate cursor
DEALLOCATE boss_cursor


