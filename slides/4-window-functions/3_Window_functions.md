# 3. Window Functions

dit komt aan bod bij SQL examen = open boek slides zijn te gebruiken

> A window function performs a *calculation across a set of table rows* that are *somehow related to the current row*. This is comparable to the type of calculation that can be done with an aggregate function. But unlike regular aggregate functions, use of a window function *does not cause rows to become grouped into a single output row* — the *rows retain their separate identities*. Behind the scenes, the window function is able to access more than just the current row of the query result.

> window = ordered subset of data over which calculations are made => usualy defined by `ORDER BY` and `PARITTION BY` after `OVER` clause

## 3.1 introduction

- mogelijk gebruik is vergelijken huidige tov vorige verkoop
- CTE => with component | WF => over clause

## 3.2 OVER clause

- makes partition of `SELECT` result
- per partition there are numbering ordering and aggregate functions
- `OVER` creates the *partitions* and *ordering*
- paritition = window shifting over the data
- `OVER` is usable with usual aggregate functions (sum, avg ...) or specific window functions (range, lag ...)

### 3.2.1 example: running total

```SQL
SELECT CategoryID, ProductID, UnitsInStock
FROM Products
ORDER BY CategoryId, ProductId
```

solution 1: Correlated Subquery

```SQL
SELECT CategoryID, ProductID, UnitsInStock,
    (
        SELECT SUM(UnitsInStock)
        FROM Products
        WHERE CategoryID = p.CategoryID
        AND ProductID <= p.ProductID
    ) as TotalUnitsInStockPerCategory
FROM Products p
ORDER BY CategoryId, ProductId
```

> the problem with this is it's inefficiency as it calculates the sum for each row

solution 2: Over clause

- we gaan de sum doen in de volgorde category, product en voor de partitie product.
- parititie bepaalt wanneer resetten
- volgorde in de order by is de volgorde waaring geteld wordt
- stel we laten de parititie weg dan zal gewoon doorgeteld worden
- order by bepaald in welke volgorde er opgeteld zal worden

```SQL
SELECT CategoryID, ProductID, UnitsInStock,
	-- take the sum of units in stock over the entire result set in order by category id and product id
	SUM(UnitsInStock) 
	OVER (ORDER BY CategoryID, ProductID) 
	as TotalUnitsInStockPerCategory
FROM Products p
ORDER BY CategoryId, ProductId

SELECT CategoryID, ProductID, UnitsInStock,
	-- each sum will simply be sum of all within the partition = what the end value would be if order by was used
	SUM(UnitsInStock) 
	OVER (PARTITION BY CategoryID) 
	as TotalUnitsInStockPerCategory
FROM Products p
ORDER BY CategoryId, ProductId

SELECT CategoryID, ProductID, UnitsInStock,
	-- take the sum of units in stock over the set partitioned by category id in order by category id and product id
	-- within each category take the running total 
	SUM(UnitsInStock) 
	OVER (PARTITION BY CategoryID ORDER BY CategoryID, ProductID) 
	as TotalUnitsInStockPerCategory
FROM Products p
ORDER BY CategoryId, ProductId

-- in volgorde van product id stock samentellen
SELECT CategoryID, ProductID, UnitsInStock,
	SUM(UnitsInStock) 
	OVER (ORDER BY ProductID) 
	as TotalUnitsInStockPerCategory
FROM Products p
ORDER BY ProductId
```

we can also use other aggregate functions besides sum

```SQL
SELECT CategoryID, ProductID, UnitsInStock,
	SUM(UnitsInStock) 
	OVER (PARTITION BY CategoryID ORDER BY CategoryID, ProductID) 
	as TotalUnitsInStockPerCategory,
	
	AVG(UnitsInStock) 
	OVER (PARTITION BY CategoryID ORDER BY CategoryID, ProductID) 
	as AvgUnitsInStockPerCategory,

	COUNT(UnitsInStock) 
	OVER (PARTITION BY CategoryID ORDER BY CategoryID, ProductID) 
	as CounUnitsInStockPerCategory
FROM Products p
ORDER BY CategoryId, ProductId
```

> this solution is more efficient as it calculates the sum for each partition
> partities zijn een optie maar order by zijn verlplicht

## 3.3 RANGE

3.2 is syntax sugar that leaves out `RANGE`

```SQL
SELECT CategoryID, ProductID, UnitsInStock,
	SUM(UnitsInStock) OVER 
	RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	as TotalUnitsInStockPerCategory
FROM Products p
ORDER BY CategoryId, ProductId
```

er zijn andere opties voor unbounded preceding and current row

```SQL
RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
```

### 3.3.1 Example

```SQL
SELECT CategoryID, ProductID, UnitsInStock,
	SUM(UnitsInStock) 
	OVER (PARTITION BY CategoryID ORDER BY CategoryID, ProductID
    -- vorige tot huidige = cumulatief
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as sumPrecCurr,
	SUM(UnitsInStock) 
	OVER (PARTITION BY CategoryID ORDER BY CategoryID, ProductID
    -- huidige tot opvolgende
    RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) as sumCurrFol,
	SUM(UnitsInStock) 
	OVER (PARTITION BY CategoryID ORDER BY CategoryID, ProductID
    -- vorige vorige tot opvolgende = category totaal
    RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as sumPrecFol
FROM Products p
WHERE ProductId < 15
ORDER BY CategoryId, ProductId
```

| CategoryID | ProductID | UnitsInStock | sumPrecCurr | sumCurrFol | sumPrecFol |
| ---------- | --------- | ------------ | ----------- | ---------- | ---------- |
| 1          | 1         | 39           | 39          | 56         | 56         |
| 1          | 2         | 17           | 56          | 17         | 56         |
| 2          | 3         | 13           | 13          | 192        | 192        |
| 2          | 4         | 53           | 66          | 179        | 192        |
| 2          | 5         | 0            | 66          | 126        | 192        |
| 2          | 6         | 120          | 186         | 126        | 192        |
| 2          | 8         | 6            | 192         | 6          | 192        |
| 4          | 11        | 22           | 22          | 108        | 108        |
| 4          | 12        | 86           | 108         | 86         | 108        |
| 6          | 9         | 29           | 29          | 29         | 29         |
| 7          | 7         | 15           | 15          | 50         | 50         |
| 7          | 14        | 35           | 50          | 35         | 50         |
| 8          | 10        | 31           | 31          | 55         | 55         |
| 8          | 13        | 24           | 55          | 24         | 55         |

## 3.4 ROWS

- while for `RANGE` current row is compared to other row based on `ORDER BY` predicate
- if you want a physical offset however you should use `ROWS`

```SQL
-- vb sales per maand en vorige sales als voorbije 3 maand
ROWS BETWEEN N PRECEDING AND CURRENT ROW
RANGE BETWEEN CURRENT ROW AND N FOLLOWING
RANGE BETWEEN N PRECEDING AND UNBOUNDED FOLLOWING
```

```SQL
SELECT 
	EmployeeID, 
	LastName + ' ' + FirstName as 'Name',
	Salary,
	AVG(Salary) OVER (ORDER BY Salary DESC ROWS BETWEEN  2 PRECEDING AND CURRENT ROW) as AvgSalary2Preceding
	-- OR
	-- AVG(Salary) OVER (ORDER BY Salary DESC ROWS BETWEEN  CURRENT ROW AND 1 FOLLOWING) as AvgSalary2Following
	-- OR
	-- AVG(Salary) OVER (ORDER BY Salary DESC ROWS BETWEEN  1 PRECEDING AND 1 FOLLOWING) as AvgSalary1Preceding2Following
FROM Northwind.dbo.Employees;
```

## 3.5 FUNCTIES WITH WINDOW FUNCTIONS

- `ROW_NUMBER()` => sequential number of a row within a partition (number rows in sequence 1,2,3,4,5)
- `RANK()` => rank of row within the partition = one + 1 plus ranks before the row (same number for ties 1,2,2,4,5 <- registreerd de gelijke stand)
- `DENSE_RANK()` =>  returns the rank of each row within the  partition of a result set, with no gaps in the ranking values (1,2,2,3,4)
- `PCT_RANK())` => ranking on 0-1 scale

```SQL
SELECT 
	EmployeeID, 
	LastName + ' ' + FirstName as 'Name',
	Title,
	Salary,
	ROW_NUMBER() OVER (ORDER BY Salary DESC) as 'ROW_NUMBER',
	RANK() OVER (ORDER BY Salary DESC) as 'RANK',
	DENSE_RANK() OVER (ORDER BY Salary DESC) as 'DENSE_RANK',
	PERCENT_RANK() OVER (ORDER BY Salary DESC) as 'PERCENT_RANK'
FROM Northwind.dbo.Employees;

SELECT 
	EmployeeID, 
	LastName + ' ' + FirstName as 'Name',
	Title,
	Salary,
	ROW_NUMBER() OVER (PARTITION BY TITLE ORDER BY Salary DESC) as 'ROW_NUMBER',
	RANK() OVER (PARTITION BY TITLE  ORDER BY Salary DESC) as 'RANK',
	DENSE_RANK() OVER (PARTITION BY TITLE ORDER BY Salary DESC) as 'DENSE_RANK',
	PERCENT_RANK() OVER (PARTITION BY TITLE ORDER BY Salary DESC) as 'PERCENT_RANK'
FROM Northwind.dbo.Employees;
```

| EmployeeID | Name             | Title                    | Salary   | ROW_NUMBER | RANK | DENSE_RANK | PERCENT_RANK |
| ---------- | ---------------- | ------------------------ | -------- | ---------- | ---- | ---------- | ------------ |
| 2          | Fuller Andrew    | Vice President, Sales    | 90000.00 | 1          | 1    | 1          | 0.0          |
| 5          | Buchanan Steven  | Sales Manager            | 55000.00 | 2          | 2    | 2          | 0.125        |
| 8          | Callahan Laura   | Inside Sales Coordinator | 51000.00 | 3          | 3    | 3          | 0.25         |
| 1          | Davolio Nancy    | Sales Representative     | 48000.00 | 4          | 4    | 4          | 0.375        |
| 7          | King Robert      | Sales Representative     | 42000.00 | 5          | 5    | 5          | 0.5          |
| 4          | Peacock Margaret | Sales Representative     | 40000.00 | 6          | 6    | 6          | 0.625        |
| 9          | Dodsworth Anne   | Sales Representative     | 40000.00 | 7          | 6    | 6          | 0.625        |
| 3          | Leverling Janet  | Sales Representative     | 36000.00 | 8          | 8    | 7          | 0.875        |
| 6          | Suyama Michael   | Sales Representative     | 35000.00 | 9          | 9    | 8          | 1.0          |

| EmployeeID | Name             | Title                    | Salary   | ROW_NUMBER | RANK | DENSE_RANK | PERCENT_RANK |
| ---------- | ---------------- | ------------------------ | -------- | ---------- | ---- | ---------- | ------------ |
| 8          | Callahan Laura   | Inside Sales Coordinator | 51000.00 | 1          | 1    | 1          | 0.0          |
| 5          | Buchanan Steven  | Sales Manager            | 55000.00 | 1          | 1    | 1          | 0.0          |
| 1          | Davolio Nancy    | Sales Representative     | 48000.00 | 1          | 1    | 1          | 0.0          |
| 7          | King Robert      | Sales Representative     | 42000.00 | 2          | 2    | 2          | 0.2          |
| 4          | Peacock Margaret | Sales Representative     | 40000.00 | 3          | 3    | 3          | 0.4          |
| 9          | Dodsworth Anne   | Sales Representative     | 40000.00 | 4          | 3    | 3          | 0.4          |
| 3          | Leverling Janet  | Sales Representative     | 36000.00 | 5          | 5    | 4          | 0.8          |
| 6          | Suyama Michael   | Sales Representative     | 35000.00 | 6          | 6    | 5          | 1.0          |
| 2          | Fuller Andrew    | Vice President, Sales    | 90000.00 | 1          | 1    | 1          | 0.0          |

## 3.6 LAG LEAD

- `LAG` refer to previous line
- `LAG(...,2)` refer to the line before the previous line
- `LEAD` refer to next line
- `LEAD(...,2)` refer to the line after the next line

```SQL
-- Calculate for each employee the percentage  difference between this employee and the employee preceding him
SELECT 
	EmployeeID, 
	LastName + ' ' + FirstName as 'Name',
	Salary,
	FORMAT(
		(Salary - LAG(Salary) OVER (ORDER BY Salary DESC)) 
		/
		Salary 
	, 'P') as EarnLessThanPreceding
FROM Northwind.dbo.Employees;

-- Calculate for each employee the percentage  difference between this employee and the employee following him
SELECT 
	EmployeeID, 
	LastName + ' ' + FirstName as 'Name',
	Salary,
	FORMAT(
		(Salary - LEAD(Salary) OVER (ORDER BY Salary DESC)) 
		/
		Salary 
	, 'P') as EarnMoreThanFollowing
FROM Northwind.dbo.Employees;


WITH amountSoldByYearAndProduct (ProductID, orderYear, amountPerYear, amountPreviousYear) AS (
	SELECT 
	od.ProductID,
	YEAR(O.OrderDate),
	SUM(od.Quantity),
	LAG(sum(od.Quantity), 1) OVER (
		PARTITION BY ProductID ORDER BY YEAR(O.OrderDate)
    ) as cummulativeAmount
	FROM Northwind.dbo.OrderDetails od
	JOIN Northwind.dbo.Orders o
	ON od.OrderID = o.OrderID
	GROUP BY od.ProductID, YEAR(O.OrderDate)
)

SELECT 
	ProductID,
	orderYear,
	amountPerYear,
	amountPreviousYear,
	ISNULL(
		FORMAT (
	    	(1.0 * (amountPerYear - amountPreviousYear))  / amountPerYear
	   , 'P')
	, "N/A") as differenceToPreviousYear
FROM amountSoldByYearAndProduct
ORDER BY ProductID, orderYear

```

## 3.7 Exercices

```SQL


-- Exercises

-- Create the following overview in which each customer gets a sequential number. 
-- The number is reset when the country changes
/*
country		rownum	CompanyName
Argentina	1		Cactus Comidas para llevar
Argentina	2		Oc�ano Atl�ntico Ltda.
Argentina	3		Rancho grande
Austria		1		Ernst Handel
Austria		2		Piccolo und mehr
Belgium		1		Maison Dewey
Belgium		2		Supr�mes d�lices
Brazil		1		Com�rcio Mineiro
Brazil		2		Familia Arquibaldo
Brazil		3		Gourmet Lanchonetes
Brazil		4		Hanari Carnes
...
*/

SELECT 
	Country,
	ROW_NUMBER() OVER (PARTITION BY Country ORDER BY CompanyName ASC) as 'ROW_NUMBER',
	CompanyName
FROM Customers;

-- Step 1: First create an overview that shows for each productid the amount sold per year
SELECT od.productid, YEAR(o.orderdate) As OrderYear, SUM(quantity) As AmountSoldPerYear
FROM orders o JOIN OrderDetails od ON o.orderid = od.orderid
GROUP BY od.productid, YEAR(o.orderdate)
ORDER BY od.productid, YEAR(o.orderdate)


-- Step 2: Now create an overview that shows for each productid the amount 
-- sold per year and for the previous year.
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


SELECT 
	od.ProductID, 
	YEAR(o.OrderDate) as orderYear,
	SUM(od.Quantity) as amountSoldInYear,
	ISNULL(LAG(SUM(od.Quantity),1) OVER (
		PARTITION BY od.ProductID
		ORDER BY YEAR(o.OrderDate)
	), 0) as amountPreviousYear
FROM Orders o 
JOIN OrderDetails od 
ON o.OrderID = od.OrderID
GROUP BY od.ProductID, YEAR(o.OrderDate);




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

WITH QuatitiySoldPerYearPerProduct(pid, orderYear, amountSoldInYear, amountSoldPreviousYear) AS (
	SELECT 
	od.ProductID, 
	YEAR(o.OrderDate),
	SUM(od.Quantity) as amountSoldInYear,
	LAG(SUM(od.Quantity),1) OVER (
		PARTITION BY od.ProductID
		ORDER BY YEAR(o.OrderDate)
	)
	FROM Orders o 
	JOIN OrderDetails od 
	ON o.OrderID = od.OrderID
	GROUP BY od.ProductID, YEAR(o.OrderDate)
)

SELECT 
	*,
	ISNULL(
		FORMAT(
			(
				(amountSoldInYear * 1.0 - amountSoldPreviousYear * 1.0) 
				/ 
				amountSoldPreviousYear
			), 
		'p')
	, 'N/A') as SalesIncrease
FROM QuatitiySoldPerYearPerProduct t1

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


SELECT 
	e.EmployeeID, 
	YEAR(o.OrderDate) as orderYear,
	SUM(od.Quantity * od.UnitPrice) as totalRevenue
FROM Employees e
JOIN Orders o 
ON e.EmployeeID = o.EmployeeID
JOIN OrderDetails od 
ON o.OrderID = od.OrderID
GROUP BY e.EmployeeID, YEAR(o.OrderDate)
ORDER BY e.EmployeeID, YEAR(o.OrderDate);

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

SELECT 
	e.EmployeeID, 
	YEAR(o.OrderDate) as orderYear,
	SUM(od.Quantity * od.UnitPrice) as totalRevenue,
	RANK() OVER (PARTITION BY YEAR(o.OrderDate) ORDER BY SUM(od.Quantity * od.UnitPrice) DESC)  as 'RANK'
FROM Employees e
JOIN Orders o 
ON e.EmployeeID = o.EmployeeID
JOIN OrderDetails od 
ON o.OrderID = od.OrderID
GROUP BY e.EmployeeID, YEAR(o.OrderDate)
ORDER BY YEAR(o.OrderDate), 'RANK';


-- Step 3:	Imagine there is a bonussystem for all the employees: the best employee gets 10 000EUR bonus, the second one 5000 EUR, the third one 2500 EUR, �

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

SELECT 
	e.EmployeeID, 
	YEAR(o.OrderDate) as orderYear,
	SUM(od.Quantity * od.UnitPrice) as totalRevenue,
	RANK() OVER (PARTITION BY YEAR(o.OrderDate) ORDER BY SUM(od.Quantity * od.UnitPrice) DESC)  as 'RANK',
	ROUND(
		(10000) / (RANK() OVER (PARTITION BY YEAR(o.OrderDate) ORDER BY SUM(od.Quantity * od.UnitPrice) DESC)) * 1.0,
		2)  as 'BONUS'
FROM Employees e
JOIN Orders o 
ON e.EmployeeID = o.EmployeeID
JOIN OrderDetails od 
ON o.OrderID = od.OrderID
GROUP BY e.EmployeeID, YEAR(o.OrderDate)
ORDER BY YEAR(o.OrderDate), 'BONUS' DESC;


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

WITH RevenuePerYearAndMonth(orderYear, orderMonth, totalRevenue) AS (
	SELECT 
		YEAR(o.OrderDate) as orderYear,
		MONTH(o.OrderDate) as orderMonth,
		SUM(od.Quantity * od.UnitPrice) as totalRevenue
	FROM Orders o 
	JOIN OrderDetails od 
	ON o.OrderID = od.OrderID
	GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
)

-- Step 2: Add an extra column for each row with the revenue of the previous month
SELECT 
	*, 
	LAG(totalRevenue) OVER (ORDER BY orderYear, orderMonth) 
FROM RevenuePerYearAndMonth;

-- Step 3: Calculate the percentage difference between this month and the previous month

SELECT 
	*, 
	LAG(totalRevenue) OVER (ORDER BY orderYear, orderMonth),
	FORMAT(
		(totalRevenue - (LAG(totalRevenue) OVER (ORDER BY orderYear, orderMonth))) /  (LAG(totalRevenue) OVER (ORDER BY orderYear, orderMonth))
		, 'P'
	)
FROM RevenuePerYearAndMonth
```

```SQL
-- 1. recalulate the total_cases column
-- calculate the difference between the original total_cases and your calculation
-- Show only the lines where the original column is wrong
-- Order by country and report_date

/*
country	report_date						new_cases	total_cases	total_cases_calculated
China	2020-01-23 00:00:00.0000000		93			641			93
China	2020-01-24 00:00:00.0000000		277			918			370
China	2020-01-25 00:00:00.0000000		483			1401		853
China	2020-01-26 00:00:00.0000000		666			2067		1519
China	2020-01-27 00:00:00.0000000		802			2869		2321
China	2020-01-28 00:00:00.0000000		2632		5501		4953
China	2020-01-29 00:00:00.0000000		576			6077		5529
China	2020-01-30 00:00:00.0000000		2054		8131		7583
...

Countries = China / France / Japan / South Korea / Taiwan / Thailand / Turkey / United States
*/

SELECT 
	country,
	report_date, 
	new_cases,
	total_cases,
	SUM(new_cases) OVER (PARTITION BY country ORDER BY report_date RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS 'rollingSum'
FROM 
	Corona.dbo.CovidData cd
WHERE country in ('China','France','Japan','South Korea','Taiwan','Thailand','Turkey','United States')
ORDER BY country;

-- 2. As can be seen from the results of the previous question, 
-- when there was a mistake at the beginning, it seems like an awful lot of times 
-- the number of total_cases is calculated wrong
-- Therefor, try to find the rows where the number between total_cases and
-- total_cases of the previous line isn't the number of new_cases
-- If new_cases is NULL, replace new_cases by 0.
-- How often was there a mistake?


WITH TotalCasesByCountryByDayPlusPreviousDay(country, report_date,  new_cases, total_cases, total_cases_previous) AS
(
	SELECT  
		country, report_date,  new_cases, total_cases,
		LAG(total_cases) OVER (PARTITION BY country ORDER BY report_date)
	FROM 
		Corona.dbo.CovidData cd
	WHERE country in ('China','France','Japan','South Korea','Taiwan','Thailand','Turkey','United States')
)

SELECT * FROM TotalCasesByCountryByDayPlusPreviousDay WHERE total_cases_previous + ISNULL(new_cases, 0)  <> total_cases ORDER BY country;
/*
country	report_date					new_cases	total_cases	total_cases_previous_day
France	2021-05-20 00:00:00.0000000	NULL		5629921			5978761
Turkey	2020-12-10 00:00:00.0000000	NULL		1748567			925342
*/

-- 3. We want to investigate the height of the waves in some countries
-- You can only compare countries if you take into account their population. 

-- Part 1
-- Show for Belgium, France and the Netherlands a ranking (per country) 
-- of the days with the most new cases per 100.000 inhabitants
-- show only the top 5 days per country

/*

report_date					country	cases_per_100000	rank_new_cases
2020-10-29 00:00:00.0000000	Belgium	205.642307038295	1
2020-10-28 00:00:00.0000000	Belgium	180.943910310690	2
2020-10-30 00:00:00.0000000	Belgium	172.415957107146	3
2020-10-24 00:00:00.0000000	Belgium	152.239438791905	4
2020-10-23 00:00:00.0000000	Belgium	151.027300282127	5
2021-04-11 00:00:00.0000000	France	174.503525540451	1
2020-11-02 00:00:00.0000000	France	157.022387475293	2
2021-04-08 00:00:00.0000000	France	143.615889414655	3
2020-11-07 00:00:00.0000000	France	128.255695456462	4
2021-04-04 00:00:00.0000000	France	119.345658105497	5
2020-12-20 00:00:00.0000000	Netherlands	76.119073243295	1
2020-12-17 00:00:00.0000000	Netherlands	74.948637677054	2
2020-12-19 00:00:00.0000000	Netherlands	71.524676916110	3
2020-12-18 00:00:00.0000000	Netherlands	70.016503723790	4
2020-12-24 00:00:00.0000000	Netherlands	67.495117653231	5

*/

WITH casesByInhabitants (report_date, country,new_cases ,cases_per_100000, rank_new_cases) AS (
	SELECT 
		cd.report_date, 
		cd.country, 
		cd.new_cases,
		(cd.new_cases * 100000.0 / (c.population))  as cases_per_100000,
		RANK() OVER (PARTITION BY c.country ORDER BY new_cases DESC) 
	FROM Corona.dbo.CovidData cd
	JOIN Corona.dbo.Countries c
	ON cd.country = c.country
	WHERE cd.country in ('Belgium','France','Netherlands')
)


SELECT *
FROM casesByInhabitants
WHERE rank_new_cases <= 5
ORDER BY country, rank_new_cases ASC;

-- Part 2
-- Give the top 10 of countries with more than 1.000.000 inhabitants with the highest number new cases per 100.000 inhabitants

/*

country		max_cases_per_100000	rank_max_cases_per_100000
Botswana	355.825866413041		1
Kazakhstan	348.097637278271		2
Sweden		319.729248331645		3
Israel		253.601456965456		4
Switzerland	251.574953754772		5
Mongolia	222.089928098611		6
Kosovo		220.253376752791		7
Uruguay		209.144393128334		8
Belgium		205.642307038295		9
Spain		200.709330416756		10

*/

--SELECT 
--	cd.report_date, 
--	cd.country, 
--	cd.new_cases,
--	ISNULL((cd.new_cases * 100000.0 / (c.population)), 0)  as cases_per_100000,
--	RANK() OVER (ORDER BY cases_per_100000 DESC) as RANK
--FROM Corona.dbo.CovidData cd
--JOIN Corona.dbo.Countries c
--ON cd.country = c.country
--WHERE c.population > 1000000
--ORDER BY cases_per_100000 DESC



WITH casesByInhabitants (report_date, country,new_cases ,cases_per_100000) AS (
	SELECT 
		cd.report_date, 
		cd.country, 
		cd.new_cases,
		ISNULL((cd.new_cases * 100000.0 / (c.population)), 0)  as cases_per_100000
	FROM Corona.dbo.CovidData cd
	JOIN Corona.dbo.Countries c
	ON cd.country = c.country
	WHERE c.population > 1000000
)


SELECT TOP(10) *, RANK() OVER (ORDER BY cases_per_100000 DESC) as rank_new_cases
FROM casesByInhabitants
ORDER BY rank_new_cases ASC;


-- 4. 
-- Make a ranking (high to low) of countries for the total number of deaths until now relative to the number of inhabitants. 
-- Show the rank number (1,2,3, ...), the country, relative number of deaths

/*

country						relative_number_of_deaths	rank_deaths
Peru						0.005972						1
Bosnia and Herzegovina		0.003193						2
North Macedonia				0.003157						3
Hungary						0.003129						4
Montenegro					0.003012						5
Bulgaria					0.002965						6
Czechia						0.002839						7
Brazil						0.002776						8
San Marino					0.002646						9
Argentina					0.002518						10
Colombia					0.002459						11
Slovakia					0.002306						12
Paraguay					0.002235						13
Georgia						0.002207						14
Belgium						0.002196						15

*/


WITH totalDeathsByCountry (country, total_deaths) AS (
	SELECT 
		cd.country, 
		SUM(cd.new_deaths) as total_deaths
	FROM Corona.dbo.CovidData cd
	JOIN Corona.dbo.Countries c
	ON cd.country = c.country
	GROUP BY cd.country
),

relativeDeathsByCountry (country, relative_number_of_deaths) AS (
	SELECT 
		d.country,
		((d.total_deaths * 1.0) / c.population) as relative_number_of_deaths
	FROM totalDeathsByCountry d
	JOIN Corona.dbo.Countries c
	ON c.country = d.country
)

SELECT 
	TOP(15)
	*,
	RANK() OVER (ORDER BY relative_number_of_deaths DESC) as rank_deaths
FROM relativeDeathsByCountry
WHERE relative_number_of_deaths IS NOT NULL
ORDER BY rank_deaths ASC


-- 5.
-- In the press conferences, Sciensano always gives updates on the 
-- weekly average instead of the absolute numbers, to eliminate weekend, ... effects
-- 5.1 Calculate for each day the weekly average of the number of new_cases and new_deaths in Belgium
-- 5.2 Calculate for each day the relative difference with the previous day in Belgium for the weekly average number of new cases
-- 5.3 Give the day with the highest relative difference of weekly average number of new cases in Belgium
-- after 2020-04-01

/*

report_date						new_cases	total_cases	new_deaths	weekly_avg_new_cases	weekly_avg_new_deaths	weekly_avg_new_cases_previous	relative difference
2020-06-23 00:00:00.0000000		260			60810		17			93.571428				7.142857				64.285714						0.312977

*/

WITH cte1 (
		report_date, 
		new_cases,
		total_cases,
		new_deaths,
		weekly_avg_new_cases,
		weekly_avg_new_deaths
) AS (
	SELECT 
		report_date, 
		new_cases,
		total_cases,
		new_deaths,
		AVG(new_cases * 1.0) OVER (ORDER BY report_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),
		AVG(new_deaths * 1.0) OVER (ORDER BY report_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
	FROM Corona.dbo.CovidData
	WHERE country = 'Belgium'
),

cte2 AS (
	SELECT 
		*,
		LAG(weekly_avg_new_cases) OVER (ORDER BY report_date) as weekly_avg_new_cases_previous
	FROM cte1
)

SELECT 
	* , (
	weekly_avg_new_cases - weekly_avg_new_cases_previous) / weekly_avg_new_cases As 'relative difference'
FROM cte2
WHERE 
	weekly_avg_new_cases <> 0 
	and report_date > '2020-04-01'
ORDER BY report_date DESC



-- 6
-- The main reason for the lockdowns was to prevent the hospital system from collapsing
-- (i.e. too much patients on IC)
-- Give those weeks for which the number of hospitalized patients in Belgium doubled compared to the week before

-- Step 1: Add 2 extra columns with the weeknumber and year of each date. Use DATEPART(WEEK,report_date) for the weeknumber
-- Step 2: Calculate the average number of hosp_patients during that week
-- Step 3: Calculate the relative difference between each 2 weeks
-- Step 4: Give those weeks for which the number of hosp_patients rose with 50%

/*
report_week	report_year	avg_number_hosp_patients	avg_number_hosp_patients_previous_week	relative_change
13			2020			2759					729										2.78463648834019204
14			2020			5161					2759									0.87060529177238129
39			2020			546						351										0.55555555555555555
42			2020			1789					1052									0.70057034220532319
43			2020			3376					1789									0.88708775852431525
44			2020			5813					3376									0.72186018957345971
*/

WITH cte1 AS (
	SELECT 
		YEAR(report_date) as report_year,
		DATEPART(WEEK,report_date) as  report_week,
		*
	FROM Corona.dbo.CovidData
	WHERE country = 'Belgium'
	AND new_cases > 0
)

,cte2 AS (
	SELECT DISTINCT
		*,
		AVG(hosp_patients) OVER (PARTITION BY report_year, report_week ORDER BY report_year, report_week) as avg_number_hosp_patients
	FROM cte1
)

,cte3 AS (
	SELECT 
		*,
		LAG(avg_number_hosp_patients) OVER (ORDER BY report_year, report_week) as avg_number_hosp_patients_previous_week
	FROM cte2
)

SELECT 
	report_date,
	report_year,
	report_week,
	avg_number_hosp_patients,
	avg_number_hosp_patients_previous_week,
	(avg_number_hosp_patients - avg_number_hosp_patients_previous_week) * 1.0 / avg_number_hosp_patients_previous_week As relative_change
FROM cte3
WHERE avg_number_hosp_patients <> avg_number_hosp_patients_previous_week
ORDER BY report_date DESC
```
