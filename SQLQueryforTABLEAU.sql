Select *
From ProjectPortfolio..CovidDeaths

--Select (*)
--From ProjectPortfolio..CovidVaccinations

--Global Numbers as percentage
--1st visualization

SELECT SUM(CAST(new_cases AS bigint)) AS total_cases, 
       SUM(CAST(new_deaths AS bigint)) AS total_deaths, 
       SUM(CAST(new_deaths AS bigint)) / SUM(CAST(new_cases AS bigint)) * 100 AS DeathPercentage
FROM ProjectPortfolio..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1, 2;

--#2 Exclude 0
SELECT 
    SUM(CAST(new_cases AS bigint)) AS total_cases, 
    SUM(CAST(new_deaths AS bigint)) AS total_deaths, 
    CASE 
        WHEN SUM(CAST(new_cases AS bigint)) = 0 
        THEN 0 
        ELSE (SUM(CAST(new_deaths AS float)) / SUM(CAST(new_cases AS float))) * 100 
    END AS DeathPercentage 
FROM ProjectPortfolio..CovidDeaths 
WHERE continent IS NOT NULL 
ORDER BY 1, 2
OFFSET 0 ROWS 
FETCH NEXT 1 ROWS ONLY;




--2nd Visualization
--breaking down by cont.
SELECT continent, MAX(CAST(total_deaths as bigint)) AS TotalDeathCountWorld
FROM ProjectPortfolio..CovidDeaths
WHERE continent IN ('North America', 'South America', 'Asia', 'Europe', 'Africa', 'Oceania')
GROUP BY continent
ORDER BY TotalDeathCountWorld DESC;





-- Countries with highest infection rate (world)
----XX 3rd visualization
--SELECT Location, population,
----moved Max(total_cases) to remove extra column
--CASE WHEN MAX(total_cases) = 0 THEN 0 ELSE (CAST(MAX(total_cases) AS float) / NULLIF(CAST(population AS float), 0)) * 100 END AS InfectedRate
--FROM ProjectPortfolio..CovidDeaths
--WHERE continent IS NOT NULL
--GROUP BY Location, population
--ORDER BY InfectedRate DESC;

--diff #3
SELECT Location, CAST(Population AS BIGINT) as Population, date, MAX(total_cases) as HighestInfectionCount,  
Max(CASE WHEN CAST(Population AS BIGINT) = 0 THEN NULL ELSE (CAST(total_cases AS float)/CAST(Population AS float))*100 END) as PercentPopulationInfected
FROM ProjectPortfolio..CovidDeaths
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected DESC





-- Total cases vs population (PercentPopulationInfected)
--4th Visualization
SELECT Location, Population, date, 
       MAX(total_cases) AS HighestInfectionCount, 
       CASE WHEN SUM(CAST(Population AS float)) = 0 THEN 0 ELSE MAX(CAST(total_cases AS float)) / SUM(CAST(Population AS float)) * 100 END AS PercentPopulationInfected
FROM ProjectPortfolio..CovidDeaths
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected DESC;

--Edit of 4 to make sure there are only numbers in PercentPopulationInfected column ?? NEEDS WORK
SELECT Location, Population, date, 
       MAX(total_cases) AS HighestInfectionCount, 
       CASE 
           WHEN SUM(CAST(Population AS float)) = 0 THEN 0 
           WHEN ISNUMERIC(CAST(MAX(total_cases) AS float) / SUM(CAST(Population AS float))) = 0 THEN 0 
           ELSE MAX(CAST(total_cases AS float)) / SUM(CAST(Population AS float)) * 100 
       END AS PercentPopulationInfected
FROM ProjectPortfolio..CovidDeaths
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected DESC;
