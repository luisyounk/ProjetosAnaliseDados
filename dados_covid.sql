SELECT *
FROM `covid_dados.mortes_covid`
WHERE continent is not null
order by 3,4

SELECT *
FROM `covid_dados.vacinacao_covid`
WHERE continent is not null
order by 3,4

--Selecionar dados que irei utilizar

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM `covid_dados.mortes_covid`
WHERE continent is not null
ORDER BY 1,2


--Comparar o Total de Casos vs Total de Mortes
--Mostrar a probabilidade de morte se você contrair covid no seu País

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM `covid_dados.mortes_covid`
--WHERE location = 'Brazil' and continent is not null
ORDER BY 1,2

--Comparar o Total de Casos vs População
-- Mostrar a porcentagem da população que contraiu covid
SELECT location, date, total_cases, population, (total_cases/population)*100 as DeathPercentage
FROM `covid_dados.mortes_covid`
WHERE location = 'Brazil' and continent is not null
ORDER BY 1,2

--Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopulationInfected
FROM `covid_dados.mortes_covid`
--WHERE location = 'Brazil'
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected desc

-- Showing Countries with Highest Death Count per Population

SELECT location, MAX (total_deaths) as TotalDeathCount
FROM `covid_dados.mortes_covid`
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc


-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing continents with highest death count per population

SELECT continent, MAX (total_deaths) as TotalDeathCount
FROM `covid_dados.mortes_covid`
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc


-- GLOBAL NUMBERS

SELECT
    SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
    CASE
        WHEN SUM(new_deaths) = 0 OR SUM(new_cases) = 0 THEN NULL
        ELSE SUM(cast(new_deaths as int)) / NULLIF(SUM(new_deaths) / SUM(new_cases) * 100, 0)
    END as DeathPercentage
FROM
    `covid_dados.mortes_covid`
WHERE
    continent IS NOT NULL 
--GROUP BY date
ORDER BY
   1,2

-- Looking at Total Population vc Vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM (vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated,
 --(RollingPeopleVaccinaed/population)*100
FROM `covid_dados.mortes_covid` dea
JOIN `covid_dados.vacinacao_covid` vac
  ON dea.location = vac.location
  and dea.date = vac.date
WHERE dea.continent is not null 
ORDER BY 2,3


--USE CTE

WITH PopvsVac AS (
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
    FROM
        `covid_dados.mortes_covid` dea
    JOIN
        `covid_dados.vacinacao_covid` vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE
        dea.continent IS NOT NULL
    ORDER BY
        2, 3
)
SELECT
   *,
   CASE
       WHEN Population = 0 THEN NULL
       ELSE (rolling_people_vaccinated / NULLIF(Population, 0)) * 100
   END as VaccinationPercentage
FROM
    PopvsVac;

--TEMP TABLE


-- Criação da tabela temporária
CREATE TEMPORARY TABLE PercentPopularVaccinated AS
SELECT
    dea.continent AS Continent,
    dea.location AS Location,
    dea.date AS Date,
    dea.population AS Population,
    vac.new_vaccinations AS New_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM
    `covid_dados.mortes_covid` dea
JOIN
    `covid_dados.vacinacao_covid` vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
ORDER BY
    2, 3;

-- Seleção dos resultados com cálculo da porcentagem de vacinação
SELECT
    *,
    CASE
        WHEN Population = 0 THEN NULL
        ELSE (RollingPeopleVaccinated / NULLIF(Population, 0)) * 100
    END AS VaccinationPercentage
FROM
    PercentPopularVaccinated;

--Creating View to store date for later visualizations

CREATE VIEW covid_dados.percentepopulationvaccinated AS
SELECT
    dea.continent AS Continent,
    dea.location AS Location,
    dea.date AS Date,
    dea.population AS Population,
    vac.new_vaccinations AS New_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
    CASE
        WHEN dea.population = 0 THEN NULL
        ELSE (SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) / NULLIF(dea.population, 0)) * 100
    END AS VaccinationPercentage
FROM
    `covid_dados.mortes_covid` dea
JOIN
    `covid_dados.vacinacao_covid` vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL;
