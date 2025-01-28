SELECT COUNT(*) FROM covidvaccinationssheet;

SELECT *
FROM coviddeathsheet
ORDER BY 3,4;

SELECT *
FROM covidvaccinationssheet;

-- SELECT *
-- FROM covidvaccinationssheet
-- ORDER BY 3,4;

-- Select data to be leveraged
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeathsheet
ORDER BY 1,2;

-- Looking at total cases vs total deaths 
-- Shows likelihood of dying if you contract Covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM coviddeathsheet
WHERE location like '%states%'
AND continent is NOT NULL
ORDER BY 1,2;

-- Looking at total cases vs Population 
-- Shows what percentage of population got Covid
SELECT location, date, total_cases, population, (total_cases/population)*100 as PercentagePopulationInfected
FROM coviddeathsheet
WHERE location like '%states%'
AND continent is NOT NULL
ORDER BY 1,2;

-- Looking at countries with highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentagePopulationInfected
FROM coviddeathsheet
-- WHERE location like '%states%'
WHERE continent is NOT NULL
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC;

-- Select Countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM coviddeathsheet
-- WHERE location like '%states%'
WHERE continent is NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- BREAK DOWN BY CONTINENT

-- Showing Continents with Highest Death count
SELECT continent, MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM coviddeathsheet
-- WHERE location like '%states%'
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS SIGNED)) AS total_deaths, SUM(CAST(new_deaths AS SIGNED))/SUM(new_cases) * 100 AS GlobalDeathPercentage
FROM coviddeathsheet
-- WHERE location like '%states%'
WHERE continent is NOT NULL
GROUP BY date
ORDER BY 1,2;

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS SIGNED)) AS total_deaths, SUM(CAST(new_deaths AS SIGNED))/SUM(new_cases) * 100 AS GlobalDeathPercentage
FROM coviddeathsheet
-- WHERE location like '%states%'
WHERE continent is NOT NULL
-- GROUP BY date
ORDER BY 1,2;

-- Looking at total population vs vaccination

UPDATE covidvaccinationssheet
SET date = STR_TO_DATE(REPLACE(date, '/', '-'), '%m-%d-%Y');

SELECT *
FROM covidvaccinationssheet vac;

SELECT *
FROM covidvaccinationssheet vac;
-- WHERE continent = 'Europe';

-- SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount
FROM coviddeathsheet dea
JOIN covidvaccinationssheet vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 1,2,3;

-- Use CTE to determine rate of vaccination

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingVaccinationCount) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount
FROM coviddeathsheet dea
JOIN covidvaccinationssheet vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent is NOT NULL
-- ORDER BY 1,2,3
)
SELECT *, (RollingVaccinationCount/population) * 100
FROM PopvsVac;

-- Use Temp table to determine rate of vaccination
DROP TABLE if exists PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount
FROM coviddeathsheet dea
JOIN covidvaccinationssheet vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;
    
SELECT continent, location, date, population, new_vaccinations, RollingVaccinationCount, (RollingVaccinationCount / population) * 100 AS PercentVaccinated
FROM PercentPopulationVaccinated;

-- Create view for PercentPopulationVaccinated visualization
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount
FROM coviddeathsheet dea
JOIN covidvaccinationssheet vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;
    
SELECT *
FROM PercentPopulationVaccinated;
