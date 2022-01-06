/* Exercises */

-- 1. Give the id and name of the products that have not been purchased yet. 
select productid, productname
from products
where productid not in (select productid from Orders);


-- 2. Select the names of the suppliers who supply products that have not been ordered yet. 
select s.CompanyName 
from suppliers s join products p on s.supplierID = p.supplierID
where productID not in (select productID from OrderDetails);

-- 3. Give a list of all customers from the same country as the customer Maison Dewey
SELECT CompanyName, country
FROM customers
WHERE country = (SELECT country from customers WHERE companyName = 'Maison Dewey')

-- 4. Calculate how much is earned by the management (like 'president' or 'manager'), the submanagement (like 'coordinator') and the rest
SELECT TitleClass, SUM(Salary) As TotalSalary
FROM
(
SELECT 
CASE 
WHEN title LIKE '%President%' OR title LIKE '%Manager%' THEN 'Management'
WHEN title LIKE '%Coordinator%' THEN 'SubManagment'
ELSE 'Rest' 
END, Salary
FROM Employees
) 
AS Totals(Titleclass, Salary)
GROUP BY TitleClass


-- 5. Give for each product how much the price differs from the average price of all products of the same category
SELECT ProductID, ProductName, UnitPrice, 
UnitPrice -
(
    SELECT AVG(UnitPrice)
    FROM Products
    WHERE CategoryID = p.CategoryID
) As differenceToCategory
FROM Products p



-- 6. Give per title the employee that was last hired

SELECT title, firstname + ' ' + lastname, HireDate
FROM employees e
WHERE HireDate = (SELECT MAX(HireDate) FROM employees WHERE title = e.title)


-- 7. Which employee has processed most orders? 
select e.firstname + ' '+ e.lastname, count(*)
from employees e join orders o on e.employeeid = o.EmployeeID
group by e.EmployeeID,e.LastName,e.FirstName
having count(*) = 
(select top 1 count(*)
 from employees e join orders o on e.employeeid = o.EmployeeID
 group by e.firstname + ' ' + e.lastname
 order by count(*) desc);

-- 8. What's the most common ContactTitle in Customers?
SELECT DISTINCT ContactTitle
FROM Customers
WHERE contactTitle = (SELECT TOP 1 ContactTitle FROM Customers GROUP BY ContactTitle ORDER BY COUNT(contacttitle) DESC)


-- 9. Is there a supplier that has the same name as a customer?
SELECT CompanyName FROM Suppliers WHERE CompanyName IN (SELECT CompanyName FROM Customers)


