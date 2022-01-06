-- Always give new columns an appropriate name 

-- How many countries can be found in the dataset? 
SELECT COUNT(country) 
FROM Countries

-- Give the total population per continent
SELECT continent, SUM(CONVERT(bigint, population)) As TotalPopulation
FROM Countries
GROUP BY continent

SELECT continent, SUM(1.0 * population) As TotalPopulation
FROM Countries
GROUP BY continent

-- Which country with more than 1 000 000 inhabitants, 
-- has the highest life expectancy?
SELECT TOP 1 country, continent, life_expectancy
FROM Countries
WHERE population > 1000000
ORDER BY life_expectancy DESC

-- Calculate the average life_expectancy for each continent
-- Take into account the population for each country
SELECT continent, SUM(population * 1.0 * life_expectancy) / SUM(1.0 * population) As 'Averae life expectancy'
FROM countries
GROUP BY continent

-- Give the country with the highest number of Corona deaths
SELECT country, SUM(new_deaths) As TotalDeaths
FROM CovidData
GROUP BY country
ORDER BY 2 DESC

-- On which day was 50% of the Belgians fully vaccinated?
SELECT MIN(report_date)
FROM CovidData  cd INNER JOIN Countries c ON c.country = cd.country
WHERE cd.country = 'Belgium' AND people_fully_vaccinated >= population / 2

-- On which day the first Belgian received a vaccin?
SELECT MIN(report_date)
FROM CovidData
WHERE total_vaccinations IS NOT NULL AND Country='Belgium'

-- On which day the first Corona death was reported in Europe?
SELECT MIN(report_date)
FROM CovidData  cd INNER JOIN Countries c ON c.country = cd.country
WHERE new_deaths IS NOT NULL AND continent = 'Europe'

-- What is the estimated total amount of smokers in Belgium?
-- Subtract 2 000 000 children from the total Belgian population
SELECT (female_smokers + male_smokers) / 200 * (population - 2000000)
FROM Countries 
WHERE country = 'Belgium'

-- The first lockdown in Belgium started on 18 march 2020. Give all the data until 21 days afterwards
-- to be able to check if the lockdown had any effect.
SELECT *
FROM CovidData
WHERE country = 'Belgium' AND report_date BETWEEN '2020/03/18' 
AND DATEADD(day, 21,'2020/03/18')

-- In which month (month + year) the number of deaths was the highest in Belgium?
SELECT YEAR(report_date) As 'Reported year', MONTH(report_date) As 'Reported month', SUM(new_deaths) As 'Total number of deaths'
FROM CovidData
WHERE country = 'Belgium'
GROUP BY YEAR(report_date), MONTH(report_date)
ORDER BY 3 DESC











