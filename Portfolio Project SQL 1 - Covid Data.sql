Select * from PortfolioProject1..CovidDeaths
Where continent is not null
order by 3,4
-- we specifically want entries where the continent field isnt null, because those are aggregate
-- values for things like North America as a whole, etc.


Select location, date, total_cases, new_cases, total_deaths, population 
from PortfolioProject1..CovidDeaths
Where continent is not null
order by 1,2

-- looking at total cases vs. total deaths
-- each day will have a % chance of how likely you are to die if you contracted covid at that time
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathpercent
from PortfolioProject1..CovidDeaths
Where continent is not null
order by 1,2

-- total cases vs. population
-- show us what % of the pop'n actually has covid
Select location, date, total_cases, population, (total_cases/population)*100 as casepercent
from PortfolioProject1..CovidDeaths
Where continent is not null
order by 1,2

-- which countries have the highest infection rates, as compared to their pop'ns?
Select location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population))*100 as casepercent
FROM PortfolioProject1..CovidDeaths
Where continent is not null
Group by location, population
order by casepercent desc

-- which are the countries with the highest death count relative to their pop'n?
-- note that total_deaths is a nvarchar, unlike total_cases which is a float, so a cast to int is needed
Select location, MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProject1..CovidDeaths
Where continent is not null
Group by location
order by total_death_count desc


-- which are the continents with the highest death rate?
-- sorted by their total death count
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject1..CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- try substituting in the sum of all new cases and new deaths, 
-- which should be equivalent to the max total # of cases seen for any given country
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, CONCAT(SUM(cast(new_deaths as int))/SUM(new_cases)*100, '%') as DeathPercentage
From PortfolioProject1..CovidDeaths
where continent is not null 
--Group By date
order by 1,2


-- what is the % of people who have been vaccinated (even if not fully) per country?
-- this doesn't do % yet because you can't call RollingVaccinatedCount in the same select declaration
-- needs some way of storing temporary values, some methods shown below
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccinatedCount
FROM PortfolioProject1..CovidDeaths dea
JOIN PortfolioProject1..CovidVaccinations vac
	ON dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- CTE method
WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingVaccinatedCount) 
as (
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccinatedCount 
FROM PortfolioProject1..CovidDeaths dea
JOIN PortfolioProject1..CovidVaccinations vac
	ON dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (RollingVaccinatedCount/population)*100 as PercentPopnVaxxed
from PopVsVac ORDER BY 2,3


-- Temp Table Method

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingVaccinatedCount numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccinatedCount 
FROM PortfolioProject1..CovidDeaths dea
JOIN PortfolioProject1..CovidVaccinations vac
	ON dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select *, (RollingVaccinatedCount/Population)*100
From #PercentPopulationVaccinated


-- This is the view version of the above
DROP VIEW if exists PercentPopulationVaccinated

-- if you encounter strange visibility errors for finding your views, like I did
USE PortfolioProject1
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccinatedCount 
FROM PortfolioProject1..CovidDeaths dea
JOIN PortfolioProject1..CovidVaccinations vac
	ON dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null
