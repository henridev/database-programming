/* Common Table Expression */


/* Exercises */

-- 1. Give per region the number of orders (region USA + Canada = North America, rest = Rest of World).
-- Solution 1
SELECT 
CASE c.Country
WHEN 'USA' THEN 'Northern America'
WHEN 'Canada' THEN 'Northern America'
ELSE 'Rest of world' 
END AS Regionclass, COUNT(o.OrderID) As NumberOfOrders
FROM Customers c JOIN Orders o 
ON c.CustomerID = o.CustomerID
GROUP BY
CASE c.Country
WHEN 'USA' then 'Northern America'
WHEN 'Canada' then 'Northern America'
ELSE 'Rest of world' 
END

-- Solution 2 -> avoid copy-paste (subquery in FROM)
SELECT Regionclass, COUNT(OrderID)
FROM
(
SELECT 
CASE c.Country
WHEN 'USA' THEN 'Northern America'
WHEN 'Canada' THEN 'Northern America'
ELSE 'Rest of world' 
END AS Regionclass, o.OrderID
FROM Customers c JOIN Orders o 
ON c.CustomerID = o.CustomerID
) 
AS Totals(Regionclass, OrderID)
GROUP BY Regionclass

-- Solution 3 (with CTE's)
WITH Totals(Regionclass, OrderID)
AS
(SELECT 
CASE c.Country
WHEN 'USA' THEN 'Northern America'
WHEN 'Canada' THEN 'Northern America'
ELSE 'Rest of world' 
END AS Regionclass, o.OrderID
FROM Customers c JOIN Orders o 
ON c.CustomerID = o.CustomerID)

SELECT Regionclass, COUNT(OrderID)
FROM Totals
GROUP BY Regionclass





-- 2 Make a histogram of the number of orders per customer, so show how many times each number occurs. 
-- E.g. in the graph below: 1 customer placed 1 order, 2 customers placed 2 orders, 7 customers placed 3 orders, etc. 

-- cte --> number of orders per customer

/*
nr	NumberOfCustomers
1	1
2	2
3	7
4	6
5	10

...

*/

with NumberOfOrders(nr) as 
(select count(*)
 from orders
 group by customerid)

   select nr, count(*) as NumberOfCustomers
   from NumberOfOrders
   group by nr
   order by nr;



-- 3. Give the customers of the Country in which most customers live
--> cte1: number of customers per country
--> cte2: maximum */

WITH cte1(Country, NumberOfCustomers)
AS
(SELECT Country, COUNT(CustomerID)
FROM Customers
GROUP BY Country),

cte2(MaximumNumberOfCustomers)
AS
(SELECT MAX(NumberOfCustomers)
FROM cte1)

SELECT CustomerID, CompanyName, c.Country
FROM Customers c JOIN cte1 ON c.country = cte1.country JOIN cte2 ON cte1.NumberOfCustomers = cte2.MaximumNumberOfCustomers



-- 4. Give all employees except for the eldest
--> birthdate of the eldest in subquery or cte

-- Solution 1 (using Subqueries)
SELECT employeeid, firstname + ' ' + lastname As employeeName, birthdate
FROM employees
WHERE birthdate > (SELECT MIN(birthdate) FROM employees)

-- Solution 2 (using CTE's)
WITH eldest(min_birthdate) AS
(SELECT min(birthdate)
FROM employees)

SELECT employeeid, firstname + ' ' + lastname As employeeName, birthdate
FROM employees CROSS JOIN eldest 
WHERE birthdate > eldest.min_birthdate





-- 5.  What is the total number of customers and suppliers?

WITH numberOfCustomers(nrOfCust) as (SELECT COUNT(CustomerID) FROM Customers),
numberOfSuppliers(nrOfSup) as (SELECT COUNT(SupplierID) FROM Suppliers)

SELECT((SELECT nrOfCust from numberOfCustomers) + (SELECT nrOfSup FROM numberOfSuppliers))


WITH numberOfCustomers(nrOfCust) as (SELECT COUNT(CustomerID) FROM Customers),
numberOfSuppliers(nrOfSup) as (SELECT COUNT(SupplierID) FROM Suppliers)

SELECT nrOfCust + nrOfSup As 'Total number of customers and suppliers'
FROM numberOfCustomers CROSS JOIN numberOfSuppliers


-- 6. Give per title the eldest employee
WITH eldestPerTitle(title, min_birthdate) AS
(SELECT title, min(birthdate)
FROM employees
GROUP BY title)

SELECT employeeid, ept.title, ept.min_birthdate
FROM Employees e JOIN eldestPerTitle ept
ON e.title = ept.title
WHERE e.BirthDate = ept.min_birthdate


-- 7. Give per title the employee that earns most
WITH mostEarningPerTitle(title, max_salary) AS
(SELECT title, max(salary)
FROM employees
GROUP BY title)

SELECT employeeid, firstname + ' ' + lastname, mept.title, mept.max_salary
FROM Employees e JOIN mostEarningPerTitle mept
ON e.title = mept.title
WHERE e.salary = mept.max_salary


-- 8. Give the titles for which the eldest employee is also the employee who earns most
WITH eldestPerTitle(title, min_birthdate) AS
(SELECT title, min(birthdate)
FROM employees
GROUP BY title),

mostEarningPerTitle(title, max_salary) AS
(SELECT title, max(salary)
FROM employees
GROUP BY title)

SELECT employeeid, ept.title, ept.min_birthdate, mept.max_salary
FROM Employees e JOIN eldestPerTitle ept
ON e.title = ept.title
JOIN mostEarningPerTitle mept ON e.title = mept.title
WHERE e.BirthDate = ept.min_birthdate AND e.salary = mept.max_salary


-- 9. Execute the following script:
CREATE TABLE Parts 
(
    [Super]   CHAR(3) NOT NULL,
    [Sub]     CHAR(3) NOT NULL,
    [Amount]  INT NOT NULL,
    PRIMARY KEY(Super, Sub)
);

INSERT INTO Parts VALUES ('O1','O2',10);
INSERT INTO Parts VALUES ('O1','O3',5);
INSERT INTO Parts VALUES ('O1','O4',10);
INSERT INTO Parts VALUES ('O2','O5',25);
INSERT INTO Parts VALUES ('O2','O6',5);
INSERT INTO Parts VALUES ('O3','O7',10);
INSERT INTO Parts VALUES ('O6','O8',15);
INSERT INTO Parts VALUES ('O8','O11',5);
INSERT INTO Parts VALUES ('O9','O10',20);
INSERT INTO Parts VALUES ('O10','O11',25);

-- Show all parts that are directly or indirectly part of O2, so all parts of which O2 is composed.
-- Add an extra column with the path as below: 

/*
SUPER	SUB		PAD
O2		O5		O2 <-O5
O2		O6		O2 <-O6
O6		O8		O2 <-O6 <-O8
O8		O11		O2 <-O6 <-O8 <-O11

*/

WITH Relation(Super, Sub, [Path]) AS 
    (
        -- Default
        SELECT 
         Super
        ,Sub
        ,[Path] =  CAST(CONCAT(Super, ' <- ',Sub) AS NVARCHAR(MAX)) -- Don't forget to CAST
        FROM Parts  
        WHERE Super = 'O2' 

        UNION ALL
        -- Recursion
        SELECT 
         Parts.Super
        ,Parts.Sub  
        ,[Path] = CONCAT(Relation.[Path], ' <- ',Parts.Sub)
        FROM Parts 
            JOIN Relation ON Parts.Super = Relation.Sub
    ) 
    SELECT * FROM Relation;
