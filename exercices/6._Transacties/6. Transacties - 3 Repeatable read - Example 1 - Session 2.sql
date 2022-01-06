-- Session 2

BEGIN TRANSACTION
UPDATE  dbo.TestIsolationLevels
SET     EmpSalary = 26000
WHERE   EmpID = 2900
COMMIT