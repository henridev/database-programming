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
1:  n transactions are demanded => each contains multiple actions (statements)
2:  the sheduler has to decide when which transaction takes place (eg => S1_T1 -> S1_T2 -> S2_T2 -> S2_T1 -> S3_T1)
3: 
	transaction gets started => stored datamanager is responsible for physical storage of the data
	instead of performing operations on files it performs them in memory which is way faster => this memory used is the 	buffer manager => the allocation from the buffer manager to the actual database is called flushing
4:  transactions can be OK or NOT OK
4a: if the transaction is successfull a commit is performed this will make the datamanager flush
4b: if transaction is unsuccessfel we need to abort and rollback to reset things to the initial state the recovery manager is used
```



### logfiles

> are responsible for ensuring that rollbacks are possible. without it we can never restore an earlier state

it registers the following

- **log sequence number**
- **tid = transaction id**
- start time of transaction
- indication of operation type => read/write
- Log modifications are logged in two ways: as **LOP_MODIFY_ROW** or **LOP_MODIFY_COLUMNS **record. (these include images which signify the bytes changed)
  - **before images** => all records that participated in the transaction 
  - **after images** => all records that were changed by the transaction
- current transaction state => active / committed / aborted
- **checkpoints** in logfiles = moment at which buffers in temporary memory are released and flushed to the disk
- **write ahead log strategy**
  - def. updates have to be registered in the logfile before written to disk
  - **before images** are recorded in the logfile prior to values being overwritten in database files



<img src="https://res.cloudinary.com/dri8yyakb/image/upload/v1641485109/A50BB2B1-43B4-42E5-B628-E1B68668FE7D_luwvzs.png" style="zoom:67%;" />

#### inside the transaction log files

[docs](https://blog.coeo.com/inside-the-transaction-log-file)

[docs-before-after-image](https://codingsight.com/dive-into-sql-server-transaction-log-part-3/)

##### example

```sql
-- excute this small transaction
-- which gets auto aborted

BEGIN TRANSACTION
DECLARE @startMessage varchar(200) = 'Transaction started at ' + CONVERT(varchar, SYSDATETIME(), 121)
RAISERROR(@startMessage,0,0) WITH NOWAIT

SELECT EmpName, EmpSalary
FROM dbo.TestIsolationLevels
WHERE EmpID = 2900;

UPDATE  dbo.TestIsolationLevels 
SET     EmpSalary = 25000
WHERE   EmpID = 2900

RAISERROR('Update happened, waiting 5 seconds to ROLLBACK',0,0) WITH NOWAIT
WAITFOR DELAY '00:00:05'
ROLLBACK;
DECLARE @endMessage varchar(200) = 'Rollback happened at ' + CONVERT(varchar, SYSDATETIME(), 121)
RAISERROR(@endMessage,0,0) WITH NOWAIT

-- get transaction info of the latest started transactions
SELECT 
	[Current LSN], 
	[Transaction ID], 
	[Transaction name]
	[Database Name],
	[AllocUnitName],
	[Page ID],
    Operation, 
    Context, 
    TRY_CONVERT(DATETIME,[Begin time]) as 'beginTime',
    TRY_CONVERT(DATETIME,[End time]) as 'endTime'
FROM sys.fn_dblog(NULL, NULL)
ORDER BY TRY_CONVERT(DATETIME,[Begin time]) DESC

-- use transaction id of the latest started transaction to find logs for our transaction
SELECT 
	[Current LSN], 
	[Transaction ID], 
	[Transaction name]
	[Database Name],
	[Page ID],
    Operation, 
    Context, 
    TRY_CONVERT(DATETIME,[Begin time]) as 'beginTime',
    TRY_CONVERT(DATETIME,[End time]) as 'endTime'
FROM sys.fn_dblog(NULL, NULL)
WHERE [Transaction ID] = '0000:0000038b'
ORDER BY TRY_CONVERT(DATETIME,[Begin time]) DESC

-- See all operations and their size
SELECT
[Operation],
count(*) AS [No of Records],
SUM([Log Record Length]/1024.00/1024.00) AS [RecordSize (MB)]
FROM fn_dblog(NULL,NULL)
GROUP BY Operation
ORDER BY [RecordSize (MB)] DESC
```

result below

---

| Current LSN            | Transaction ID | Database Name    | Page ID       | Operation      | Context       | beginTime               | endTime                 |
| ---------------------- | -------------- | ---------------- | ------------- | -------------- | ------------- | ----------------------- | ----------------------- |
| 00000025:00000198:0005 | 0000:0000038b  | user_transaction |               | LOP_BEGIN_XACT | LCX_NULL      | 2022-01-06 16:21:52.350 |                         |
| 00000025:00000198:0006 | 0000:0000038b  |                  | 0001:000000f0 | LOP_MODIFY_ROW | LCX_CLUSTERED |                         |                         |
| 00000025:00000198:0007 | 0000:0000038b  |                  | 0001:000000f0 | LOP_MODIFY_ROW | LCX_CLUSTERED |                         |                         |
| 00000025:00000198:0008 | 0000:0000038b  |                  |               | LOP_ABORT_XACT | LCX_NULL      |                         | 2022-01-06 16:21:57.360 |

##### columns

| Column                | Description                                                  |
| --------------------- | ------------------------------------------------------------ |
| Current LSN           | Current Log Sequence Number                                  |
| Previous LSN          | Previous Log Sequence Number                                 |
| Operation             | Describes the operations performed                           |
| Context               | Context of the operation                                     |
| Transaction ID        | ID of the transaction in the LOG file                        |
| Log Record Length     | Size of the row in bytes                                     |
| AllocUnitName         | Object name (table or index) against which the operation was performed |
| Page ID               | Table/Index Page ID                                          |
| SPID                  | User Session ID                                              |
| Xact ID               | User Transaction ID - logged only in the LOP_BEGIN_XACT and LOP_COMMIT_XACT rows |
| Begin Time            | Transaction Start time - logged only in the LOP_BEGIN_XACT record |
| End Time              | End Time - logged only in the LOP_COMMIT_XACT record         |
| Transaction Name      | Typically refers to the type of transaction: INSERT for example - logged only in the LOP_BEGIN_XACT: record |
| Transaction SID       | User Security identifier                                     |
| Parent Transaction ID | If is a child transaction, will contain the ID of its parent transaction |
| Transaction Begin     | The first LSN of the transaction                             |
| Number of Locks       | Number of locks                                              |
| Lock Information      | Description of the lock                                      |
| Description           | Transaction LOG row description                              |
| Log Record            | The hexadecimal content of the transaction, an inserted/deleted row or the content of a page i.e. |

##### operations in logfile

| Operation           | Description       |
| ------------------- | ----------------- |
| LOP_BEGIN__XACT     | Begin Transaction |
| LOP_COMMIT__XACT    | End Transaction   |
| OP_FORMAT_PAGE      | Page Modified     |
| LOP_INSERT__ROWS    | Row inserted      |
| LOP_DELETE_ROWS     | Row deleted       |
| LOP_LOCK_XACT       | Lock              |
| LOP_MODIFY_ROW      | Row Modified      |
| LOP_MODIFY__COLUMNS | Column Modified   |
| LOP_XACT_CKPT       | Checkpoint        |
| LOP_BEGIN__CKPT     | Checkpoint start  |
| LOP_END_CKPT        | Checkpoint end    |
| LOP_MARK__SAVEPOINT | Save point        |

## recovery

### types of failures

- **Transaction failure** => error in the logic driving the transaction’s operations and/or in the app logic
- **System failure** => the OS or the database system crashes
- **Media failure** =>  the secondary storage is  damaged or inaccessible

### system recovery

- 2 types of transactions in light of system failure
  - transactions committed before failure
  - transactions in active statE
- **logfile** remains essential in handling the failure
  - it knows which transactions updated what and when via **before/after images**
  - via this info it can either **REDO** or **UNDO** a transaction 
- **buffer flushing strategy** => impacts undo or redo usage



![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641491306/872ED369-E370-4392-B078-19F4DEC2BF28_mnjif9.png)

<img src="https://res.cloudinary.com/dri8yyakb/image/upload/v1641492608/Untitled_Diagram.drawio_hmt0bd.png" style="zoom:65%;" />

> **checkpoint** = last moment buffer manager transferred permanently to disk
>
> - T1 result was flushed before the checkpoint + commit happened already before failure => nothing
> - T2 result was not fully flushed + commit happened before the failure => a piece of work that was committed but not flushed => REDO based on after images in the log
> - T3 result not flushed but a part of the work was + no commit before failure => UNDO the part of the work that happened before the checkpoint
> - T4 result was not flushed + commit happened before the failure => REDO via **after images**
> - T5 result not flushed no work before the checkpoint => nothing



### media recovery

- requires some form of **redundancy**
- trade-off => cost of redundancy <> time to restore
- 2 types
  - **disk mirroring**
    - +- real time writing data to two disks
    - limits failover time but often costlier than archiving
    - con small impact on write performance
    - pro opportunity for parallel read access
  -  **archiving**
    - periodical copying to other medium
    - trade-off => cost of frequent backups <> cost of lost data
    - full backup => full system
    - incremental backup => only modifications
  - mixed => **rollforward recovery**
    - database files are archived
    - logfiles are mirrored
    - data can be complemented with (a redo of) the more recent transactions as recorded in the logfile

> Note: NoSQL databases allow for temporary  inconsistency, in return for increased performance  (eventual *consistency*)

## concurrency control

- **scheduler** is responsible for handling concurrency control aka planning when transactions and their operations are executed
- concurrency problems arise with data altering not with reading alone
- most error free approach would be to execute the transactions fully **sequential**
- a scheduler will not plan execution sequentially but will **interleave** transaction operations
-  possible problems
  - **lost update problem**
  - **uncommitted dependency / dirty read problem** 
  - **inconsistent analysis problem**

### typical concurrency problems (recognize / give example / explain)

#### lost update

> an update written by transaction x is not taken into account by transaction y thus overwriting the update performed in y

![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641494164/76B508F0-9783-41C0-90CF-C387DD64C901_vvypj2.png)

#### dirty read / uncommitted dependency

> transaction x updates a record in the meantime transaction y reads in that updated record at the moment it changes the record however y is rolled back. in this case transaction x will hold on to the value it read in earlier and not take into consideration the rollback performed before  
>
> t1 will use uncommitted modifications of t2 that will later be rolled back

![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641494186/673F576A-D835-4B60-B8E8-ECB63063C1F4_a9d5kc.png)

#### inconsistent analysis

> denotes a situation where a transaction reads partial results of another transaction that simultaneously interacts with (and updates) the same data items.
>
> we have to wait to read in amount_z and amount_x until after the commit in T1

![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641494237/76C9A1E6-AB90-4FD9-802F-7FC4AD83A038_sxjfu2.png)

#### other problems

- **non/unrepeatable read** occurs when a transaction T1 reads the same row multiple times, but  obtains different subsequent values, because another  transaction T2 updated this row in the meantime
- **phantom reads** can occur when a transaction T2 is executing insert or delete operations on a set of rows  that are being read by a transaction T1

![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641495438/81BE6543-3F37-47F2-AE92-1C7740052E58_e7s7ts.png)

### schedules and serial schedules

#### sequential ordering



**schedule** = set of n **transactions**, and a **sequential ordering** over the statements of these transactions, following property 1.



property 1: S preserves the ordering of the individual statements *within* each T but allows an arbitrary ordering of statements *between* T
$$
\text{each transaction T that participates in a schedule S} \\
\text{and for all statements } s_i \text{ and } s_j \text{ that belong to the same transaction T:} \\
\text{if statement } s_i \text{ precedes statement } s_j \text{in T} \\
\text{then } s_i \text{  is scheduled to be executed before } s_j \text{ in } S 
\\ 
\\
[(T_1(s_1,s_2,s_3), T_1(s_1,s_2,s_3)]\in S \\
ok \rightarrow S =T1{s_{1}}, T2{s_{1}}, T2{s_{2}}, T2{s_{3}}, T1{s_{2}}, T1{s_{3}} \\
nok \rightarrow S =T1{s_{1}}, T2{s_{1}}, T2{s_{2}}, T1{s_{3}}, T1{s_{2}}, T2{s_{3}}
$$

#### serial schedule

> all statement Oi of T are scheduled consecutively within S => NO RISK OF PARALLEL TRANSACTION EXECUTION (only if things are non serial do we need a correct schedule to prevent concurrency problems)

#### serializable S

> a **non-serial** S which is equivalent to a **serial** schedule in terms of outcome

- in behaviour it is equivalent to a serial schedule
- only if things are **non-serial** do we need a **correct schedule** to prevent concurrency problems => follow a correct schedule but be non-serial 

$$
\text{schedules } S_1 \text{ and } S_2  \text{ are equivalent if} \\
$$

![serializable properties](https://res.cloudinary.com/dri8yyakb/image/upload/v1641533233/Drawing_2_xj0ecq.png)

##### testing serializability

draw a **precedence graph** with rules:

-  each Ti gets a node
- create a directed edge Ti=>Tj 
  - if Tj reads a value after it was written by Ti
  - if Tj writes a value after it was read by Ti
  - if Tj writes a value after it was written by Ti
- If precedence graph contains a **cycle**, the schedule is not  serializable. 

![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641533919/Drawing.sketchpad_y1mbik.png)



### optimistic and pessimistic schedulers

a scheduler is responsible for applying a scheduling protocol

- optimistic protocol

  - assume that transaction conflicts are exceptional

  - transactions get scheduled without any delay

  - just before a **commit** a check for conflicts gets done => if there is a conflict **rollback** 

  - **locking** used to detect conflict during transaction execution

    

- pessimistic protocol (eg serial scheduler)

  - assume that transaction conflicts are common
  - transactions get scheduled with delay until the scheduler can find a moment so that the chance of conflict is minimum
  - **throughput** will be reduced lightly 
  - **locking** is used to limit simultaneity of transaction execution 

- both protocols will use **locking** to prevent transaction conflict 

- both protocols will use **timestamping** to prevent transaction conflict 

  - Read/Write timestamps are associated with database objects
  - enforces that a set of transaction operations is executed in correct order



### locking and locking protocols

#### Purposes of Locking

> **prevent conflict** => when multiple **concurrent** transactions try accessing the same **database object** access will only be granted so that no conflict can occur

- **lock** = variable associated to **database object** where it's value*** constrains the type of operations that are permitted on the object at that time
- **lock manager** = part of DBMS responsible for **locking** and **unlocking**
  - implements certain **locking protocol** => set of rules that determines which locks can be granted when (**lock compatibility**)
  - uses a **lock table** => stores which lock are held by which transactions and which transactions are waiting to get a lock
  - has to ensure **fairness** of scheduling (eg avoid starvation)
- 2 types of locks***:
  - **exclusive lock / x-lock / write lock** => 1 transaction has sole privilege to interact with database object at that time
    - no other transactions allowed R/W
    - no other lock can be held on this database object
  - **shared lock / s-lock / read lock** => no other transaction can update the same object during this lock
    - other transactions may hold a shared lock on that same object as  well, however they are only allowed to read it
    - other shared locks can be held on this database object (not exclusive lacksSS)

###### lock compatibility

> if a transaction needs to update a database object an x-lock is needed which only will be available if no other lock rests upon a database object 

![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641538088/Screenshot_2022-01-07_074753_pxbcpw.png)

#### Two-Phase Locking Protocol (2PL)

takes into account following principles:

- if a transaction wants to `READ` or `UPDATE` a database object a **Shared** or **Exclusive** lock needs to be given to it
- lock allocation happens based on **compatibility matrix**
- **Locking** and **Unlocking** happens in 2 phases:
  - **growth phase** = locks can be requested/acquired not released
  - **shrink phase** = locks are slowly released not requested/acquired

##### 2 types of 2PL

- **rigorous** => all locks held till commit
- **static / conservative** =>  all locks requested at start (skips growth phase)

![2PL](https://res.cloudinary.com/dri8yyakb/image/upload/v1641549569/03BA55F4-29D8-47A7-A9BA-CECA2F164AC5_udl2hu.png)

> **lost update problem** with locking



![lost update problem with locking](https://res.cloudinary.com/dri8yyakb/image/upload/v1641549685/D4EE3A5E-A30E-4122-9A1C-F6EB3668ED4F_wfwvl4.png)

> **uncommitted dependency** with locking

![uncommitted dependency with locking](https://res.cloudinary.com/dri8yyakb/image/upload/v1641549763/822A3363-668E-4F2F-8A08-CF408E782E83_a8mwwc.png)

#### Cascading Rollbacks

> the **uncommitted dependency problem** is fixed by holding the lock until after the rollback => with 2PL protocol however a lock can be released before transaction commits or aborts (**shrink phase**)

- if T1 needs to be committed the DBMS should first ensure that all transactions that made changes applied to data items that were subsequently read by T1 are committed first 
- if T2 needs to be rolled back the transactions Tu that read values written by T2 need to be rolled back too (if it commits there are no problems)
- CASCADE: All transactions that have in their turn read values written by the transactions Tu need to be rolled back as well, and so forth
  - should be applied **recursively**
  - can be **time-consuming**
  - best to avoid by using **rigorous 2PL** => release lock after commit => slower throughput but less error prone

![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641550800/Drawing-1.sketchpad_frp6qm.png)

#### Dealing with Deadlocks

**deadlock** = 2 or more Ts are waiting for each others locks to be released



![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641551275/01AC54AA-2F6E-4895-9F58-462DB03E1C9A_zhjccl.png)

3 important questions:

- prevent deadlocks => **static 2PL** all locks are acquired at the start (will slow down throughput)

- detect deadlocks

  - **wait for graph** consisting of **nodes** representing active transactions  and **directed edges** Ti => Tj for each transaction Ti that is waiting to acquire a lock currently held by transaction Tj
  - deadlock exists if the wait for graph contains a cycle

- resolve deadlocks

  - **victim selection** => make one of transactions victim to rollback so that the other can continue

  

#### Isolation Levels

- in 2PL (static vs rigorous) => trade-off between less errors <=> higher throughput
- limited interference between transactions can be positive for throughput
- **long term lock** = granted and released following protocol held longer until after commit (rigorous)
- **short term lock** = lock only held for time necessary to complete operation
  - violates 2PL rule (locking and unlocking happens in growth and shrink phase)
  - can improve throughput

**isolation level** = setting a session or query level

- **Reader**: reads data using a **s-lock** (`SELECT`)
  - can be influenced in SQL Server with respect to the locks they claim and the duration of these locks. 
  - can be influenced explicitly Using **isolation levels**
    - can be set on either **session** or **query level** ***
  - this can implicitly influence writer behaviour
- **Writer**: writes data, using an **x-lock**  (`INSERT, UPDATE, DELETE`)
  - can't be influenced in SQL Server with respect to  the locks they claim and the duration of these locks. 
  - They always claim an exclusive lock.

4 possible levels: 

- **Read uncommitted** 
  - **Long-term** locks are *not* taken into account
  - READ does not ask for shared lock => READ never conflicts with WRITE
  - READ reads uncommitted data => risk for **dirty read / uncommitted dependency**
  - assumption is => concurrency conflicts do not occur or their impact on the transactions with this isolation level are not problematic.  
  - typically only allowed for read-only transactions, which do not perform updates anyway. 
- **Read committed** 
  - **default**
  - READ claims shared lock => WRITER has to wait
  - READ reads committed data only
  - uses **long-term write locks**, but **short-term read locks**.  
    - In this way, a transaction is guaranteed not to read any data that are still being updated by a yet uncommitted transaction.  
    - **short term read locks** => means that lock is released when data is obtained (end of `SELECT`) not at the end of a transaction
      - reading same data again in same transaction can give different result =  **nonrepeatable reads / inconsistent analysis** 
  - This resolves the **lost update** as well as the **dirty read / uncommitted dependency** problem. 
  -  inconsistent analysis problem may still occur with this isolation level, as well as **nonrepeatable reads / inconsistent analysis** and **phantom reads**
- **Repeatable read** 
  - uses both **long-term read - and write locks**.  
    - long term read lock means it is held until the end of the transaction
    - READ and transaction needs to be committed before **x-lock**
  - Thus, a transaction can read the same row repeatedly, without interference from  insert, update or delete operations by other transactions, fixing the **inconsistent analysis problem**. 
  - the problem of **phantom reads** remains unresolved with this isolation level.
- **Serializable**
  - corresponds roughly to an implementation of **2PL**. 
  - **phantom reads**
    - Repeatable read only locks rows found with first SELECT 
    - Same SELECT in same transaction can give new row  (added by other transactions) = phantoms
    - Locks all keys (current and future) that correspond to WHERE-clause
  - in practice, the definition of **serializability** in the context of isolation levels merely comes down to the absence of concurrency problems, such as  nonrepeatable reads and phantom reads.

##### prevented errors

| Isolation level  | Lost update | Uncommitted dependency | Inconsistent analysis | Nonrepeatable read | Phantom read |
| ---------------- | ----------- | ---------------------- | --------------------- | ------------------ | ------------ |
| Read uncommitted | Yes         | Yes                    | Yes                   | Yes                | Yes          |
| Read committed   | No          | No                     | Yes                   | Yes                | Yes          |
| Repeatable read  | No          | No                     | No                    | No                 | Yes          |
| Serializable     | No          | No                     | No                    | No                 | No           |

##### properties

| Isolation level  | locks                             | lock duration | consistency | concurrency |
| ---------------- | --------------------------------- | ------------- | ----------- | ----------- |
| Read uncommitted | not taken into account            | shortest      | least       | most        |
| Read committed   | long term read / short term write |               |             |             |
| Repeatable read  | long term read / write lock       |               |             |             |
| Serializable     | static 2PL                        | longest       | most        | least       |



! Ex: know this table by hard

 

##### override isolation levels

```sql
-- with "table hint"
SELECT * FROM ORDERS WITH (READUNCOMMITTED); -- overwrites session isolation
-- or
SELECT * FROM ORDERS WITH (NOLOCK);

-- This avoids that long running queries on a production system lock updates in other transactions in case of READ COMMITTED and higher
```

#### Lock Granularity

- Database object for locking can be a tuple, a column, a table, a tablespace, a disk block, etc. => from high to low granularity
- Trade-off between **locking overhead** and **transaction throughput**
- Many DBMSs provide the option to have the optimal **granularity level** determined by the database system



## ACID (Atomicity, Consistency, Isolation and 
Durability)

### atomicity

multiple database operations that alter the database state can be treated as one indivisible unit of work. A transaction is indivisble

> **recovery manager** can induce rollbacks where necessary (based on **before images** in the **logfile**), by means of UNDO operations 

### consistency

a transaction, if  executed in isolation, renders the database from one consistent state into another consistent state

- developer is primary responsible
- also an overarching responsibility of the DBMS’s transaction management system

### isolation

when multiple Ts are executed concurrently, outcome should be equal to T execution in isolation

> responsibility of the **concurrency control** mechanisms of the  DBMS, as coordinated by the **scheduler**

### durability

the effects of a committed transaction should always be persisted into the database

> Responsibility of recovery manager (e.g. by **REDO** operations or data redundancy) (eg. flush did not happen)