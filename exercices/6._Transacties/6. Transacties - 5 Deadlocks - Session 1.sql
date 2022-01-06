-- TRANSACTIONS IN SQL SERVER

use Transactions_Db;
-- DEADLOCKS - SESSION 1

-- 1
begin transaction
-- 3
select EmpSalary from dbo.TestIsolationLevels where EmpID=2900
-- S-lock on record for employeeid=2900 is taken and released 
-- after the select statement (default isolation level = read committed)
-- 5
update dbo.TestIsolationLevels set EmpSalary = EmpSalary * 1.1 where EmpID=2900
-- X-lock on record for employeeid=2900 is taken and held until end of transaction 
-- (write statements are not effected by isolation level)
-- 6
select EmpSalary from dbo.TestIsolationLevels where EmpID=2900
-- shows 44.000

RAISERROR('Session 1 - waiting for 5 so Session 2 can start.',0,0) WITH NOWAIT
WAITFOR DELAY '00:00:05'

-- 9
select EmpSalary from dbo.TestIsolationLevels where EmpID=2950
-- sessions "hangs", in fact it waits for the X-lock from session 2 on employeeid = 2950 to be released
-- after session 2 queries the record from employee 2900 a deadlock occurs and this session is chosen as the deadlock victim
-- a rollback is executed automatically and X-lock is released
-- 11
select EmpSalary from dbo.TestIsolationLevels where EmpID=2950
-- the session hangs again because session 2 still hasn't committed nor aborted
-- after session 2 commits the new salary for employee 2950 is shown