/*
Issues
The issue with a READ COMMITTED is that other transactions can still mutate the data outside of the first transaction. For example:

1. Session 1 reads data;
2. Session 1 does some other actions on other data (in the example below simulated with the WAITFOR 20 seconds statement);
3. Session 2 updates the same data as Session 1 which just reads and commits, there is no mutation going on;
4. Session 1 reads the same data again after 20 seconds.
5. The data will no longer be the same.
*/

-- Session 1
SET TRANSACTION ISOLATION LEVEL READ COMMITTED 
BEGIN TRANSACTION

RAISERROR('1. Going to select the data.',0,0) WITH NOWAIT
SELECT  EmpID, EmpName, EmpSalary
FROM    dbo.TestIsolationLevels 
WHERE   EmpID = 2900

RAISERROR('2. Selected all my data.',0,0) WITH NOWAIT
RAISERROR('Doing some other stuff for 20 seconds.',0,0) WITH NOWAIT

WAITFOR DELAY '00:00:20' -- Do some other actions.

RAISERROR('3. Going to select the data.',0,0) WITH NOWAIT
SELECT  EmpID, EmpName, EmpSalary
FROM    dbo.TestIsolationLevels 
WHERE   EmpID = 2900
RAISERROR('4. Selected all my data.',0,0) WITH NOWAIT

COMMIT

