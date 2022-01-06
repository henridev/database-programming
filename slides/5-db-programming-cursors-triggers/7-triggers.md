# Triggers

properties:

- db prgram with procedural and declarative instructions
- saved in catalogue
- similar to SP but no explicit calls
- activated by DBMS after certain operations and conditions
  - **DML triggers** `INSERT UPDATE DELETE` => our focus
  - DDL triggers `CREATE ALTER DROP`
  - LOGON LOGOFF triggers

dml triggers:

- activation
  - `before` before DML processed (not in SQL server but you can do after with rollback)
  - `instead of` instead of DML
  - `after` after DML processed (before commit) (default behaviour)
- some DBMS let you specify how many times cursor is activated
  - `for each row`
  - `for each statement`

## Procerdural DB objects

| Types       | saved as      | execution         | support parameters |
| ----------- | ------------- | ----------------- | ------------------ |
| **script**  | spearate file | client tool       | no                 |
| **sp**      | DB objects    | app or SQL script | yes                |
| **udf**     | DB objects    | app or SQL script | yes                |
| **trigger** | DB objects    | DML statement     | no                 |

## Use cases

- Validation of data and *complex* constraints
	– An employee can't be assigned to > 10 projects
	– An employee can only be assigned to a project that is assigned to his department
- Automatic generation of values
  - If an employee is assigned to a project the default value for the monthly bonus is set according to the project priority and his job category (calculated default value)
- Support for alerts
  - Send automatic e-mail if an employee is removed from a project
- Auditing
  - Keep track of who did what on a certain table
- Replication and controlled update of redundant data
  - If an ordersdetail record changes, update the orderamount in the orders table
  - Automatic update of datawarehouse tables for reporting (see "Datawarehousing")

## Pros

store functionality in DB (not in app development for example) and execute with each data change consistently.

- no redundant code (functionality localised in one spot)
- write + test once by dba
- security
- more processing power for DBMS and DB
- fits in to client server model (1 call = multiple executions)

## Cons

- complex
  - functionality shifted from app to db => db design + implementation more complex
  - difficult to debug
- hidden functionality
  - user can have unwanted side effects because of the trigger
  - trigger can possibly cascade (not easy to predict)
- performance
  - each db change has to re-evaluate trigger
- portability
  - restricted to db dialect

## comparisson

| Types                     | Oracle                                                 | SQL Server                                                                        | MySql                                                  |
| ------------------------- | ------------------------------------------------------ | --------------------------------------------------------------------------------- | ------------------------------------------------------ |
| **before** for validation | spearate file                                          | simulate with after + rollback                                                    | x                                                      |
| **after**                 | X                                                      | x                                                                                 | x                                                      |
| **instead of** for views  | X                                                      | x                                                                                 | n/a                                                    |
| **for each statement**    | X                                                      | default                                                                           | default                                                |
| **for each row**          | X                                                      | n/a                                                                               | x                                                      |
| for each row inf          | (acces to values before/afer per row via NEW/OLD vars) | (acces to values before/afer per row via deleted/inserted psuedo tables and rows) | (acces to values before/afer per row via NEW/OLD vars) |
| **transactions**          | NOT ALLOWED                                            | ALLOWED                                                                           | NOT ALLOWED                                            |

## virtual tables with triggers

2 types

- **deleted** table
  - during update or delete rows are moved from triggering table to deleted table
  - 2 tables have no rows in common
- **inserted** table
  - during update or insert rows are moved from triggering table to inserted table
  - all rows in inserted also in triggering

| Types      | INSERTED table        | DELTED table           |
| ---------- | --------------------- | ---------------------- |
| **insert** | has inserted row      | empty                  |
| **delete** | empty                 | has deleted rows       |
| **update** | has rows after update | has rows before update |

> with updates inserted will have new values while deleted will have old values

![image](https://res.cloudinary.com/dri8yyakb/image/upload/v1641191732/DFD6C9E3-917F-48EE-A87C-C2923B4FF05C_vvqqmw.png)

![img](https://res.cloudinary.com/dri8yyakb/image/upload/v1641192084/Untitled_Diagram.drawio_fkrivc.png)

## creating triggers

```SQL
CREATE TRIGGER triggerName
ON table
FOR [INSERT, UPDATE, DELETE]
AS ...
```

- authority: SysAdmin, dbo
- linked to 1 table not a view
- timing
  - after DUI operation
  - after copy changes to temporary deleted/inserted tables
  - before commit

## delete trigger

```SQL
CREATE OR ALTER TRIGGER deleteorderdetails 
ON orderdetails FOR DELETE 
AS

DECLARE @deletedProductID INT = (SELECT ProductID FROM deleted )
DECLARE @deletedQuantity INT = (SELECT Quantity FROM deleted)

UPDATE products
SET    unitsinstock = unitsinstock + @deletedQuantity
FROM   products
WHERE  productid = @deletedProductId
```

```SQL
BEGIN TRANSACTION
SELECT * FROM Products WHERE ProductID = 14 OR ProductID = 51
DELETE FROM OrderDetails WHERE OrderID = 10249
SELECT * FROM Products WHERE ProductID = 14 OR ProductID = 51
ROLLBACK

-- error because multiple results returned to var declaration => cursor needed
```

solution:

```SQL
CREATE OR ALTER TRIGGER deleteorderdetails ON orderdetails FOR DELETE 
AS
	DECLARE @deletedProductID INT, @deletedQuantity INT
	
	DECLARE cursor_delete CURSOR FOR
	  SELECT ProductID, Quantity
	  FROM deleted
	 
	OPEN cursor_delete
	FETCH NEXT FROM cursor_delete INTO @deletedProductID, @deletedQuantity
	
	WHILE @@FETCH_STATUS = 0
    BEGIN
    	PRINT "deleted " + @deletedProductID + " ==> " + @deletedQuantity
    	UPDATE Products
		SET    unitsinstock = unitsinstock + @deletedQuantity
		FROM   Products WHERE  productid = @deletedProductId
    	FETCH NEXT FROM cursor_city_country INTO @city_id, @city_name, @country_name;
    END

	CLOSE cursor_delete;
	DEALLOCATE cursor_delete;
```

## insert trigger

```SQL
-- If a new record is inserted in OrderDetails => check if the unitPrice is not too low or too high
CREATE OR ALTER TRIGGER insertOrderDetails ON OrderDetails FOR insert
AS
DECLARE @insertedProductID INT = (SELECT ProductID From inserted)
DECLARE @insertedUnitPrice Money = (SELECT UnitPrice From inserted)
DECLARE @unitPriceFromProducts Money = (SELECT UnitPrice FROM Products WHERE ProductID = @insertedProductID)
IF @insertedUnitPrice NOT BETWEEN @unitPriceFromProducts * 0.85 AND @unitPriceFromProducts * 1.15
BEGIN
ROLLBACK TRANSACTION
RAISERROR ('The inserted unit price can''t be correct', 14,1)
END
```

```SQL
BEGIN TRANSACTION
INSERT INTO OrderDetails
VALUES (10249, 72, 60.00, 10, 0.15)
SELECT * FROM OrderDetails WHERE OrderID = 10249
ROLLBACK
```

> when triggering by INSERT-SELECT statement more than one record can be added at once. The trigger code is executed only once

## update after

```SQL
CREATE OR ALTER TRIGGER insertOrderDetails ON orderdetails FOR update -- only thing that changes 
AS
  DECLARE @deletedProductID INT, @deletedQuantity INT
  DECLARE @deletedProductID INT, @deletedQuantity INT
  DECLARE @deletedProductID INT, @deletedQuantity INT
  IF @insertedUnitPrice NOT BETWEEN @unitPriceFromProducts * 0.85 AND @unitPriceFromProducts * 1.15
  BEGIN
    -- simulate before
    ROLLBACK TRANSACTION
    RAISERROR ('inserted unit price can''t be corrected', 14, 1)
  END
```

```SQL
BEGIN TRANSACTION
UPDATE OrderDetails SET UnitPrice = 60 WHERE OrderId = 10249 AND ProductId = 14
SELECT * FROM OrderDetails WHERE OrderId = 10249
ROLLBACK
```

## if update clase

conditional execution of triggers => only if specific column is mentioned in update or insert

```SQL
CREATE OR ALTER TRIGGER updateOrderDetails ON OrderDetails FOR update
AS
-- If a record is updated in OrderDetails => check if the new unitPrice is not too low or too high
-- If so, rollback the transaction and raise an error
IF update(unitPrice)
  BEGIN
    DECLARE @updatedProductID INT = (SELECT ProductID From inserted)
    DECLARE @updatedUnitPrice Money = (SELECT UnitPrice From inserted)
    DECLARE @unitPriceFromProducts Money = (
      SELECT UnitPrice FROM Products WHERE ProductID = @updatedProductID
    )
    IF @updatedUnitPrice NOT BETWEEN @unitPriceFromProducts * 0.85 AND @unitPriceFromProducts * 1.15
    BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('The updated unit price can''t be correct', 14,1)
    END
  END
-- If a record is updated in OrderDetails => check if the new discount is not too low or too high
-- If so, rollback the transaction and raise an error
IF update(Discount)
BEGIN
  DECLARE @updatedDiscount REAL = (SELECT Discount FROM inserted)
  IF @updatedDiscount NOT BETWEEN 0 AND 0.25
  BEGIN
    ROLLBACK TRANSACTION
    RAISERROR ('The updated discount can''t be correct', 14,1)
  END
END
```

## triggers and transactions

- trigger => part of same transaction as triggering instruction
- triggering instruction => can be rolled back inside the trigger
- trigger => happens after triggering instruction but the triggering instruction can still be undone in the trigger

## 1 trigger for insert and/or update and/or delete

> if needed you can still distinguish inside the trigger like below

```SQL
IF NOT EXISTS (SELECT * FROM deleted)
BEGIN
--
END
IF NOT EXISTS (SELECT * FROM inserted)
BEGIN
--
END
```

> sometimes it's not necessary to distuingsh like below

```SQL
-- If a record is inserted or updated in OrderDetails 
-- => check if the new unitPrice is not too low or too high
-- If so, rollback the transaction and raise an error
CREATE OR ALTER TRIGGER updateOrInsertOrderDetails ON OrderDetails FOR update, insert
AS
DECLARE @updatedProductID INT = (SELECT ProductID From inserted)
DECLARE @updatedUnitPrice Money = (SELECT UnitPrice From inserted)
DECLARE @unitPriceFromProducts Money = (
  SELECT UnitPrice FROM Products WHERE ProductID = @updatedProductID
)
IF @updatedProductID NOT BETWEEN @unitPriceFromProducts * 0.85 AND @unitPriceFromProducts * 1.15
BEGIN
	ROLLBACK TRANSACTION
  RAISERROR ('The unit price can''t be correct', 14,1)
END
```

## drop a trigger

is done via DDL (CREATE/ALTER/DROP)

`DROP TRIGGER <trigger_name>`

## remarks

In addition to differences in syntax, the SQL products also differ in the functionality of triggers. Some interesting questions are:

- Can multiple triggers be defined for a single table and a specific transaction? Sequence problems that can affect the result
- Can processing a statement belonging to a trigger action trigger another trigger?One mutation in an application can lead to a waterfall of mutations, recursion
- When exactly is a trigger action processed? Immediately after the change or before the commit statement
- Can triggers be defined on catalog tables?

## exercices

```SQL
-- Exercise 1
-- Create a trigger that, when adding a new employee, sets the reportsTo attribute 
-- to the employee to whom the least number of employees already report.
-- Testcode


CREATE OR ALTER TRIGGER insertEmployee ON Employees FOR insert
AS
BEGIN
	DECLARE @insertedEmployeeID INT = (SELECT EmployeeID From inserted)
	
	DECLARE @leastReportedTo INT = (
		SELECT TOP 1 ReportsTo FROM (
			SELECT ReportsTo, COUNT(*) as supervision_count FROM Employees e  WHERE ReportsTo IS NOT NULL GROUP BY ReportsTo 
		) AS supervisors 
		ORDER BY supervision_count ASC
	)
	 
    UPDATE Employees 
    SET ReportsTo = @leastReportedTo 
    FROM Employees 
    WHERE EmployeeID = @insertedEmployeeID
END

BEGIN TRANSACTION
INSERT INTO Employees(LastName,FirstName)
VALUES ('New','Emplo');
SELECT EmployeeID, LastName, FirstName, ReportsTo
FROM Employees
ROLLBACK


-- Exercise 2
/* 
Create a new table called ProductsAudit with the following columns:
AuditID --> Primary Key + Identity
UserName --> NVARCHAR(128) + Default value = SystemUser
CreatedAt --> DateTime + Default value = UTC Time
Operation --> NVARCHAR(10): The name of the operation we performed on a row (Updated, Created, Deleted)
If the table is already present, drop it.
Create a trigger for all actions (Update, Delete, Insert) to persist the mutation of the Products table.
Use system functions to populate the UserName and CreatedAt.
*/

-- Drop the objects created in this code (easier to re-run)
DROP TABLE ProductAudit
DROP TRIGGER TR_Product_AuditProducts
GO

-- Create the audit table
CREATE TABLE ProductAudit(
    Id INT NOT NULL PRIMARY KEY IDENTITY,
    UserName NVARCHAR(256) DEFAULT SUSER_SNAME(),
    CreatedAt DATETIME DEFAULT getutcdate(),
    Operation NCHAR(6))
GO

-- Create the trigger
CREATE TRIGGER TR_Product_AuditProducts
on Products
FOR INSERT, UPDATE, DELETE
AS

-- Get the text representation of the action that happned
DECLARE @operation NCHAR(6)
IF NOT EXISTS (SELECT NULL FROM inserted)
    SET @operation = 'delete'
ELSE IF NOT EXISTS (select NULL from deleted)
        SET @operation = 'insert'
     ELSE SET @operation = 'update'
    
-- Add a new record in the audit table.
INSERT INTO ProductAudit(operation)
VALUES (@operation)
GO

-- TestCode
BEGIN TRANSACTION
DECLARE @productId INT;
SET @productId = 100;
INSERT INTO Products(ProductName, Discontinued) VALUES('New product100', 0)
UPDATE Products SET productName = 'abc' WHERE ProductID = @productId
DELETE FROM Products WHERE ProductID = @productId
SELECT * FROM ProductAudit -- Changes should be seen here.
ROLLBACK
```
