-- TRANSACTIONS IN SQL SERVER

use Transactions_Db;
-- DEADLOCKS - SESSION 2

-- 2
begin transaction
-- 4
select EmpSalary from dbo.TestIsolationLevels where EmpID=2950
-- S-lock on record for employeeid=2900 is taken and released 
-- after the select statement (default isolation level = read committed)
-- 7
update dbo.TestIsolationLevels set EmpSalary = EmpSalary * 1.1 where EmpID=2950
-- X-lock on record for employeeid=2900 is taken and held until end of transaction 
-- (write statements are not effected by isolation level)
-- 8
select EmpSalary from dbo.TestIsolationLevels where EmpID=2950
-- 10
select EmpSalary from dbo.TestIsolationLevels where EmpID=2900
-- session "hangs" for a few seconds continues after session 1 has been killed (or vice versa)
-- due to deadlock detection
-- it shows the "old" value of the salary because session 1 has never committed its update
-- 12
commit
-- the X-lock is released