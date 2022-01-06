-- 1. Which suppliers (SupplierID and CompanyName) deliver Dairy Products? 
SELECT DISTINCT s.SupplierID, s.CompanyName
FROM Suppliers s JOIN Products p ON s.SupplierID = p.SupplierID
JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName LIKE '%Dairy%'

-- 2. Give for each supplier the number of orders that contain products of that supplier. 
-- Show supplierID, companyname and the number of orders.
-- Order by companyname.
select s.SupplierID, s.CompanyName, count(DISTINCT od.OrderID) As NrOfOrders
from Suppliers s join Products p ON s.SupplierID = p.SupplierID
JOIN OrderDetails od ON od.ProductID = p.ProductID
GROUP BY s.SupplierID, s.CompanyName
ORDER BY s.CompanyName

-- 3. What’s for each category the lowest UnitPrice? Show category name and unit price. 
SELECT c.CategoryName, MIN(p.UnitPrice) As 'Minimum UnitPrice'
FROM Products p join Categories c ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryName

-- 4. Give for each ordered product: productname, the least (columnname 'Min amount ordered') and the most ordered (columnname 'Max amount ordered'). Order by productname.
SELECT p.ProductName, MIN(od.Quantity) As 'Min amount ordered', Max(od.Quantity) As 'Max amount ordered'
FROM Products p join OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductName
ORDER BY p.ProductName

-- 5. Give a summary for each employee with orderID, employeeID and employeename.
-- Make sure that the list also contains employees who don’t have orders yet.
SELECT e.EmployeeID, e.FirstName + ' ' + e.LastName As 'Name', o.OrderID
FROM Employees e left join Orders o on e.EmployeeID = o.EmployeeID
