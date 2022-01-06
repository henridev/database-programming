# exercices SP and UDF

```SQL
-- Give per product category the price of the cheapest product that costs more than x € and a product with that price.s

CREATE FUNCTION cheapest_product_per_category_above_price_x (@price AS MONEY)
RETURNS TABLE AS
RETURN
	SELECT * FROM (
		SELECT
			*,
			ROW_NUMBER() OVER (PARTITION BY CategoryID ORDER BY UnitPrice ASC) as ROW_NUMBER
		FROM Northwind.dbo.Products
		WHERE UnitPrice > @price
	) AS ranked WHERE ROW_NUMBER = 1;

-- Exercise: Write a function that calculates the netto salary per month for each employee
-- If salary < 4000 EUR per month => tax is 30%
-- If salary < 5500 EUR per month => tax is 35%
-- Else => tax is 40%
-- Give an overview of firstname, lastname, birthdate, salary and netto salary for each employee
-- Give an overview of all employees that earn more than 2800 each month

ALTER FUNCTION GetNettoSalary(@salary as DECIMAL(10,2))
RETURNS DECIMAL(10,2) 
AS
BEGIN
	RETURN CASE 
			WHEN @salary < 4000 THEN (@salary - (@salary * 0.3))
			WHEN @salary < 5500 THEN (@salary - (@salary * 0.35))
			ELSE (@salary - (@salary * 0.4))
	END
END


SELECT firstname, lastname, birthdate, salary, dbo.GetNettoSalary(Salary) as 'netto salary' FROM Northwind.dbo.Employees e 

-- Exercise 1
-- In case a supplier goes bankrupt, we need to inform the customers on this
-- Write a SP that gives all information about the customers that ordered a product of this supplier during 
-- the last 6 months,
-- given the companyname of the supplier, so we will be able to inform the appropriate customers
-- First check if the companyname IS NOT NULL and if there is a supplier with this companyname
-- Then check if there isn't by chance more than 1 supplier with this companyname 
-- Use in the procedure '2018-10-21' instead of GETDATE(), otherwise the procedure won't return any records.
-- The procedure returns the number of found customers using an OUTPUT parameter
-- TO DO
-- (1) Test if companyname is NOT NULL
-- (2) Test if companyname exists
-- (3) Test if there is more than 1 supplier with the given companyname
-- (4) SELECT statement to get customers from supplier  use DATEDIFF(MONTH, orderDate, '2018-10-21')
-- (5) number of customers --> @@rowcount
-- Write testcode 
-- (*) in which companyName IS NULL
-- (*) in which companyName does not exist
-- (*) in which companyName = Refrescos Americanas LTDA. 

CREATE OR ALTER PROCEDURE CustomersOfBankruptSupplier (
	@companyname NVARCHAR(40), @customersfound INT OUT
)
AS
BEGIN 
	-- check if name given
	IF @companyname IS NULL
	BEGIN
		PRINT 'Please provide a company name'
		RETURN
	END
	
	-- check if unique name
	DECLARE @numberOfSuppliers INT = (
		SELECT COUNT(SupplierID) 
		FROM Northwind.dbo.Suppliers 
		WHERE CompanyName = @companyname
	)
	
	IF @numberOfSuppliers <> 1
	BEGIN
		PRINT 'This company is not unique or does not exist'
		RETURN
	END
	
	SELECT *
	FROM Customers c 
	JOIN Orders o 
	ON c.CustomerID = o.CustomerID 
	JOIN OrderDetails od 
	ON od.OrderID = o.OrderID
	JOIN Products p 
	ON p.ProductID = od.ProductID 
	JOIN Suppliers s 
	ON s.SupplierID = p.SupplierID
	WHERE 
		DATEDIFF(MONTH,o.OrderDate,'2018-10-21') <= 6 
	AND 
		s.companyName = @companyName
	
	SET @customersfound = @@ROWCOUNT
END 

DECLARE @customerCount INT
EXEC CustomersOfBankruptSupplier 'Refrescos Americanas LTDA', @customerCount OUT
PRINT 'number of cutsomers under bankrupt supplier: ' + STR(@customerCount)


CREATE PROCEDURE InserOrderDetails (
	@OrderID int,
	@ProductID int,
	@UnitPrice money = NULL,
	@Quantity smallint = 1,
	@Discount real = 0.0
)
AS
DECLARE @normalUnitPrice money, @maxOrderedQuantity smallint
BEGIN 
	IF @OrderID IS NULL
	BEGIN
		PRINT 'Please provide a OrderID'
		RETURN
	END
	IF @ProductID IS NULL
	BEGIN
		PRINT 'Please provide a ProductID'
		RETURN
	END
	
	IF NOT EXISTS (SELECT * FROM dbo.Orders o WHERE OrderID = @OrderID)
	BEGIN
		PRINT 'This Order does not exist'
		RETURN
	END
	
	IF NOT EXISTS (SELECT * FROM dbo.Products p WHERE ProductID = @ProductID)
	BEGIN
		PRINT 'This product does not exist'
		RETURN
	END
	
	SET @normalUnitPrice = (SELECT UnitPrice FROM dbo.Products p WHERE ProductID = @ProductID)
	
	IF @UnitPrice IS NULL 
	BEGIN
	    SET @UnitPrice = (SELECT UnitPrice FROM dbo.Products p WHERE ProductID = @ProductID)
	END 
	
	IF ABS((@normalUnitPrice - @UnitPrice) / @UnitPrice) > 0.25
	BEGIN 
		PRINT 'Unit price difference too large'
		RETURN
	END
	
	IF @Discount < 0 OR @Discount > 0.15
	BEGIN 
		PRINT 'Invalid discount value'
		RETURN
	END
	
	SET @maxOrderedQuantity = (SELECT MAX(Quantity) FROM dbo.OrderDetails od WHERE ProductID = @ProductID)
	
	IF @Quantity > @maxOrderedQuantity * 2
	BEGIN 
		PRINT 'Order quantity is too large'
		RETURN
	END
	
	INSERT INTO dbo.OrderDetails (
		OrderID,
		ProductID,
		UnitPrice,
		Quantity,
		Discount
	)
	VALUES (@OrderID, @ProductID, @UnitPrice, @Quantity, @Discount)
END



BEGIN TRANSACTION
EXEC InserOrderDetails 10249, 172, 35, 10, 0.35
SELECT * FROM OrderDetails WHERE OrderID = 10249
ROLLBACK;

-- Exercise 3
-- Create a stored procedure for deleting a shipper. You can only delete a shipper if
-- (*) The shipperID exists
-- (*) There are no Orders for this shipper
-- Write two versions of your procedure:
-- (*) In the first version you check these conditions before deleting the shipper, 
-- so you don't rely on SQL Server messages. Generate an appropriate error message if the shipper can't be 
-- deleted. 
-- (*) In the second version you try to delete the shipper and catch the exceptions that might occur. 
-- Write testcode to delete shipper with shipperID = 10 (doesn't exist) / 5 (exists + no shippings) / 3 
-- (exists + already shippings). 
-- Put everything in a transaction. Messages are visible on the Messages tab



CREATE PROCEDURE DeleteShipper (@ShipperID int=NULL,@NumberOfDeletedShippers int=0)
AS
BEGIN
	IF @ShipperID IS NULL
	BEGIN
		PRINT 'Please provide a shipperID'
		RETURN
	END
	
	IF EXISTS (SELECT * FROM Northwind.dbo.Orders WHERE ShipVia = @ShipperID)
	BEGIN
		PRINT 'This shipper has orders assigned'
		RETURN
	END

	DELETE FROM Northwind.dbo.Shippers WHERE ShipperID = @ShipperID
	SET @NumberOfDeletedShippers = @@ROWCOUNT
END

CREATE OR ALTER PROCEDURE DeleteShipperTwo (@ShipperID int=NULL,@NumberOfDeletedShippers int=0)
AS
BEGIN
	BEGIN TRY
		DELETE FROM Northwind.dbo.Shippers WHERE ShipperID = @ShipperID
		SET @NumberOfDeletedShippers = @@ROWCOUNT
		IF @NumberOfDeletedShippers = 0
			THROW 50000,'The shipper doesn''t exist',14
		
		PRINT 'Shipper ' + STR(@shipperID) + ' deleted'
	END TRY
	BEGIN CATCH
		PRINT 'weve got ourselves an error folks'
		PRINT 'Error Number = ' + STR(ERROR_NUMBER())
		PRINT 'Error Procedure = ' + ERROR_PROCEDURE()
		PRINT 'Error Message = ' + ERROR_MESSAGE()
	END CATCH
END


BEGIN TRANSACTION
EXEC DeleteShipperTwo 10101
SELECT * FROM Shippers
ROLLBACK;

-- Exercise 1
-- Write a stored procedure to update already existing values 
-- for new_cases for a specific country and report_date
-- (1) If there isn't a record for the specific country and report_date 
-- (so you can't do the update), an exception is thrown
-- (2) Check if the new value is reasonable. 
-- A reasonable value is a value that is not 25% higher or lower than the average number of new cases of the past week
-- If not, throw an exception
-- (3) Do the update. Make sure the total_cases is updated too.
-- (4) Write testcode. Use transactions in order to keep the original data unchanged.
-- You can find the error messages in Messages
-- (4.1) Update the new_cases of Belgica on 2021-09-10 to 2200 (previous value was 2190)
-- (4.2) Update the new_cases of Belgium on 2021-09-10 to 3200 (previous value was 2190)
-- (4.3) Update the new_cases of Belgium on 2021-09-10 to 2200 (previous value was 2190)

CREATE OR ALTER PROCEDURE UpdateNewCases (@cases int=NULL, @country nvarchar(50), @report_date datetime2(7))
AS
BEGIN
	BEGIN TRY
		IF NOT EXISTS (SELECT * FROM Corona.dbo.CovidData WHERE country = @country AND report_date = @report_date)
		BEGIN
			THROW 50001, 'country with this report date does not exist', 1
		END	
		
		DECLARE @averageNewCasesLastWeek DECIMAL
		
		SELECT  @averageNewCasesLastWeek = AVG(new_cases) FROM 
		Corona.dbo.CovidData
		WHERE report_date 
	    BETWEEN DATEADD(DAY, -7, @report_date) AND @report_date
	    AND country = @country
		
		
		IF  @cases NOT BETWEEN (@averageNewCasesLastWeek* 0.75) AND (@averageNewCasesLastWeek * 1.25)
		BEGIN
			THROW 50001, 'A reasonable value is a value that is not 25% higher or lower than the average number of new cases of the past week', 1
		END	
		
		UPDATE Corona.dbo.CovidData
		SET new_cases = @cases
		WHERE country = @country AND report_date = @report_date
		
		DECLARE @old_new_cases int
		
		SELECT @old_new_cases = new_cases
		FROM Corona.dbo.CovidData 
		WHERE country = @country 
		AND report_date = @report_date
	
		DECLARE @diff_cases int
		SET @diff_cases = @cases - @old_new_cases

		UPDATE Corona.dbo.CovidData 
		SET total_cases = total_cases + @diff_cases  
		WHERE country = @country AND report_date >= @report_date
	END TRY
	
	BEGIN CATCH
		 THROW
	END CATCH
END

-- Testcode 1
BEGIN TRANSACTION 
EXEC UpdateNewCases 2200, 'Belgica', '2021-09-10'-- Original value = 2190
SELECT * FROM Corona.dbo.CovidData WHERE country = 'Belgium' and report_date >= '2021-09-10' -- only you (in  your session) can see changes
ROLLBACK;

-- Testcode 2

BEGIN TRANSACTION 
EXEC UpdateNewCases 3200, 'Belgium', '2021-09-10'
SELECT * FROM Corona.dbo.CovidData WHERE country = 'Belgium' and report_date >= '2021-09-10'
ROLLBACK;

-- Testcode 3

BEGIN TRANSACTION 
EXEC UpdateNewCases 2200, 'Belgium', '2021-09-10'
SELECT * FROM Corona.dbo.CovidData cd WHERE country = 'Belgium' and report_date >= '2021-09-10'
ROLLBACK;


-- Exercise 2

-- Write a stored procedure UpdatePopulation to update the population of a country
-- (1) If there isn't a country with the given name, an exception is thrown
-- (2) According to this website: https://www.indexmundi.com/map/?v=24&l=nl the population growth per country is a value between 5% and -8%. 
-- If the new value for the population for the given country doesn't meet
-- this constraints, an exception is thrown
-- (3) Write testcode. Use transactions in order to keep the original data unchanged.
-- You can find the error messages in Messages
-- (3.1) Update the population of Belgica to 11600000
-- (3.2) Update the population of Belgium to 21600000 
-- (3.3) Update the population of Belgium to 11600000 



-- Testcode 1

-- Testcode 2

-- Testcode 3

-- Exercise 3
-- Write a SP
-- (1) Calculate and print the startdate of the first golf in Belgium
-- (2) Calculate and print the enddate of the first golf in Belgium
-- (3) Calculate and print the startdate of the second golf in Belgium
-- (4) Calculate and print the enddate of the second golf in Belgium
-- (5) Calculate and print the total number of days and the total number of deaths during the first golf in Belgium
-- (6) Calculate and print the total number of days and the total number of deaths during the second golf in Belgium
-- We define the beginning (ending) of a golf 
-- when the 14 days moving average of positive_rate becomes >= (<) 0.06

/*
Start Golf 1: 07 Mar 2020
End Golf 1: 05 May 2020

Start Golf 2: 05 Oct 2020
End Golf 2: 14 Jan 2021

Number of days in Golf 1: 59
Number of days in Golf 2: 101

Number of deaths in Golf 1: 8016
Number of deaths in Golf 2: 10230
*/



-- Testcode
```
