Select *
From ProjectPortfolio..CovidDeaths
Where continent is not null
order by 3,4;

--Select (*)
--From ProjectPortfolio..CovidVaccinations
--Where continent is not null
--order by 3,4

--Selecting Data we are using

Select Location, date, total_cases, new_cases, total_deaths, population
From ProjectPortfolio..CovidDeaths
Where continent is not null
order by 1,2;

-- Total cases vs total deaths (Likelihood of death if contracted) in US
SELECT Location, date, total_cases, total_deaths, 
  CASE WHEN total_cases = 0 THEN 0 ELSE (CAST(total_deaths AS float) / NULLIF(CAST(total_cases AS float), 0)) * 100 END AS DeathPercentage
FROM ProjectPortfolio..CovidDeaths
WHERE location LIKE '%states%'
  AND continent IS NOT NULL 
ORDER BY 1, 2;

-- Total cases vs population (Percentage infected by covid) in US
SELECT Location, date, total_cases, population, 
  CASE WHEN population = 0 THEN 0 ELSE (CAST(total_cases AS float) / NULLIF(CAST(population AS float), 0)) * 100 END AS InfectedPercentage
FROM ProjectPortfolio..CovidDeaths
WHERE location LIKE '%states%'
  AND continent IS NOT NULL 
ORDER BY 1, 2;

-- Countries with highest infection rate (world)
SELECT Location, population,
--moved Max(total_cases) to remove extra column
CASE WHEN MAX(total_cases) = 0 THEN 0 ELSE (CAST(MAX(total_cases) AS float) / NULLIF(CAST(population AS float), 0)) * 100 END AS InfectedRate
FROM ProjectPortfolio..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY InfectedRate DESC;


---- Countries with highest death count per population (world)
--SELECT Location, population,
----moved Max(total_deaths) to remove extra column
--CASE WHEN MAX(total_deaths) = 0 THEN 0 ELSE (CAST(MAX(total_deaths) AS float) / NULLIF(CAST(population AS float), 0))END AS TotalDeathCount
--FROM ProjectPortfolio..CovidDeaths
--WHERE continent IS NOT NULL
--GROUP BY Location, population
--ORDER BY TotalDeathCount DESC;


--breaking down by cont.
SELECT continent, MAX(CAST(total_deaths as bigint)) AS TotalDeathCountWorld
FROM ProjectPortfolio..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCountWorld DESC;


--Global Numbers
SELECT SUM(CAST(new_cases AS bigint)) AS total_cases, 
       SUM(CAST(new_deaths AS bigint)) AS total_deaths, 
       SUM(CAST(new_deaths AS bigint)) / SUM(CAST(new_cases AS bigint)) * 100 AS DeathPercentage
FROM ProjectPortfolio..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1, 2;

----global numbers by day NEEDS WORK
--SELECT date, 
--       SUM(CONVERT(NUMERIC(18,0), new_cases)) AS TotalCases, 
--       SUM(CAST(new_deaths AS BIGINT)) AS TotalDeaths, 
--       SUM(CAST(new_deaths AS BIGINT))/SUM(CONVERT(NUMERIC(18,0), new_cases))*100 AS DeathPercentage
--FROM ProjectPortfolio..CovidDeaths
--WHERE continent IS NOT NULL
--GROUP BY date
--ORDER BY date

----Troubleshooting errors in (global numbers by day) query NEEDS WORK
--SELECT *
--FROM ProjectPortfolio..CovidDeaths
--WHERE continent IS NOT NULL
--AND TRY_CONVERT(NUMERIC(18,0), new_cases) IS NULL


-- Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM ProjectPortfolio..CovidDeaths dea
JOIN ProjectPortfolio..CovidVaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY dea.location, dea.date


--!!Using CTE (credited assistance to Kevin Lewis SWD @Oracle-- Come back to this one and re-do))
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT dea.continent, dea.location, dea.date, TRY_CONVERT(NUMERIC(18, 0), dea.population),
           vac.new_vaccinations,
           SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
    --, (RollingPeopleVaccinated/population)*100
    FROM ProjectPortfolio..CovidDeaths dea
    JOIN ProjectPortfolio..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL 
    --order by 2,3
)
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM PopvsVac


--using temp tables for calculations (Aw, dude, this is getting HARD) 
DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated (
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT
dea.continent,
dea.location,
dea.date,
dea.population,
CONVERT(BIGINT, vac.new_vaccinations),
SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM
ProjectPortfolio..CovidDeaths dea
JOIN ProjectPortfolio..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
ISNUMERIC(vac.new_vaccinations) = 1;

SELECT
*,
CASE
WHEN Population = 0 THEN 0
ELSE (RollingPeopleVaccinated / Population) * 100
END AS PercentPopulationVaccinated
FROM
#PercentPopulationVaccinated;

--Making View for visualization percent of pop vaccinated
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From ProjectPortfolio..CovidDeaths dea
Join ProjectPortfolio..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

--another view for vis global numbers of deaths

Create View GlobalNumbers as
SELECT SUM(CAST(new_cases AS bigint)) AS total_cases, 
       SUM(CAST(new_deaths AS bigint)) AS total_deaths, 
       SUM(CAST(new_deaths AS bigint)) / SUM(CAST(new_cases AS bigint)) * 100 AS DeathPercentage
FROM ProjectPortfolio..CovidDeaths
WHERE continent IS NOT NULL 
--ORDER BY 1, 2;

-- another VIEW Total cases vs total deaths (Likelihood of death if contracted) in US
create view USTotalcasesVStotaldeaths as
SELECT Location, date, total_cases, total_deaths, 
  CASE WHEN total_cases = 0 THEN 0 ELSE (CAST(total_deaths AS float) / NULLIF(CAST(total_cases AS float), 0)) * 100 END AS DeathPercentage
FROM ProjectPortfolio..CovidDeaths
WHERE location LIKE '%states%'
  AND continent IS NOT NULL 
--ORDER BY 1, 2;

-- another VIEW Total cases vs total deaths (Likelihood of death if contracted) in WORLD
create view WORLDTotalcasesVStotaldeaths as
SELECT Location, date, total_cases, total_deaths, 
  CASE WHEN total_cases = 0 THEN 0 ELSE (CAST(total_deaths AS float) / NULLIF(CAST(total_cases AS float), 0)) * 100 END AS DeathPercentage
FROM ProjectPortfolio..CovidDeaths
WHERE location  IS NOT NULL
  AND continent IS NOT NULL 
--ORDER BY 1, 2;

Select *
From PercentPopulationVaccinated