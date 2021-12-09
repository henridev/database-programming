
-- Give the names of all countries for which a larger percentage of people was vaccinated (not fully vaccinated) than for Belgium on 1 april 2021

WITH cte_1 (percentage_vaccinated_Belgium)
AS
(SELECT cd.people_vaccinated * 1.0 / c.population
FROM CovidData cd JOIN Countries c ON cd.country = c.country
WHERE report_date = '2021-04-01' and cd.country = 'Belgium')

SELECT cd.country, cd.people_vaccinated * 1.0 / c.population
FROM CovidData cd JOIN Countries c ON cd.country = c.country JOIN cte_1 ON cd.people_vaccinated * 1.0 / c.population > percentage_vaccinated_Belgium
WHERE report_date = '2021-04-01'

-- Give for each month the percentage of fully vaccinated people in Belgium at the end of the month

/*
12	2020	0.00%
1	2021	0.23%
2	2021	2.93%
3	2021	4.86%
4	2021	7.48%
5	2021	19.10%
6	2021	35.01%
7	2021	59.28%
8	2021	70.06%
*/

WITH cte_end_month([month], [year], endday)
AS
(SELECT month(report_date), year(report_date), MAX(report_date)
FROM covidData
WHERE country = 'Belgium'
GROUP BY month(report_date), year(report_date))

SELECT [month], [year], FORMAT(cd.people_fully_vaccinated * 1.0 / c.population, 'P')
FROM coviddata cd JOIN countries c ON cd.country = c.country
JOIN cte_end_month cte ON cte.endday = cd.report_date
WHERE cd.country = 'Belgium' AND cd.people_fully_vaccinated IS NOT NULL


-- What is the percentage of the total amount of new_cases that died in the following periods in Belgium
-- march 2020 - may 2020 / june 2020 - august 2020 / september 2020 - november 2020 / december 2020 - february 2021 / march 2021 - may 2021 / june 2021 - august 2021

/*
march 2020 - may 2020	16.22%
june 2020 - august 2020	1.59%
september 2020 - november 2020	1.37%
december 2020 - february 2021	2.80%
march 2021 - may 2021	0.99%
june 2021 - august 2021	0.35%
*/


WITH cte_1 (report_date, new_cases, new_deaths, periode)
AS
(SELECT report_date, new_cases, new_deaths,
CASE 
WHEN report_date BETWEEN '2020-03-01' AND '2020-05-31' THEN 'march 2020 - may 2020'
WHEN report_date BETWEEN '2020-06-01' AND '2020-08-31' THEN 'june 2020 - august 2020'
WHEN report_date BETWEEN '2020-09-01' AND '2020-11-30' THEN 'september 2020 - november 2020'
WHEN report_date BETWEEN '2020-12-01' AND '2021-02-28' THEN 'december 2020 - february 2021'
WHEN report_date BETWEEN '2021-03-01' AND '2021-05-31' THEN 'march 2021 - may 2021'
WHEN report_date BETWEEN '2021-06-01' AND '2021-08-31' THEN 'june 2021 - august 2021'
END AS periode
FROM CovidData
WHERE country = 'Belgium')

SELECT periode, FORMAT(SUM(new_deaths * 1.0) / SUM(new_cases * 1.0), 'P') As sterfpercentage
FROM cte_1
WHERE periode IS NOT NULL
GROUP BY periode
ORDER BY SUM(new_deaths * 1.0) / SUM(new_cases * 1.0) DESC

-- Which country(ies) was(were) the first to have 50% of the population fully vaccinated
WITH cte1(min_report_date)
AS
(SELECT MIN(report_date)
FROM Coviddata cd JOIN Countries c 
ON cd.country = c.country
WHERE cd.people_fully_vaccinated * 1.0 / c.population > 0.5)

SELECT cd.country
FROM Coviddata cd JOIN Countries c ON cd.country = c.country JOIN cte1 cte ON report_date = min_report_date
WHERE cd.people_fully_vaccinated * 1.0 / c.population > 0.5


