

-- Exercises

-- Create the following overview in which each customer gets a sequential number. 
-- The number is reset when the country changes
/*
country		rownum	CompanyName
Argentina	1		Cactus Comidas para llevar
Argentina	2		Océano Atlántico Ltda.
Argentina	3		Rancho grande
Austria		1		Ernst Handel
Austria		2		Piccolo und mehr
Belgium		1		Maison Dewey
Belgium		2		Suprêmes délices
Brazil		1		Comércio Mineiro
Brazil		2		Familia Arquibaldo
Brazil		3		Gourmet Lanchonetes
Brazil		4		Hanari Carnes
...
*/


SELECT  country,
   ROW_NUMBER() OVER (PARTITION BY country ORDER BY CompanyName) rownum, CompanyName
FROM customers
WHERE country IS NOT NULL
ORDER BY country;

-- Step 1: First create an overview that shows for each productid the amount sold per year

SELECT od.productid, YEAR(o.orderdate) As OrderYear, SUM(quantity) As AmountSoldPerYear
FROM orders o JOIN OrderDetails od ON o.orderid = od.orderid
GROUP BY od.productid, YEAR(o.orderdate)
ORDER BY od.productid, YEAR(o.orderdate)

-- Step 2: Now create an overview that shows for each productid the amount sold per year and for the previous year.
/*
1	2016	125	NULL
1	2017	304	125
1	2018	399	304
2	2016	226	NULL
2	2017	435	226
2	2018	396	435
3	2016	30	NULL
3	2017	190	30
3	2018	108	190
...
*/


select od.ProductID, year(o.OrderDate) As YearSold, sum(od.Quantity) as AmountSoldPerYear, 
LAG(sum(od.Quantity), 1) over (partition by productid order by year(o.orderdate)) as AmountSoldPreviousYear
FROM orders o JOIN OrderDetails od ON o.orderid = od.orderid
group by od.ProductID, year(o.OrderDate)
order by od.ProductID, year(o.OrderDate)


-- Step 3: Use a CTE and the previous SQL Query to calculate the year over year performance for each productid. 
-- If the amountPreviousYear is NULL, then the year over year performance becomes N/A.

/*
1	2016	125	NULL	N/A
1	2017	304	125	143.20%
1	2018	399	304	31.25%
2	2016	226	NULL	N/A
2	2017	435	226	92.48%
2	2018	396	435	-8.97%
3	2016	30	NULL	N/A
3	2017	190	30	533.33%
3	2018	108	190	-43.16%
...
*/



WITH cte_amountSold (productid, yearOrder, amountSoldPerYear, AmountSoldPreviousYear)
AS
(select od.ProductID, year(o.OrderDate) As YearSold, sum(od.Quantity) as AmountSoldPerYear, 
LAG(sum(od.Quantity), 1) over (partition by productid order by year(o.orderdate)) as AmountSoldPreviousYear
FROM orders o JOIN OrderDetails od ON o.orderid = od.orderid
group by od.ProductID, year(o.OrderDate))

SELECT productid, yearOrder, amountSoldPerYear, AmountSoldPreviousYear, 
ISNULL(FORMAT(1.0 * (amountSoldPerYear - AmountSoldPreviousYear) / AmountSoldPreviousYear, 'P'), 'N/A') As RelativeDifference
FROM cte_amountSold


-- Exercise 2
-- Step 1: First create an overview of the revenue (unitprice * quantity) per year per employeeid
/*
1	2016	38789,00
1	2017	97533,58
1	2018	65821,13
2	2016	22834,70
2	2017	74958,60
2	2018	79955,96
3	2016	19231,80
3	2017	111788,61
3	2018	82030,89
4	2016	53114,80
4	2017	139477,70
4	2018	57594,95
...
*/

select o.employeeid, year(o.orderdate) As OrderYear, sum(od.UnitPrice * od.Quantity) as revenue
from orders o join OrderDetails od on o.OrderID = od.OrderID
group by o.EmployeeID,  year(o.orderdate)
ORDER BY EmployeeID, OrderYear

-- Step 2: Now add a ranking per year per employeeid
/*
4	2016	53114,80	1
1	2016	38789,00	2
8	2016	23161,40	3
2	2016	22834,70	4
5	2016	21965,20	5
3	2016	19231,80	6
7	2016	18104,80	7
6	2016	17731,10	8
9	2016	11365,70	9
...
*/

select o.employeeid, year(o.orderdate) As OrderYear, sum(od.UnitPrice * od.Quantity) as revenue,
RANK() OVER (PARTITION BY  year(o.orderdate) ORDER BY sum(od.UnitPrice * od.Quantity) DESC) As ranking
from orders o join OrderDetails od on o.OrderID = od.OrderID
group by o.EmployeeID,  year(o.orderdate)


-- Step 3:	Imagine there is a bonussystem for all the employees: the best employee gets 10 000EUR bonus, the second one 5000 EUR, the third one 2500 EUR, …

/*
4	2016	53114,80	10000
1	2016	38789,00	5000
8	2016	23161,40	3333
2	2016	22834,70	2500
5	2016	21965,20	2000
3	2016	19231,80	1666
7	2016	18104,80	1428
6	2016	17731,10	1250
9	2016	11365,70	1111
...
*/

select o.employeeid, year(o.orderdate) As OrderYear, sum(od.UnitPrice * od.Quantity) as revenue,
10000 / RANK() OVER (PARTITION BY  year(o.orderdate) ORDER BY sum(od.UnitPrice * od.Quantity) DESC) As bonus
from orders o join OrderDetails od on o.OrderID = od.OrderID
group by o.EmployeeID,  year(o.orderdate)


-- Exercise: Calculate for each month the percentage difference between the revenue for this month and the previous month
/*
2016	7	30192,10	NULL	NULL
2016	8	26609,40	30192,10	-11.86%
2016	9	27636,00	26609,40	3.85%
2016	10	41203,60	27636,00	49.09%
2016	11	49704,00	41203,60	20.63%
2016	12	50953,40	49704,00	2.51%
2017	1	66692,80	50953,40	30.88%
2017	2	41207,20	66692,80	-38.21%
2017	3	39979,90	41207,20	-2.97%
2017	4	55699,39	39979,90	39.31%
2017	5	56823,70	55699,39	2.01%
2017	6	39088,00	56823,70	-31.21%
2017	7	55464,93	39088,00	41.89%
2017	8	49981,69	55464,93	-9.88%
2017	9	59733,02	49981,69	19.50%
*/

-- Step 1: calculate the revenue per year and per month
WITH RevenuePerYearAndMonth (OrderYear, OrderMonth, Revenue)
AS
(SELECT YEAR(o.OrderDate) As OrderYear, Month(o.OrderDate) As OrderMonth, SUM(od.UnitPrice * od.Quantity) As Revenue
FROM Products p INNER JOIN OrderDetails od ON od.ProductID = p.ProductID
INNER JOIN Orders o ON o.OrderID = od.OrderID
GROUP BY YEAR(o.OrderDate), Month(o.OrderDate)),

-- Step 2: Add an extra column for each row with the revenue of the previous month
RevenuePerYearAndMonthAndPreviousMonth (OrderYear, OrderMonth, Revenue, RevenuePreviousMonth)
AS
(SELECT OrderYear, OrderMonth, Revenue,
LAG(Revenue) OVER (ORDER BY OrderYear, OrderMonth) RevenuePreviousMonth
FROM RevenuePerYearAndMonth)

-- Step 3: Calculate the percentage difference between this month and the previous month
SELECT OrderYear, OrderMonth, Revenue, RevenuePreviousMonth, FORMAT((Revenue - RevenuePreviousMonth) / RevenuePreviousMonth, 'P') As PercentageDifference
FROM RevenuePerYearAndMonthAndPreviousMonth
ORDER BY OrderYear, OrderMonth





