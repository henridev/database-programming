# Cursors

- sql statements are generallt processing a complete result-set (SELECT, UPDATE, DELETE)
- A SQL Server cursor is a databse object which refers to results of a query, it allows yo specify one at a time a row from the resultset
- A SQL Server cursor is a set of T-SQL logic to loop over a predetermined number of rows one at a time => **sequentialy**

important cursor statements:

- `DECLARE CURSOR`
- `OPEN`
- `FETCH` => fetch next row
- `CLOSE`
- `DEALLOCATE` => removes cursor definition

```SQL
-- declare variables used in cursor
DECLARE @city_name VARCHAR(128);
DECLARE @country_name VARCHAR(128);
DECLARE @city_id INT;
 
-- DECLARE: declare cursor
DECLARE cursor_city_country CURSOR FOR
  SELECT city.id, TRIM(city.city_name), TRIM(country.country_name)
  FROM city
  INNER JOIN country ON city.country_id = country.id;
 
-- OPEN: open cursor
OPEN cursor_city_country;
 
-- FETCH: loop through a cursor
FETCH NEXT FROM cursor_city_country INTO @city_id, @city_name, @country_name;
WHILE @@FETCH_STATUS = 0
    BEGIN
    	PRINT CONCAT('city id: ', @city_id, ' / city name: ', @city_name, ' / country name: ', @country_name);
    	FETCH NEXT FROM cursor_city_country INTO @city_id, @city_name, @country_name;
    END;
 
-- CLOSE / DEALLOCATE : close and deallocate cursor
CLOSE cursor_city_country;
DEALLOCATE cursor_city_country;
```

![image](https://slideplayer.com/slide/9217243/27/images/7/Controlling+Explicit+Cursors.jpg)

## declaration

```SQL
DECLARE <cursor_name> [INSENSITIVE][SCROLL] CURSOR FOR <SELECT_statement>
[FOR {READ_ONLY | UPDATE [OF <column list>]}] 
```

- `SCROLL` => all fetch operations (`first,last,prior,next,relative,absolute`) are allowed (might give difficult to understand code)
- `READ ONLY` => prohibit data change underlying table via cursor
- `UPDATE` => data changes are allowed (specify column that are allowed to change)

## open

```SQL
OPEN <cursor_name>
```

1. open cursor
2. fill cursor by executing select and creating virtual table with **active set**
3. cursor pointer placed just before first row result set

## Fetch data with cursor

```SQL
FETCH [NEXT | PRIOR | FIRST | LAST | {ABSOLUTE | RELATIVE <row number>}]
FROM <cursor_name>
[INTO <variable name>[,...<last variable name>]]
```

- position cursor
  - on nex, previous, first, last or specific row
  - default only allows next (else enable scroll)
- fetch data
  - WITH into => assign data to specific variables
  - WITHOUT into => result data shown on screen

## close cursor

```SQL
CLOSE <cursor_name>
```

- definition remains
- cursor can be reopened

## deallocate cursor

```SQL
DEALLOCATE <cursor_name>
```

- definition removed
- if last reference to cursor all resources get released
- deallocate will close too if not already done

## nested cursors

- declaring 2 or + cursors in same block
- often related via params

> example: multi-level report with each level using rows from different cursor

```SQL
DECLARE @supplierID INT, @companyName NVARCHAR(30), @city NVARCHAR(15)
DECLARE @productID INT, @productName NVARCHAR(40), @unitPrice MONEY
 
DECLARE s_cursor CURSOR FOR
SELECT SupplierID, CompanyName, City FROM Suppliers WHERE country = 'USA'

OPEN s_cursor
 
FETCH NEXT FROM s_cursor INTO @supplierID, @companyName, @city

WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT 'Supplier: ' + STR(@supplierID) + ' ' + @companyName + ' ' + @city

	DECLARE p_cursor CURSOR FOR 
	-- here it's related to s_cursor
	SELECT ProductId, ProductName, UnitPrice FROM Products WHERE SupplierID = @supplierID

	OPEN p_cursor
 
	FETCH NEXT FROM p_cursor INTO @productID, @productName, @unitPrice

	WHILE @@FETCH_STATUS = 0
	BEGIN
		PRINT '- ' + STR(@productID) + ' ' + @productName + ' ' + STR(@unitPrice) + 'EUR'
		FETCH NEXT FROM p_cursor INTO @productID, @productName, @unitPrice
	END
	CLOSE p_cursor
	DEALLOCATE p_cursor
	 
	FETCH NEXT FROM s_cursor INTO @supplierID, @companyName, @city

END;
 
CLOSE s_cursor;
DEALLOCATE s_cursor;
```

## update and delete via cursor => **cursor based positioned delete/update**

```SQL
DELETE FROM <table_name>
WHERE CURRENT OF <cursor_name>
```

```SQL
UPDATE <table_name>
SET ...
WHERE CURRENT OF <cursor_name>
```

- affects row the cursor referred in `WHERE CURRENT OF` refers to

```SQL
DECLARE @shipperID INT, @companyName NVARCHAR(30)

DECLARE s_cursor CURSOR FOR
  SELECT ShipperID, CompanyName FROM Shippers
 
OPEN s_cursor;
 
FETCH NEXT FROM s_cursor INTO @shipperID, @companyName

WHILE @@FETCH_STATUS = 0
    BEGIN
    	PRINT '- ' + STR(@shipperID) + ' ' + @companyName
		IF @shipperID > 4
    		DELETE FROM Shippers WHERE CURRENT OF s_cursor
		FETCH NEXT FROM s_cursor INTO @shipperID, @companyName
    END;
 
CLOSE s_cursor;
DEALLOCATE s_cursor;
```

## exercices

```SQL
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

DECLARE @categoryID INT, @categoryName NVARCHAR(15)
DECLARE @count INT

DECLARE c_cursor CURSOR FOR
SELECT CategoryID, CategoryName FROM dbo.Categories c

OPEN c_cursor
 
FETCH NEXT FROM c_cursor INTO @categoryID, @categoryName

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @count = COUNT(*) FROM dbo.Products p WHERE CategoryID = @categoryID
	PRINT 
		'Category: ' + STR(@categoryID) + ' ' +  
		@categoryName + '----> ' + STR(@count)
	FETCH NEXT FROM c_cursor INTO @categoryID, @categoryName

END;
 
CLOSE c_cursor;
DEALLOCATE c_cursor;

-- Exercise 2
-- Give an overview of the employees per country. Use a nested cursor.
/*
* UK
- 5 Steven Buchanan London
- 6 Michael Suyama London
- 7 Robert King London
- 9 Anne Dodsworth London
* USA
- 1 Nancy Davolio Seattle
- 2 Andrew Fuller Tacoma
- 3 Janet Leverling Kirkland
- 4 Margaret Peacock Redmond
- 8 Laura Callahan Seattle
*/

DECLARE @country NVARCHAR(15)
DECLARE @name NVARCHAR(31), @city NVARCHAR(15)
DECLARE @count INT = 1

DECLARE c_cursor CURSOR FOR
SELECT DISTINCT(Country) FROM Employees e

OPEN c_cursor

FETCH NEXT FROM c_cursor INTO @country

WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT @country

	DECLARE e_cursor CURSOR FOR 
	SELECT LastName + ' ' + FirstName, city FROM Employees e WHERE Country = @country

	OPEN e_cursor
 
	FETCH NEXT FROM e_cursor INTO @name, @city

	WHILE @@FETCH_STATUS = 0
	BEGIN
		PRINT STR(@count) + ' ' + @name + ' ' + @city
		FETCH NEXT FROM e_cursor INTO @name, @city
		SET @count = @count + 1
	END
	CLOSE e_cursor
	DEALLOCATE e_cursor
	SET @count = 1
	FETCH NEXT FROM c_cursor INTO @country
END;
 
CLOSE c_cursor;
DEALLOCATE c_cursor;


-- Exercise 3
/*
Create an overview of bosses and employees who have
to report to this boss and 
also give the number of employees who have to report to this boss.
Use a nested cursor.
* Andrew Fuller
- 1 Nancy Davolio
- 3 Janet Leverling
- 4 Margaret Peacock
- 5 Steven Buchanan
- 8 Laura Callahan
Total number of employees =          5
* Steven Buchanan
- 6 Michael Suyama
- 7 Robert King
- 9 Anne Dodsworth
Total number of employees =          3
*/


DECLARE @boss int, @boss_name NVARCHAR(31)
DECLARE @employee int, @employee_name NVARCHAR(31)
DECLARE @count INT = 0

DECLARE b_cursor CURSOR FOR
SELECT DISTINCT(ReportsTo) FROM Employees e

OPEN b_cursor

FETCH NEXT FROM b_cursor INTO @boss

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @boss_name = LastName + ' ' + FirstName FROM Employees e WHERE EmployeeID = @boss

	PRINT @boss_name
	
	DECLARE e_cursor CURSOR FOR 
	SELECT EmployeeID, LastName + ' ' + FirstName FROM Employees e WHERE ReportsTo = @boss

	OPEN e_cursor
 
	FETCH NEXT FROM e_cursor INTO @employee, @employee_name

	WHILE @@FETCH_STATUS = 0
	BEGIN
		PRINT STR(@employee) + ' ' + @employee_name
		FETCH NEXT FROM e_cursor INTO @employee, @employee_name
		SET @count = @count + 1
	END
	CLOSE e_cursor
	DEALLOCATE e_cursor
	IF @count > 0
		PRINT 'Total number of employees ' + STR(@count)
	
	SET @count = 0
	FETCH NEXT FROM b_cursor INTO @boss
END;
 
CLOSE b_cursor;
DEALLOCATE b_cursor;
```