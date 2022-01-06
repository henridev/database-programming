-- Session 2
/*
You'll notice that the query does not complete directly since it's waiting 
on an action(COMMIT or ROLLBACK) from Session 1, after 20 seconds the query 
is completed since Session 1 did a ROLLBACK of the transaction
*/

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION
DECLARE @startMessage varchar(200) = 'Select requested at ' + CONVERT(varchar, SYSDATETIME(), 121)
RAISERROR(@startMessage,0,0) WITH NOWAIT

SELECT EmpID, EmpName, EmpSalary
FROM dbo.TestIsolationLevels
WHERE EmpID = 2900

DECLARE @endMessage varchar(200) = 'Select completed at ' + CONVERT(varchar, SYSDATETIME(), 121)
RAISERROR(@endMessage,0,0) WITH NOWAIT
COMMIT