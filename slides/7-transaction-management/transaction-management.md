# Transaction-management

- transactions (management)
- recovery
- concurrency control
- ACID properties of transactions



## transactions / recovery / concurrency control

### context

- most DBs are multi-user
- if data is accessed concurrently => possible anomalies
- errors my arise in DBMS or it's environment
- DBMS must support **ACID** 
  - atomic => non divisible
  - consistent
  - isolated => multiple users need to be able to work isolated form each other
  - durable => transactions that are committed are permanent

### transactions

> **transaction** = collection of DB statements:
>
> 1. induced by a single user or application
> 2. that should be considered as an indivisible unit of work (eg. transfer of money between 2 accounts)

-  a transaction is *indivisible / atomic* so it fails or succeeds in its entirety
- a transaction is *consistent* it takes the db from state X to state Y

### recovery / concurrency control

- **recovery** = ensuring that given problems the database is returned to a *consistent* state without any data loss afterwards
- **concurrency control** = coordination of concurrently executed transactions working on the same data to avoid *inconsistency* in data because of mutual interference
- examples: hard disk failure, application/DBMS crash, division by 0, ...

## transaction (management)

### Delineating Transactions and the Transaction Lifecycle

2 types of transaction delineation:

- explicitly => Dev decides when transaction starts and stops or how steps are rolled back to handle faulty situations
- implicitly => first executable sql statement



- ACTIVATION of transaction => once first operation is executed
- COMMIT of transaction => all operations completed successfully
- ROLLEDBACK of transaction => one operation failed

### SP and transactions

```sql
-- explicit transaction example

CREATE PROCEDURE sp_Customer_Insert @customerid varchar(5), @companyname varchar(25), @orderid int OUTPUT
AS
BEGIN TRANSACTION
	INSERT INTO customers(customerid, companyname) VALUES(@customerid, @companyname)
	IF @@error <> 0 
	BEGIN
		ROLLBACK TRANSACTION
		RETURN -1    
	END
	
	INSERT INTO orders(customerid) VALUES(@customerid)
	IF @@error <> 0 
	BEGIN
		ROLLBACK TRANSACTION
		RETURN -1    
	END
COMMIT TRANSACTION

SELECT @orderid = @@IDENTITY
```

### Triggers and transactions

> the trigger itself and the instructions attached to it belong to one *atomic* transaction 
>
> the atomic transaction can be rolled-back inside the trigger

```sql
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

### DBMS components used in transaction management

![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641478283/B4D498BF-64E9-4002-B0F5-D98FF69894F3_pyhunq.png)



```
1: n transactions are demanded => each contains multiple actions (statements)
2: the sheduler has to decide when which transaction takes place (eg => S1_T1 -> S1_T2 -> S2_T2 -> S2_T1 -> S3_T1)
```



### logfiles

## recovery

## concurrency control

## ACID