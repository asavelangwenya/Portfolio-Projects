SELECT * FROM [C:\USERS\ASAVE\DOCUMENTS\COVID_19.MDF]..CovidDeaths$
where continent is not null
ORDER BY 3,4 

SELECT * FROM [C:\USERS\ASAVE\DOCUMENTS\COVID_19.MDF]..CovidVaccinations$
where continent is not null
ORDER BY 3,4

---SELECT DATA THAT WE ARE GOING TO BE USING

SELECT Location, date,total_cases, new_cases, total_deaths, population
From [C:\USERS\ASAVE\DOCUMENTS\COVID_19.MDF]..CovidDeaths$
where continent is not null
ORDER BY 1, 2 

--- LOOKING AT TOTAL CASES VS  TOTAL DEATHS
-- SHOWS THE LIKELIHOOD OF DYING IF YOU CONTRACT COVID IN YOUR COUNTRY

SELECT Location, date,total_cases, total_deaths, Round(total_deaths/total_cases,2)*100 death_Percentage
From [C:\USERS\ASAVE\DOCUMENTS\COVID_19.MDF]..CovidDeaths$
WHERE LOCATION LIKE '%SOUTH AFRICA%' AND continent is not null
ORDER BY 1, 2 


-- Looking at Total Cases Vs Population
-- shows what percentage of population got covid

SELECT Location, date, Population, total_cases, Round(total_cases/population,0)*100 AS PercentPopulationInfected
From [C:\USERS\ASAVE\DOCUMENTS\COVID_19.MDF]..CovidDeaths$
WHERE LOCATION LIKE '%SOUTH AFRICA%' AND continent is not null
ORDER BY 1, 2

-- Countries that have the highest infection rated compared to populations
SELECT Location,Population, MAX(total_cases) AS HighestInfectionCount, ROUND((MAX(total_cases) / Population) * 100, 0) AS PercentPopulationInfected
From [C:\USERS\ASAVE\DOCUMENTS\COVID_19.MDF]..CovidDeaths$
where continent is not null
GROUP BY Location, population
ORDER BY PercentPopulationInfected Desc


-- Counteries with the highest death count per population

SELECT Location, MAX(Cast(Total_deaths as int)) AS TotalDeathCount
FROM [C:\USERS\ASAVE\DOCUMENTS\COVID_19.MDF]..CovidDeaths$
WHERE continent is not null
Group by Location
Order by TotalDeathCount Desc


-- BREAK THINGS DOWN BY CONTINENT
-- SHOWING THE CONTINENTS WITH THE HIGHEST DEATH COUNT

SELECT continent, MAX(Cast(Total_deaths as int)) AS TotalDeathCount
FROM [C:\USERS\ASAVE\DOCUMENTS\COVID_19.MDF]..CovidDeaths$
WHERE continent is not null
Group by continent
Order by TotalDeathCount Desc


-- GLOBAL NUMBERS
SELECT date, SUM(new_cases) as Total_Cases,
SUM(Cast(new_deaths as int)) as total_deaths, 
ROUND(SUM(Cast(new_deaths as int))/SUM(New_cases)*100,0) as DeathPercentage
FROM [C:\USERS\ASAVE\DOCUMENTS\COVID_19.MDF]..CovidDeaths$
WHERE CONTINENT IS NOT NULL
GROUP BY DATE
ORDER BY 1,2
 
 --- TOTAL ACROSS THE WORLD
 SELECT SUM(new_cases) as Total_Cases, 
 SUM(Cast(new_deaths as int)) as total_deaths, 
 ROUND(SUM(Cast(new_deaths as int))/SUM(New_cases)*100,0) as DeathPercentage
FROM [C:\USERS\ASAVE\DOCUMENTS\COVID_19.MDF]..CovidDeaths$
WHERE CONTINENT IS NOT NULL
ORDER BY 1,2



-- JOINING THE TWO TABLES
-- TO CHECK TOTAL POPULATION VS VACCINATION


SELECT CD.Continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CONVERT(INT,CV.new_vaccinations)) OVER (Partition by cd.Location order by cd.location,cd.date) AS RollingTotalNewVaccinations
FROM [C:\USERS\ASAVE\DOCUMENTS\COVID_19.MDF]..CovidDeaths$ CD
JOIN [C:\USERS\ASAVE\DOCUMENTS\COVID_19.MDF]..CovidVaccinations$ CV
	ON CD.location = CV.location
	and CD.date = CV.date
WHERE CD.continent is not null AND CV.new_vaccinations   is not null
ORDER BY 1,2,3



-- USING A CTE TO RETURN THE TOTAL OF VACCINATED PEOPLE IN  EACH COUNTRY(THE MASTER TOTAL OF THE ROLLING SUM)
 
 WITH Population_VS_Vaccination (Continent, Location, Date, Population, New_Vaccinations, RollingTotalNewVaccinations)
 as
 (
 SELECT CD.Continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CONVERT(INT,CV.new_vaccinations)) OVER (Partition by cd.Location order by cd.location,cd.date) AS RollingTotalNewVaccinations
FROM [C:\USERS\ASAVE\DOCUMENTS\COVID_19.MDF]..CovidDeaths$ CD
JOIN [C:\USERS\ASAVE\DOCUMENTS\COVID_19.MDF]..CovidVaccinations$ CV
	ON CD.location = CV.location
	and CD.date = CV.date
WHERE CD.continent is not null
--ORDER BY 1,2,3

)
SELECT *, ROUND(RollingTotalNewVaccinations/Population,0) * 100 AS PERCENTAGE  --Location,  -- SUM(RollingTotalNewVaccinations) AS MAXIMUM * --
FROM Population_VS_Vaccination
-- WHERE Location LIKE ('SOUTH AFRICA')
-- Group by Location


-- TEMP TABLE 

Drop Table if exists #PercentagePopulationVaccinated
Create Table #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric 
)

Insert into #PercentagePopulationVaccinated

SELECT CD.Continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CONVERT(INT,CV.new_vaccinations)) OVER (Partition by cd.Location order by cd.location,cd.date) AS RollingPeopleVaccinated
FROM [C:\USERS\ASAVE\DOCUMENTS\COVID_19.MDF]..CovidDeaths$ CD
JOIN [C:\USERS\ASAVE\DOCUMENTS\COVID_19.MDF]..CovidVaccinations$ CV
	ON CD.location = CV.location
	and CD.date = CV.date
--WHERE CD.continent is not null

SELECT *, (RollingPeopleVaccinated/Population) * 100   --Location,  -- SUM(RollingTotalNewVaccinations) AS MAXIMUM * --
FROM #PercentagePopulationVaccinated
 
-- CREATING A VIEW TO STORE DATA FOR VISUALIZATIONS
Create View PercentagePopulationVaccinated as
SELECT CD.Continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CONVERT(INT,CV.new_vaccinations)) OVER (Partition by cd.Location order by cd.location,cd.date) AS RollingPeopleVaccinated
FROM [C:\USERS\ASAVE\DOCUMENTS\COVID_19.MDF]..CovidDeaths$ CD
JOIN [C:\USERS\ASAVE\DOCUMENTS\COVID_19.MDF]..CovidVaccinations$ CV
	ON CD.location = CV.location
	and CD.date = CV.date
WHERE CD.continent is not null

