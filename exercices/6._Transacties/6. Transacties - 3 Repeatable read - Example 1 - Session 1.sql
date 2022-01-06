/*
REPEATABLE READ
Is a more restrictive isolation level than READ COMMITTED. 
It basically is a READ COMMITTED but additionally specifies that no other 
transactions can modify or delete data that has been read by the current 
transaction until the current transaction commits. 
Concurrency is lower than for READ COMMITTED because shared locks on read data are held 
for the duration of the transaction instead of being released at the end of each statement.
*/

-- Session 1


SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
SET NOCOUNT ON
GO
BEGIN TRANSACTION
SELECT  EmpID, EmpName, EmpSalary
FROM    dbo.TestIsolationLevels 
WHERE   EmpID = 2900

WAITFOR DELAY '00:00:10' -- Do some other actions.

SELECT  EmpID, EmpName, EmpSalary
FROM    dbo.TestIsolationLevels 
WHERE   EmpID = 2900
COMMIT

