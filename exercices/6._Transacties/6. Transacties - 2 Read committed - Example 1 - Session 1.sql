/*
READ COMMITTED
Is the default isolation level for SQL Server. 
It prevents dirty reads and lost updates by specifying that statements cannot 
read data values that have been modified but not yet committed by other transactions. 
However, the inconsistent analysis problem may still occur with this isolation level, 
as well as nonrepeatable reads and phantom reads.
*/

-- Session 1 
/*
The code starts a transaction, updates the EmpSalary to 25.000, 
waits for 20 seconds to simulate a long statement and after 20 seconds, 
the transaction is rolledback. Within those 20 seconds of waiting make sure 
to execute the code for Session 2. 
If you waited too long you can execute Session 1 again.
!Look at the messages!
*/

BEGIN TRANSACTION
DECLARE @startMessage varchar(200) = 'Transaction started at ' + CONVERT(varchar, SYSDATETIME(), 121)
RAISERROR(@startMessage,0,0) WITH NOWAIT

UPDATE  dbo.TestIsolationLevels 
SET     EmpSalary = 25000
WHERE   EmpID = 2900

RAISERROR('Update happened, waiting 20 seconds to ROLLBACK',0,0) WITH NOWAIT
WAITFOR DELAY '00:00:20'
ROLLBACK;
DECLARE @endMessage varchar(200) = 'Rollback happened at ' + CONVERT(varchar, SYSDATETIME(), 121)
RAISERROR(@endMessage,0,0) WITH NOWAIT

-- Result
/*
1. Session 1 tried to update the salary;
2. During the update of Session 1, Session 2 tried reading the data after 
it was updated by Session 1, notice that the transaction of Session 1 was not committed yet. 
Therefore Session 2 is waiting on an action(ROLLBACK or COMMIT) from Session 1.
3. Session 1 did a rollback of it's changes, so basically the update did not happen. 
Only after Session 1 completes, Session 2 can read the values.
*/