/*
SERIALIZABLE
Is the most restrictive isolation level, because it locks entire ranges of keys 
and holds the locks until the transaction is complete. 
Basically it's the same as REPEATABLE READ but adds the restriction that other transactions cannot 
insert new rows into ranges that have been read by the transaction until the transaction is complete.

SERIALIZABLE has all the features of READ COMMITTED, 
REPEATABLE READ but also ensures concurrent transactions are treated as if they had been run in serial. 
This means guaranteed repeatable reads, and no phantom rows. 
Be warned, however, that this (and to some extent, the previous two isolation levels) 
can cause large performance losses as concurrent transactions are effectively queued.
*/

-- Session 1


SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
SET NOCOUNT ON
GO
BEGIN TRANSACTION
SELECT  EmpID, EmpName, EmpSalary
FROM    dbo.TestIsolationLevels 


WAITFOR DELAY '00:00:10' -- Do some other actions.

SELECT  EmpID, EmpName, EmpSalary
FROM    dbo.TestIsolationLevels 

COMMIT

