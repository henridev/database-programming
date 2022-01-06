-- Session 2

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DECLARE @startMessage varchar(200) = 'Select requested at ' + CONVERT(varchar, SYSDATETIME(), 121)
RAISERROR(@startMessage,0,0) WITH NOWAIT

SELECT EmpID, EmpName, EmpSalary
FROM dbo.TestIsolationLevels
WHERE EmpID = 2900
DECLARE @endMessage varchar(200) = 'Select completed at ' + CONVERT(varchar, SYSDATETIME(), 121)
RAISERROR(@endMessage,0,0) WITH NOWAIT