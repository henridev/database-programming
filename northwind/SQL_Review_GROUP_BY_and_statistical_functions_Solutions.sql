-- 1. Count the amount of products (columnname 'amount of products'), AND the amount of products in stock (= unitsinstock not empty) (columnname 'Units in stock') 
SELECT COUNT(ProductID) As 'Amount of products', SUM(UnitsInStock) As 'Units in Stock'
FROM Products

-- 2. How many employees have a function of Sales Representative (columnname 'Number of Sales Representative')? 
SELECT COUNT(EmployeeID) As 'Number of Sales Representative'
FROM Employees
WHERE Title = 'Sales Representative'

-- 3. Give the date of birth of the youngest employee (columnname 'Birthdate youngest') and the eldest (columnname 'Birthdate eldest').
SELECT MAX(BirthDate) As 'Birthdate Youngest', MIN(BirthDate) As 'Birthdate Eldest'
FROM Employees

-- 4. What's the number of employees who will retire (at 65) within the first 20 years? 
SELECT *
FROM Employees
WHERE DATEDIFF(year, Birthdate, GETDATE()) >= 45

-- 5. Show a list of different countries where 2 of more suppliers are from. Order alphabeticaly. 
SELECT Country, COUNT(SupplierID) As 'Number of suppliers'
FROM Suppliers
GROUP BY Country
HAVING COUNT(SupplierID) >= 2

-- 6. Which suppliers offer at least 5 products with a price less than 100 dollar? Show supplierId and the number of different products. 
-- The supplier with the highest number of products comes first. 
SELECT SupplierID, COUNT(ProductID) As 'Number of products less than 100'
FROM Products
WHERE UnitPrice < 100
GROUP BY SupplierID
HAVING COUNT(ProductID) >= 5












