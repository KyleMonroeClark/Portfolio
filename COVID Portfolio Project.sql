-- Covid 19 Data Exploration 

-- Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

-- Select all data from CovidDeaths where continent is not null
Select *
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 3,4

-- Select Data that we are going to be starting with
Select Location, date, 
       CAST(total_cases AS BIGINT) AS total_cases, 
       CAST(new_cases AS BIGINT) AS new_cases, 
       CAST(total_deaths AS BIGINT) AS total_deaths, 
       CAST(population AS BIGINT) AS population
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
Select Location, date, 
       CAST(total_cases AS BIGINT) AS total_cases,
       CAST(total_deaths AS BIGINT) AS total_deaths, 
       CASE 
           WHEN CAST(total_cases AS BIGINT) = 0 THEN 0
           ELSE (CAST(total_deaths AS BIGINT) / CAST(total_cases AS BIGINT)) * 100 
       END AS DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null 
order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
Select Location, date, 
       CAST(population AS BIGINT) AS population, 
       CAST(total_cases AS BIGINT) AS total_cases,  
       CASE 
           WHEN CAST(population AS BIGINT) = 0 THEN 0
           ELSE (CAST(total_cases AS BIGINT) / CAST(population AS BIGINT)) * 100 
       END AS PercentPopulationInfected
From PortfolioProject..CovidDeaths
order by 1,2

-- Countries with Highest Infection Rate compared to Population
Select Location, 
       CAST(population AS BIGINT) AS population, 
       MAX(CAST(total_cases AS BIGINT)) AS HighestInfectionCount,  
       MAX(CASE 
           WHEN CAST(population AS BIGINT) = 0 THEN 0
           ELSE (CAST(total_cases AS BIGINT) / CAST(population AS BIGINT)) * 100 
       END) AS PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, CAST(population AS BIGINT)
order by PercentPopulationInfected desc

-- Countries with Highest Death Count per Population
Select Location, 
       MAX(CAST(total_deaths AS BIGINT)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population
Select continent, 
       MAX(CAST(total_deaths AS BIGINT)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS
Select SUM(CAST(new_cases AS BIGINT)) AS total_cases, 
       SUM(CAST(new_deaths AS BIGINT)) AS total_deaths, 
       CASE 
           WHEN SUM(CAST(new_cases AS BIGINT)) = 0 THEN 0
           ELSE (SUM(CAST(new_deaths AS BIGINT)) / SUM(CAST(new_cases AS BIGINT))) * 100 
       END AS DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 
order by 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine
Select dea.continent, 
       dea.location, 
       dea.date, 
       CAST(dea.population AS BIGINT) AS population, 
       CAST(vac.new_vaccinations AS BIGINT) AS new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    On dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query
;With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) as (
    Select dea.continent, 
           dea.location, 
           dea.date, 
           CAST(dea.population AS BIGINT) AS population, 
           CAST(vac.new_vaccinations AS BIGINT) AS new_vaccinations,
           SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
    From PortfolioProject..CovidDeaths dea
    Join PortfolioProject..CovidVaccinations vac
        On dea.location = vac.location
        and dea.date = vac.date
    where dea.continent is not null
)
Select *, 
       CASE 
           WHEN Population = 0 THEN 0
           ELSE (RollingPeopleVaccinated / Population) * 100 
       END AS PercentPopulationVaccinated
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population BIGINT,
    New_vaccinations BIGINT,
    RollingPeopleVaccinated BIGINT
)

INSERT INTO #PercentPopulationVaccinated
Select dea.continent, 
       dea.location, 
       dea.date, 
       CAST(dea.population AS BIGINT) AS population, 
       CAST(vac.new_vaccinations AS BIGINT) AS new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    On dea.location = vac.location
    and dea.date = vac.date

Select *, 
       CASE 
           WHEN Population = 0 THEN 0
           ELSE (RollingPeopleVaccinated / Population) * 100 
       END AS PercentPopulationVaccinated
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
GO

CREATE VIEW PercentPopulationVaccinated AS
Select dea.continent, 
       dea.location, 
       dea.date, 
       CAST(dea.population AS BIGINT) AS population, 
       CAST(vac.new_vaccinations AS BIGINT) AS new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    On dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
