
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

WITH cte1(country, report_date, new_cases, total_cases, total_cases_calculated)
AS
(SELECT country, report_date, new_cases, total_cases, 
SUM(new_cases) OVER (PARTITION BY country ORDER BY report_date) total_cases_calculated
FROM CovidData)

SELECT *
FROM cte1
WHERE total_cases != total_cases_calculated
ORDER BY country, report_date

-- 2. As can be seen from the results of the previous question, 
-- when there was a mistake at the beginning, it seems like an awful lot of times 
-- the number of total_cases is calculated wrong
-- Therefor, try to find the rows where the number between total_cases and
-- total_cases of the previous line isn't the number of new_cases
-- If new_cases is NULL, replace new_cases by 0.
-- How often was there a mistake?

/*
country	report_date					new_cases	total_cases	total_cases_previous_day
France	2021-05-20 00:00:00.0000000	NULL		5629921			5978761
Turkey	2020-12-10 00:00:00.0000000	NULL		1748567			925342
*/

WITH cte1(country, report_date, new_cases, total_cases, total_cases_previous_day)
AS
(SELECT country, report_date, new_cases, total_cases, 
LAG(total_cases) OVER (PARTITION BY country ORDER BY report_date)
FROM CovidData)

SELECT *
FROM cte1
WHERE total_cases_previous_day + ISNULL(new_cases,0) <> total_cases


-- 3. We want to investigate the height of the waves in some countries
-- You can only compare countries if you take into account there population. 

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

WITH cte1
AS
(SELECT report_date, cd.country, new_cases * 100000.0 /population AS cases_per_100000,
RANK() over (partition by cd.country order by new_cases desc) rank_new_cases
FROM covidData cd JOIN countries c ON cd.country = c.country
WHERE cd.country IN ('Belgium','France','Netherlands'))

SELECT *
FROM cte1
WHERE rank_new_cases <= 5
ORDER BY country, rank_new_cases

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


WITH cte1
AS
(SELECT report_date, cd.country, new_cases * 100000.0 /population AS cases_per_100000
FROM covidData cd JOIN countries c ON cd.country = c.country
WHERE population > 1000000),

cte2
AS 
(SELECT country, MAX(cases_per_100000) As max_cases_per_100000
FROM cte1
GROUP BY country),

cte3 AS
(SELECT *,
RANK() over (order by max_cases_per_100000 desc) rank_max_cases_per_100000
FROM cte2)

SELECT *
FROM cte3
WHERE rank_max_cases_per_100000 <= 10



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


WITH cte1(country, relative_number_of_deaths)
AS
(SELECT cd.country, SUM(new_deaths * 1.0) / population 
FROM CovidData cd JOIN countries c ON cd.country = c.country
GROUP BY cd.country, population)

SELECT *, RANK() OVER (ORDER BY relative_number_of_deaths DESC) As rank_deaths
FROM cte1


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

WITH cte1
AS
(SELECT report_date, new_cases, total_cases, new_deaths,
AVG(new_cases * 1.0) OVER (ORDER BY report_date ROWS between 6 preceding and current row) AS weekly_avg_new_cases,
AVG(new_deaths * 1.0) OVER (ORDER BY report_date ROWS between 6 preceding and current row) AS weekly_avg_new_deaths
FROM coviddata 
WHERE country = 'Belgium'),

cte2
AS
(SELECT *,
LAG(weekly_avg_new_cases) OVER (ORDER BY report_date) As weekly_avg_new_cases_previous
FROM cte1)

SELECT * , (weekly_avg_new_cases - weekly_avg_new_cases_previous) / weekly_avg_new_cases As 'relative difference'
FROM cte2
WHERE weekly_avg_new_cases <> 0 and report_date > '2020-04-01'
ORDER BY 'relative difference' DESC



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

WITH cte1
AS
(SELECT report_date, hosp_patients,  DATEPART(WEEK,report_date) As report_week, YEAR(report_date) As report_year
FROM coviddata
WHERE country = 'Belgium'),

cte2
AS
(SELECT report_week, report_year, AVG(hosp_patients) As avg_number_hosp_patients
FROM cte1
GROUP BY report_week, report_year),

cte3
AS
(SELECT *, 
LAG(avg_number_hosp_patients) OVER (ORDER BY report_year, report_week) AS avg_number_hosp_patients_previous_week
FROM cte2)

SELECT  *, (avg_number_hosp_patients - avg_number_hosp_patients_previous_week) * 1.0 / avg_number_hosp_patients_previous_week As relative_change
FROM cte3
WHERE (avg_number_hosp_patients - avg_number_hosp_patients_previous_week) * 1.0 / avg_number_hosp_patients_previous_week > 0.5






SELECT min(report_date) FROM coviddata where country = 'Belgium'

SELECT week(report_date), MONT
