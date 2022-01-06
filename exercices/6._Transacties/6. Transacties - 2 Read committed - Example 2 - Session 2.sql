-- Session 2

BEGIN TRANSACTION
UPDATE  dbo.TestIsolationLevels 
SET     EmpSalary = 25000
WHERE   EmpID = 2900
COMMIT