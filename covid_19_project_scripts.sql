select * 
from Covid_19_Project..CovidDeaths
order by 3,4

-- Select Data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from Covid_19_Project..CovidDeaths
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in your country
select location, date, total_cases, total_deaths, round((total_deaths*100/total_cases),2) as death_percentage
from Covid_19_Project..CovidDeaths
where location like '%states%'
order by 1,2

-- Looking at the Total Cases vs Population
select location, date, population, total_cases, round((total_cases*100/population),2) as percent_population_infected
from Covid_19_Project..CovidDeaths
--where location like '%states%'
order by 1,2

-- Looking at Countries with highest infection rate compared to Population
select 
	location, population, max(total_cases) as highest_infection_count, 
	max(round((total_cases*100/population),2)) as percent_population_infected
from Covid_19_Project..CovidDeaths
--where location like '%states%'
group by location, population
order by percent_population_infected desc

-- Breaking this down by continent


-- Showing continent with the highest death count per population

select 
	continent, max(cast(total_deaths as int)) as total_death_count
from Covid_19_Project..CovidDeaths
--where location like '%states%'
where continent IS NOT NULL
group by continent
order by total_death_count desc


-- Global Numbers per date
select 
	date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths,
	round((sum(cast(new_deaths as int))*100/sum(new_cases)),2) as death_percentatge
from Covid_19_Project..CovidDeaths
--where location like '%states%'
where continent IS NOT NULL
group by date
order by 1,2

-- Global Numbers 
select 
	sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths,
	round((sum(cast(new_deaths as int))*100/sum(new_cases)),2) as death_percentatge
from Covid_19_Project..CovidDeaths
--where location like '%states%'
where continent IS NOT NULL
order by 1,2


-- Looking at Total Population vs Vaccinations

select 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as int)) over(partition by dea.location order by dea.location, dea.date) 
		as rolling_people_vaccination
from 
	Covid_19_Project..CovidDeaths dea join Covid_19_Project..CovidVaccinations vac
		on dea.location = vac.location and 
		dea.date = vac.date
where dea.continent is not NULL
order by 2,3
		
--- Using a CTE
with pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_people_vaccination) 
as
(
	select 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as int)) over(partition by dea.location order by dea.location, dea.date) 
		as rolling_people_vaccination
	from 
		Covid_19_Project..CovidDeaths dea join Covid_19_Project..CovidVaccinations vac
		on dea.location = vac.location and 
		dea.date = vac.date
	where dea.continent is not NULL
	--order by 2,3
)
select 
	*, (rolling_people_vaccination/population)*100 as percentage_people_vaccinated
from pop_vs_vac


-- Temp Table

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
	continent nvarchar(255),
	Location nvarchar(255),
	Date datetime, 
	Population numeric,
	New_vaccinations numeric,
	rolling_people_vaccination numeric
)
insert into #PercentPopulationVaccinated
select 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as int)) over(partition by dea.location order by dea.location, dea.date) 
		as rolling_people_vaccination
	from 
		Covid_19_Project..CovidDeaths dea join Covid_19_Project..CovidVaccinations vac
		on dea.location = vac.location and 
		dea.date = vac.date
	where dea.continent is not NULL
	--order by 2,3

select 
	*, (rolling_people_vaccination/population)*100 as percentage_people_vaccinated
from #PercentPopulationVaccinated

-- Creating view to store data for later visualizations

create view PercentPopulationVaccinated as
select 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as int)) over(partition by dea.location order by dea.location, dea.date) 
		as rolling_people_vaccination
from 
	Covid_19_Project..CovidDeaths dea join Covid_19_Project..CovidVaccinations vac
		on dea.location = vac.location and 
		dea.date = vac.date
where dea.continent is not NULL
	--order by 2,3