# Stored procedures

```SQL
CREATE PROCEDURE myProc
	-- params
	@input VARCHAR(50),
	@output VARCHAR(50) OUTPUT
AS BEGIN
	-- code
	@input_param1
END
```

![procedural databse objects](https://res.cloudinary.com/dri8yyakb/image/upload/v1640880545/Untitled_Diagram.drawio_mlntlf.png)

SP = a named collection of SQL and control-of-flow commands (program) that is stored as a database object

- saved in the catalog under the procedures map under the schema or database
- analogous to methods, procedures, functions in other PL
- can be called by a program, trigger or other SP
- accepts in and out parameters
- returns status info on correct or incorrect execution
- contains a task to be executed

## Syntax

declare / set some variables :

```SQL
-- create a variable
DECLARE @variable_name1 data_type [, @variable_name2 data_type ...]
-- assign to variable according to ansi standard
SET @variable_name1 = expression
-- equivalent to SET but not ansi
-- can assign to multiple values at once
SELECT @variable_name1 = column_specification

DECLARE @maxQuantity SMALLINT, @maxUnitPrice SMALLINT, @minUnitPrice SMALLINT, 
SET @maxQuantity = (SELECT MAX(quantity) FROM orderDetails)
SELECT @maxQuantity = (SELECT MAX(quantity) FROM orderDetails)
SELECT @maxUnitPrice = MAX(UnitPrice), @minUnitPrice = MIN(UnitPrice)  FROM Products

-- result in tab message
PRINT 'max quantity is ' + STR(@maxQuantity)
-- result in tab result
SELECT 'max quantity is ' + STR(@maxQuantity)
```

operators :

- logical => AND, OR, NOT
- comparisson => <, >, =, IS NULL, LIKE, BETWEEN, IN
- alpha/numeric => +
- arithmic => -, +, %, /, *

create a procedure :

> syntax control: a SP will only be stored if it syntax is sound

```SQL
-- create db object via DDL instruction
CREATE PROCEDURE <proc_name> [parameter declaratie]
AS
<sql_statements>
```

alter a procedure :

```SQL
ALTER PROCEDURE <proc_name> [parameter_declaration]
AS
<sql_statements>
```

```SQL
ALTER PROCEDURE OrderSelectAll @customerId int
AS
SELECT * FROM orders
WHERE customerID = @customerID
```

remove a procedure :

```SQL
DROP PROCEDURE <proc_name>
```

executing procedures :

Execute a stored procedure or function  

```SQL
[ { EXEC | EXECUTE } ]  
    {   
      [ @return_status = ]  
      { module_name [ ;number ] | @module_name_var }   
        [ [ @parameter = ] { value   
                           | @variable [ OUTPUT ]   
                           | [ DEFAULT ]   
                           }  
        ]  
      [ ,...n ]  
      [ WITH <execute_option> [ ,...n ] ]  
    }  
[;]  
```

## Details

return values :

```SQL
CREATE PROCEDURE OrdersSelectAll AS
SELECT * FROM Orders
-- explicit return
RETURN @@ROWCOUNT
```

```SQL
DECLARE @numberOfOrders INT
EXEC @numberOfOrders = OrdersSelectAll
PRINT 'We have ' + STR(@numberOfOrders) + ' orders.'
```

we can only return a type `int` from the output otherwise you need to use a function

SP parameters :

```SQL
-- you can use a default input param like below too
-- CREATE PROCEDURE OrdersSelectAllForCustomer @customerID int = 5, @numberOfOrders int OUTPUT
CREATE PROCEDURE OrdersSelectAllForCustomer @customerID int, @numberOfOrders int OUTPUT
AS
SELECT @numberOfOrders = COUNT(*)
FROM orders
WHERE customerID = @customerID
```

and to call SP and retrieve output:

- provide the `OUTPUT` keyword
- pass a parameter:
  - possitional
  - via name

```SQL
DECLARE @nmbrOfOrders int
EXECUTE OrdersSelectAllForCustomer @customerID = 5, @nmbrOfOrders = @nmbrOfOrders OUTPUT 
PRINT @nmbrOfOrders
```

```SQL
DECLARE @nmbrOfOrders int
EXECUTE OrdersSelectAllForCustomer 5, @nmbrOfOrders OUTPUT 
PRINT @nmbrOfOrders
```

## Errors

- `RETURN` = immediate end of execution of batch procedure
- `@@error` = is 0 if OK else error number of last executed SQL instruction
- `RAISERROR(msg,severity,state)` = user defined or system error returned
  - msg = error message
  - severity = value between 0-18
  - state = value between 1-127 (distinguish between consecutive call with same message)
- `TRY ... CATCH`

simple example:

```SQL
CREATE PROCEDURE SomeProc 
  @name VARCHAR(50),
  @greeting VARCHAR(50) OUTPUT
AS
BEGIN
  IF @name <> 'Henri' BEGIN
	-- level (ernst) en state (zelfde error messages tussen verschillende procedures)
    RAISERROR('OEPS!!', 12, 1)
  END
  SET @greeting = 'HELLO MY FRIEND => ' + @name 
END
```

```SQL
---- main ----
DECLARE @output VARCHAR(60)
EXEC SomeProc @name = 'Henri', @greeting = @output OUTPUT 
PRINT @output
```

error handling with `@@error` and `RAISERROR`:

```SQL
CREATE PROCEDURE ProductInsert @productName nvarchar(50) = NULL, @categoryID = NULL AS 
DECLARE @error
INSERT INTO Products(ProductName, CategoryID, Discontinued) VALUES (@productName, @categoryID, 0)

-- save @error to avoid overwriting by consecutive statements

SET @errormsg = @@error

-- IF @errormsg = 0
--     PRINT 'SUCCESS the product ' + STR(@productName) + ' has been added.'
-- ELSE IF @errormsg = 515 -- what these errors are is defined inside sysmessages tabele
--     PRINT 'ERROR productname is NULL'
-- ELSE IF @errormsg = 547
--     PRINT 'ERROR category does not exist'
-- ELSE PRINT 'ERROR unable to add new prodect. ERROR' + STR(@errormsg)

IF @errormsg = 0
    PRINT 'SUCCESS the product ' + STR(@productName) + ' has been added.'
ELSE IF @errormsg = 515 -- what these errors are is defined inside sysmessages tabele
    RAISERROR('ERROR productname is NULL', 18, 1)
ELSE IF @errormsg = 547
    RAISERROR('ERROR category does not exist', 18, 1)
ELSE PRINT 'ERROR unable to add new prodect. ERROR' + STR(@errormsg)

RETURN @errormsg
```

```SQL
BEGIN TRANSACTION
    EXEC ProductInsert 'Wokkels', 10
    SELECT * FROM Products WHERE productName LIKE '%Wokkels%'
ROLLBACK;  
```

error location and descriptions:

```SQL
SELECT * FROM master.dbo.sysmessages
SELECT * FROM master.dbo.sysmessages WHERE error = @@ERROR
```

| error | severity | dlevel | description                                                                                                  | msglangid |
| ----- | -------- | ------ | ------------------------------------------------------------------------------------------------------------ | --------- |
| 21    | 20       | 0      | Warning: Fatal error %d occurred at %S_DATE. Note the error and time, and contact your system administrator. | 1033      |
| 101   | 15       | 0      | Query not allowed in Waitfor.                                                                                | 1033      |
| 102   | 15       | 0      | Incorrect syntax near '%.*ls'.                                                                               | 1033      |
| 103   | 15       | 0      | The %S_MSG that starts with '%.*ls' is too long. Maximum length is %d.                                       | 1033      |

exception handling:

5 functions to use in `catch` block

- `ERROR_LINE()` number of exception occurence
- `ERROR_MESSAGE()` error message
- `ERROR_PROCEDURE()` SP where exception occured
- `ERROR_NUMBER()` error number
- `ERROR_SEVERITY()` severity level

```SQL
CREATE PROCEDURE DeleteShipper @ShipperID int=NULL, @NumberOfDeletedShippers int OUT
AS
BEGIN
	BEGIN TRY
		DELETE FROM Shippers WHERE ShipperID = @ShipperID
		SET @NumberOfDeletedShippers = @@ROWCOUNT
	END TRY
	BEGIN CATCH
		PRINT 'Error Number = ' + STR(ERROR_NUMBER())
		PRINT 'Error Procedure = ' + ERROR_PROCEDURE()
		PRINT 'Error Message = ' + ERROR_MESSAGE()
	END CATCH
END
```

```SQL
BEGIN TRANSACTION
DECLARE @nrOfDeletedShippers int;
EXEC DeleteShipper 3, @nrOfDeletedShippers OUT
PRINT 'Number of deleted shippers ' + STR(@nrOfDeletedShippers)
ROLLBACK
```

```SQL
CREATE PROCEDURE DeleteShipper @ShipperID int=NULL, @NumberOfDeletedShippers int OUT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
		DELETE FROM Shippers WHERE ShipperID = @ShipperID
		SET @NumberOfDeletedShippers = @@ROWCOUNT
		COMMIT
	END TRY
	BEGIN CATCH
		ROLLBACK
		INSERT INTO log values(
			GETDATE(),
			ERROR_MESSAGE(),
			ERROR_NUMBER(),
			ERROR_PROCEDURE(),
			ERROR_LINE(),
			ERROR_SEVERITY()
		)
	END CATCH
END
```

the `THROW(error_number, msg, state)` statement

```SQL
THROW 
 [ 
   { error_number  | @local_variable },
   { message | @local_variable },
   { state | @local_variable }
 ] 
[ ; ]

RAISERROR ( 
	{ error_number | message | @local_variable }
    { ,severity ,state }
    [ ,argument [ ,...n ] ] 
	)
    [ WITH option [ ,...n ] ]
```

- better alternative to `RAISERROR(error_number | msg ,severity ,state)`
- raise exception + transfer execution to `TRY ... CATCH`
- error_number = int between 0 and 2147483647 representing the exception
- state = value between 1 and 127 distinguishing between consecutive calls with same message
- 2 options
  - with params: can be used outside catch block
  - without params: **only** in catch block => rethrows a caught exception

```SQL
CREATE PROCEDURE DeleteShipper @ShipperID int=NULL, @NumberOfDeletedShippers int OUT
AS
BEGIN
	BEGIN TRY
		DELETE FROM Shippers WHERE ShipperID = @ShipperID
		SET @NumberOfDeletedShippers = @@ROWCOUNT
	END TRY
	BEGIN CATCH
		PRINT 'weve got ourselves an error folks'
		THROW -- catch the exception to show it in messages
		-- OR
		THROW 5001, 'Shipper isn''t deleted' -- create a user defined error
	END CATCH
END
```

## other examples

other ways of preventing errors in the first place, setup some initial checks

```SQL
CREATE PROCEDURE DeleteShipper @ShipperID int=NULL, @NumberOfDeletedShippers int OUT
AS
BEGIN
	IF @ShipperID IS NULL
	BEGIN
		PRINT 'Please provide a shipperID'
		RETURN
	END
	IF NOT EXISTS (SELECT * FROM Shippers WHERE ShipperID = @ShipperID)
	BEGIN
		PRINT 'This shipper does not exist'
		RETURN
	END
	IF EXISTS (SELECT * FROM Orders WHERE ShipVia = @ShipperID)
	BEGIN
		PRINT 'The shipper has orders assigned to it and can''t be deleted'
		RETURN
	END

	DELETE FROM Shippers WHERE ShipperID = @ShipperID
	SET @NumberOfDeletedShippers = @@ROWCOUNT
END
```

insert via identity

```SQL
CREATE PROCEDURE InserShipper @CompanyName NVARCHAR(40), @phone NVARCHAR(40) = NULL, @shipperID INT OUT
AS
INSERT INTO Shippers(CompanyName, Phone)
VALUES (@CompanyName, @Phone)

SET @shipperID = @@identity
```

```SQL
BEGIN TRANSACTION
DECLARE @NewShipperID INT
EXEC InsertShipper 'Solid Shippings', '(503) 555-9874', @NewShipperID OUT
PRINT 'ID of inserted shipper: ' + STR(@NewShipperID)
ROLLBACK
```

## control flow

```SQL
CREATE PROCEDURE ShowFirstXEmployees @x INT, @missed INT OUTPUT
AS
DECLARE @empid INT, @fullname VARCHAR(100), @city NVARCHAR(30), @total INT

SET @empid = 1
SELECT @total = COUNT(*) FROM Employees
SET @missed = 10

IF @x > @total
    SELECT @x = COUNT(*) FROM Employees
ELSE 
    SET @missed = @total - @x

WHILE @empid <= @x
BEGIN
    SELECT @fullname = firstname + ' ' + lastname, @city = city 
    FROM Employees WHERE employeeid = @empid
    PRINT 'Full Name : ' + @fullname
    PRINT 'City : ' + @city
    PRINT '-------------------------'
    SET @empid = @empid + 1
END
```

```SQL
-- tester
DECLARE @numberOfMissedEmployees INT
SET @numberOfMissedEmployees = 0
EXEC showFirstXEmployees 5, @numberOfMissedEmployees OUT -- OUT has to be here
PRINT 'Number of missed employees: ' + STR(@numberOfMissedEmployees)
```
