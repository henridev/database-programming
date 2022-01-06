-- 1. On which day(s) the highest number of new cases was reported in Belgium?
SELECT report_date, new_cases
FROM CovidData
WHERE country = 'Belgium' AND new_cases = (SELECT MAX(new_cases) FROM CovidData WHERE country = 'Belgium')

-- 2. On which day(s) the highest number of new deaths was reported for each country?
SELECT country, report_date, new_deaths
FROM CovidData cd
WHERE new_deaths = (SELECT MAX(new_deaths) FROM CovidData WHERE country = cd.country)

-- 3. Which country(ies) was(were) the first to start vaccinations?
SELECT country, report_date
FROM CovidData
WHERE total_vaccinations IS NOT NULL AND report_date = (SELECT MIN(report_date) FROM CovidData WHERE total_vaccinations IS NOT NULL)

-- 4. Give for each country the percentage of fully vaccinated people
-- based on the most recent data on the fully vaccinated people for that country
-- Order the results in a descending way
-- You could try to solve this taking into account that - for now - the number of fully vaccinated people is an always increasing number.
-- But once the vaccination campaign is done and old people are dying and new babies are born, it's possible this won't be the case any more.

SELECT cd.country, cd.people_fully_vaccinated * 1.0 / c.population
FROM CovidData  cd INNER JOIN Countries c ON c.country = cd.country
WHERE people_fully_vaccinated IS NOT NULL AND report_date = (SELECT MAX(report_date) FROM CovidData WHERE country = cd.country AND people_fully_vaccinated IS NOT NULL)
ORDER BY 2 DESC

SELECT cd.country, MAX(cd.people_fully_vaccinated * 1.0 / c.population)
FROM CovidData  cd INNER JOIN Countries c ON c.country = cd.country
GROUP BY  cd.country
ORDER BY 2 DESC

-- 5. Assume that all people in Belgium got fully vaccinated from elder to younger. 
-- We don't take into account people on priority lists like doctors, nurses, ...
-- On which day all Belgians of 70 or older were fully vaccinated?

SELECT MIN(report_date)
FROM CovidData
WHERE country = 'Belgium' AND people_fully_vaccinated >= (SELECT aged_70_older * population / 100 FROM Countries WHERE country = 'Belgium')

-- 6. Give an overview of the cumulative sum of Corona deaths for each country
-- Give country, report_date, new_deaths and the cumulative sum
-- Order by country and report_date
SELECT country, report_date, new_deaths,
(
	SELECT SUM(new_deaths) 
	FROM CovidData
	WHERE country = cd.country AND report_date <= cd.report_date
) As TotalDeaths
FROM CovidData cd
ORDER BY country, report_date;

-- 7. Give for each continent the countries in which the life_expectancy
-- is higher than the average life_expectancy of that continent

SELECT continent, country, life_expectancy
FROM countries c
WHERE life_expectancy > (SELECT avg(life_expectancy) FROM countries WHERE continent = c.continent GROUP BY continent)

-- 8. Which country(ies) have the highest value for median_age
SELECT country, median_age
FROM countries
WHERE median_age = (SELECT MAX(median_age) FROM countries)

