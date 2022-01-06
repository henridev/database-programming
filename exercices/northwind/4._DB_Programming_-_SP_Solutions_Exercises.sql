/****************************/
/** Stored procedures      **/
/****************************/

/***************/
/** Exercises **/
/***************/

-- Exercise 1
-- In case a supplier goes bankrupt, we need to inform the customers on this
-- Write a SP that gives all information about the customers that ordered a product of this supplier during the last 6 months,
-- given the companyname of the supplier, so we will be able to inform the appropriate customers
-- First check if the companyname IS NOT NULL and if there is a supplier with this companyname
-- Then check if there isn't by chance more than 1 supplier with this companyname 
-- Use in the procedure '2018-10-21' instead of GETDATE(), otherwise the procedure won't return any records.
-- The procedure returns the number of found customers using an OUTPUT parameter

-- Write testcode 
-- (*) in which companyName IS NULL
-- (*) in which companyName does not exist
-- (*) in which companyName = Refrescos Americanas LTDA. 

CREATE OR ALTER PROCEDURE ContactCustomers (@companyName NVARCHAR(40), @numberOfInvolvedCustomers INT OUT) 
AS

IF @companyName IS NULL
BEGIN
	PRINT 'Please provide a CompanyName'
	RETURN
END

IF NOT EXISTS (SELECT NULL FROM Suppliers where CompanyName = @companyName)
BEGIN
	PRINT 'The supplier doesn''t exist.'
	RETURN
END

DECLARE @numberOfSuppliers INT  = (SELECT COUNT(SupplierID) FROM Suppliers WHERE CompanyName = @companyName)
IF @numberOfSuppliers > 1
BEGIN
	PRINT 'There is more than 1 supplier with the given name'
	RETURN
END



SELECT *
FROM Customers c JOIN Orders o ON c.CustomerID = o.CustomerID JOIN OrderDetails od ON od.OrderID = o.OrderID
JOIN Products p ON p.ProductID = od.ProductID JOIN Suppliers s ON s.SupplierID = p.SupplierID
WHERE DATEDIFF(MONTH,o.OrderDate,'2018-10-21') <= 6 AND s.companyName = @companyName

SET @numberOfInvolvedCustomers = @@ROWCOUNT


-- Testcode
DECLARE @numberOfInvolvedCustomers INT
EXEC ContactCustomers 'Refrescos Americanas LTDA', @numberOfInvolvedCustomers
PRINT 'The number of involved customers = ' + STR(@numberOfInvolvedCustomers)

-- Exercise 2
-- We'd like to have 1 stored procedure to insert new OrderDetails, however make sure that:

-- (*) the OrderID and ProductID exist;
-- (*) the UnitPrice is optional, use it when it's given else retrieve the product's price from the product table. 
-- If the difference between the given UnitPrice and the UnitPrice in the table Products is larger than 15%: write out a message and don't insert the new OrderDetail
-- (*) If the discount is smaller than 0.0 or larger than 0.25: write out a message and don't insert the new OrderDetail.
-- The discount is optional. If there is no value for discount => the discount is 0.0
-- (*) If the quantity is larger than 2 * the max ordered quantity of this product untill now: write out a message and don't insert the new OrderDetail

-- Write testcode in which you check all the special cases
-- Put everything in a transaction, so the original data in the tables isn't changed. You can see messages in the Messages tab
-- An example that should work: OrderID = 10249 + ProductID = 72 + UnitPrice = 35.00 + qauntity = 10 + discount = 0.15
-- OrderID = 10249 contains already 2 rows:
-- OrderID	ProductID	UnitPrice	Quantity	Discount
-- 10249	14			18,60		9			0
-- 10249	51			42,40		40			0



CREATE OR ALTER PROCEDURE InsertProduct (@orderID INT, @productID INT, @unitPrice Money = NULL, @quantity SMALLINT, @discount REAL = NULL)
AS

IF @OrderID IS NULL
BEGIN
	PRINT 'The orderID can''t be null'
	RETURN
END

IF @ProductID IS NULL
BEGIN
	PRINT 'The productID can''t be null'
	RETURN
END

IF NOT EXISTS (SELECT * FROM Orders where OrderID = @orderID)
BEGIN
	PRINT 'The orderID doesn''t exist.'
	RETURN
END

IF NOT EXISTS (SELECT * FROM Products where ProductID = @productID)
BEGIN
	PRINT 'The productID doesn''t exist.'
	RETURN
END

DECLARE @unitPriceProduct Money = (SELECT UnitPrice FROM Products WHERE productID = @productID)

IF @unitPrice IS NULL
	SET @unitPrice = @unitPriceProduct

IF (@unitPriceProduct * 0.85 > @unitPrice) OR (@unitPriceProduct * 1.15 < @unitPrice)
BEGIN
	PRINT 'The difference between the given UnitPrice and the UnitPrice in the table Products is larger than 15%'
	RETURN
END

IF @discount IS NULL
	SET @discount = 0

IF @discount < 0 OR @discount > 0.25
BEGIN
	PRINT 'The discount is < 0 OR > 0.25. This is not allowed.'
	RETURN
END

DECLARE @maxQuantity SMALLINT
SET @maxQuantity = (SELECT MAX(quantity) FROM OrderDetails WHERE ProductID = @productID)

IF @quantity > @maxQuantity
BEGIN
	PRINT 'The given quantity > 2 * the max ordered quantity of this product untill now. This is not allowed.'
	RETURN
END

INSERT INTO OrderDetails
VALUES (@orderID, @productID, @unitPrice, @quantity, @discount)

-- TestCode

BEGIN TRANSACTION

EXEC InsertProduct 10249, 172, 35, 10, 0.35

SELECT * FROM OrderDetails WHERE OrderID = 10249

ROLLBACK;

-- Exercise 3
-- Create a stored procedure for deleting a shipper. You can only delete a shipper if
-- (*) The shipperID exists
-- (*) There are no Orders for this shipper

-- Write two versions of your procedure:
-- (*) In the first version you check these conditions before deleting the shipper, 
-- so you don't rely on SQL Server messages. Generate an appropriate error message if the shipper can't be deleted. 
-- (*) In the second version you try to delete the shipper and catch the exceptions that might occur. 

-- Write testcode to delete shipper with shipperID = 10 (doesn't exist) / 5 (exists + no shippings) / 3 (exists + already shippings). 
-- Put everything in a transaction. Messages are visible on the Messages tab


CREATE PROCEDURE DeleteShipper1 @shipperID INT
AS

IF NOT EXISTS (SELECT NULL FROM Shippers WHERE ShipperID = @shipperID)
BEGIN
RAISERROR('The shipper doesn''t exist',14,0)
RETURN
END
IF EXISTS (SELECT * FROM Orders WHERE ShipVia = @shipperID)
BEGIN
RAISERROR('There are already shippings for this shipper',14,0)
RETURN
END
DELETE FROM Shippers WHERE ShipperId = @shipperID
PRINT 'Shipper ' + STR(@shipperID) + ' deleted'

BEGIN TRANSACTION

EXEC DeleteShipper1 5

SELECT * FROM Shippers

ROLLBACK;

CREATE PROCEDURE DeleteShipper2 @shipperID INT
AS

BEGIN TRY

DELETE FROM Shippers WHERE ShipperId = @shipperID

IF @@ROWCOUNT = 0
THROW 50000,'The shipper doesn''t exist',14
PRINT 'Shipper ' + STR(@shipperID) + ' deleted'
END TRY

BEGIN CATCH
IF ERROR_NUMBER() = 50000
	PRINT ERROR_MESSAGE()
ELSE IF ERROR_NUMBER() = 547 and ERROR_MESSAGE() like '%order%'
PRINT 'There are already shippings for this shipper. '
END CATCH

BEGIN TRANSACTION

EXEC DeleteShipper2 3

SELECT * FROM Shippers

ROLLBACK;

