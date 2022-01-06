/*
Issues
Interestingly though, this still doesn't hold true for phantom rows - 
it's possible to insert rows into a table and have the rows returned 
by a calling SELECT transaction even under the REPEATABLE READ isolation level.
*/

-- Session 1


SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
SET NOCOUNT ON
GO

BEGIN TRANSACTION
SELECT  EmpName
FROM    dbo.TestIsolationLevels 

WAITFOR DELAY '00:00:10'

SELECT  EmpName
FROM    dbo.TestIsolationLevels 
COMMIT