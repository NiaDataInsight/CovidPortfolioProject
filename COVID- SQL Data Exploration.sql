Select *
From CovidDeaths
Where continent is not null 
order by 3,4

-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Where continent is not null
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths
Where location like 'italy'
and continent is not null 
order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths
Where location like 'italy'
order by 1,2

-- Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc

-- Countries with Highest Death Count per Population
Select Location, MAX(cast(Total_deaths as SIGNED)) as TotalDeathCount
From CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population
Select continent, MAX(cast(Total_deaths as SIGNED)) as TotalDeathCount
From CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS
-- New Cases & New Deaths in % by date
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as signed)) as total_deaths, SUM(cast(new_deaths as signed))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
where continent is not null 
Group By date
order by 1,2

-- New Cases & New Deaths in % total
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as signed)) as total_deaths, SUM(cast(new_deaths as signed))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
where continent is not null
order by 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
-- Joins on location and date

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
from coviddeaths as dea
join CovidVaccinations_PREP as vac
on dea.location = vac.location
and cast(dea.date as date) = cast(vac.date as date)
where dea.continent is not null
order by 2,3

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as signed))
		over(partition by dea.location
			order by dea.location, dea.date) as RollingPeopleVaccinated
from coviddeaths as dea
join CovidVaccinations_PREP as vac
on dea.location = vac.location
and cast(dea.date as date) = cast(vac.date as date)
where dea.continent is not null
order by 2,3

-- USE CTE

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as signed))
		over(partition by dea.location
			order by dea.location, dea.date) as RollingPeopleVaccinated
from coviddeaths as dea
join CovidVaccinations_PREP as vac
on dea.location = vac.location
and cast(dea.date as date) = cast(vac.date as date)
where dea.continent is not null
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

with PopvsVac (continent, location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as signed))
		over(partition by dea.location
			order by dea.location, dea.date) as RollingPeopleVaccinated
from coviddeaths as dea
join CovidVaccinations_PREP as vac
on dea.location = vac.location
and cast(dea.date as date) = cast(vac.date as date)
where dea.continent is not null
)
select * From PopvsVac

-- CTE to calculate vaccinated people vs Population in %

with PopvsVac (continent, location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as signed))
		over(partition by dea.location
			order by dea.location, dea.date) as RollingPeopleVaccinated
from coviddeaths as dea
join CovidVaccinations_PREP as vac
on dea.location = vac.location
and cast(dea.date as date) = cast(vac.date as date)
where dea.continent is not null
)
select *, (RollingPeopleVaccinated/Population)*100
from PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query
-- CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as signed))
		over(partition by dea.location
			order by dea.location, dea.date) as RollingPeopleVaccinated
from coviddeaths as dea
join CovidVaccinations_PREP as vac
on dea.location = vac.location
and cast(dea.date as date) = cast(vac.date as date)
where dea.continent is not null
)
select *, (RollingPeopleVaccinated/Population)*100
from PopvsVac AS PercentPopulationVaccinated
FROM
    PercentPopulationVaccinated;

-- TO DROP THE TABLE WE MADE ABOVE 
DROP TABLE IF EXISTS PercentPopulationVaccinated;

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM
    coviddeaths AS dea
JOIN CovidVaccinations_PREP AS vac
ON dea.location = vac.location AND CAST(dea.date AS DATE) = CAST(vac.date AS DATE)
WHERE
    dea.continent IS NOT NULL;


-- When views is created: refresh or select rows to see the visualization
-- you can also go to the main working area and select this new view as a table because it is permanent now
SELECT * FROM percentpopulationvaccinated;
