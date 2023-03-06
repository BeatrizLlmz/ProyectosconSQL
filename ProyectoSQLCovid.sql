/* Análisis de datos sobre muertes y vacunaciones de COVID-19 desde febrero de 2020 hasta abril de 2021 */

SELECT *
FROM Portafolio.dbo.CovidDeaths
WHERE continent IS NOT NULL

SELECT * 
FROM Portafolio.dbo.CovidVaccinations

-- Seleccionamos los datos que vamos a utilizar

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portafolio.dbo.CovidDeaths
ORDER BY 1, 2

-- Estandarizamos el formato de la fecha en la tabla de muertes por Covid

SELECT date, CONVERT(DATE, date)
from Portafolio.dbo.CovidDeaths

ALTER TABLE Portafolio.dbo.CovidDeaths
ADD dateconverted DATE

UPDATE Portafolio.dbo.CovidDeaths
SET dateconverted = CONVERT(DATE, date)

ALTER TABLE Portafolio.dbo.CovidDeaths
DROP COLUMN date

-- Estandarizamos la fecha también en la tabla de las vacunaciones

ALTER TABLE Portafolio.dbo.CovidVaccinations
ADD dateconverted DATE

UPDATE Portafolio.dbo.CovidVaccinations
SET dateconverted = CONVERT(DATE, date)

ALTER TABLE Portafolio.dbo.CovidVaccinations
DROP COLUMN date


-- Observación de los casos totales vs las muertes totales en España

SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) *100 AS DeathPercentage
FROM Portafolio.dbo.CovidDeaths
WHERE location = 'Spain'
ORDER BY 1, 2

-- Observación de los casos totales vs la población

SELECT location, date, population, total_cases, (total_cases / population) *100 AS PercentPopulationInfected
FROM Portafolio.dbo.CovidDeaths
 --WHERE location = 'Spain'
ORDER BY 1, 2

-- Países con mayor ratio de infección comparado con la población
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM Portafolio.dbo.CovidDeaths
 --WHERE location = 'Spain'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Realizamos la misma consulta que la anterior pero con fechas
SELECT location, date, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM Portafolio.dbo.CovidDeaths
GROUP BY location, population, date
ORDER BY PercentPopulationInfected DESC

-- Países con el mayor número de muertes por población

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM Portafolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Continentes con el mayor número de muertes por población

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM Portafolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Número total de muertes por continente

SELECT location, SUM(CAST(new_deaths AS int)) AS TotalDeathCount
FROM Portafolio.dbo.CovidDeaths
WHERE continent IS NULL
AND location NOT IN ('World', 'International', 'European Union')
GROUP BY location

-- Números globales

SELECT date, SUM(CAST(new_cases AS int)) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths,
             SUM(CAST(new_deaths AS int)) / SUM(CAST(new_cases AS int))*100 AS DeathPercentage
FROM Portafolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date

SELECT SUM(CAST(new_cases AS int)) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths,
       SUM(CAST(new_deaths AS int)) / SUM(CAST(new_cases AS int))*100 AS DeathPercentage
FROM Portafolio.dbo.CovidDeaths
WHERE continent IS NOT NULL

-- Observación total de la población vs vacunación

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS int)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM Portafolio.dbo.CovidDeaths dea
JOIN Portafolio.dbo.CovidVaccinations vac
 ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

--CTE para crear una columna con el porcentaje de la suma de los vacunados sobre la población

WITH PopvsVac
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS int)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM Portafolio.dbo.CovidDeaths dea
JOIN Portafolio.dbo.CovidVaccinations vac
 ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentPeopleVaccinated
FROM PopvsVac

-- Creamos una vista para guardar esta información para futuras visualizaciones

CREATE VIEW PercentPopulationVaccinates AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM Portafolio.dbo.CovidDeaths dea
JOIN Portafolio.dbo.CovidVaccinations vac
 ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinates