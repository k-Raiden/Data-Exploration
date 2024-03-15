Select*from CovidTab1

Select*from CovidTab2

Select Location,date,total_cases,new_cases,total_deaths,population from DataPortfolioDb..CovidTab1
Where location like 'Burundi%'

Select Location,date,total_cases,new_cases,total_deaths,population from DataPortfolioDb..CovidTab1
Where location like 'Rwanda%'

--Shows the likelyhood of dying from Covid-19 if you live in those Country.

SELECT Location, Date, Total_Cases, Total_Deaths,
    CASE
        WHEN Total_Cases = 0 THEN 0 -- Handle division by zero
        ELSE (CAST(Total_Deaths AS FLOAT) / CAST(Total_Cases AS FLOAT)) * 100
    END AS DeathPercentage
FROM DataPortfolioDb..CovidTab1
WHERE Location = 'Nigeria';

SELECT Location, Date, Total_Cases, Total_Deaths,
    CASE
        WHEN Total_Cases = 0 THEN 0 -- Handle division by zero
        ELSE (CAST(Total_Deaths AS FLOAT) / CAST(Total_Cases AS FLOAT)) * 100
    END AS DeathPercentage
FROM DataPortfolioDb..CovidTab1
WHERE Location = 'Burundi' ;

SELECT Location, Date, Total_Cases, Total_Deaths,
    CASE
        WHEN Total_Cases = 0 THEN 0 -- Handle division by zero
        ELSE (CAST(Total_Deaths AS FLOAT) / CAST(Total_Cases AS FLOAT)) * 100
    END AS DeathPercentage
FROM DataPortfolioDb..CovidTab1
WHERE Location LIKE '%States%'

--Total cases Vs Population
--Countries Stats
SELECT 
	Location, 
	Population, 
	Date, 
	Total_cases,
    CASE
        WHEN Total_cases = 0 THEN 0
        ELSE (CAST(Total_cases AS FLOAT) / CAST(Population AS FLOAT)) * 100
    END AS InfectPercentage
FROM DataPortfolioDb..CovidTab1
WHERE Location = 'Burundi';

SELECT 
    Location, 
    Population, 
    MAX(Total_Deaths) AS DeathCount, 
    MAX((CAST(Total_Deaths AS FLOAT) / Population)) * 100 AS DeathRate
FROM 
    DataPortfolioDb..CovidTab1
WHERE 
    location = 'Burundi'
GROUP BY 
    Location, 
    Population
ORDER BY 
    DeathRate DESC;

--To Combine both Queries I had to create the CTE below

	WITH BurundiStats AS (
    SELECT 
        Location, 
        Population, 
        Date, 
        Total_cases,
        CASE
            WHEN Total_cases = 0 THEN 0
            ELSE (CAST(Total_cases AS FLOAT) / CAST(Population AS FLOAT)) * 100
        END AS InfectPercentage,
        MAX(Total_Deaths) AS DeathCount, 
        MAX((CAST(Total_Deaths AS FLOAT) / Population)) * 100 AS DeathRate
    FROM 
        DataPortfolioDb..CovidTab1
    WHERE 
        Location = 'Burundi'
    GROUP BY 
        Location, 
        Population, 
        Date, 
        Total_cases
)

SELECT 
    Location, 
    Population, 
    Date, 
    Total_cases,
    InfectPercentage,
    DeathCount, 
    DeathRate
FROM 
    BurundiStats;

SELECT Location, Population, Date, Total_cases,
    CASE
        WHEN Total_cases = 0 THEN 0
        ELSE (CAST(Total_cases AS FLOAT) / CAST(Population AS FLOAT)) * 100
    END AS InfectPercentage
FROM DataPortfolioDb..CovidTab1
WHERE Location = 'Nigeria'



SELECT 
	Location, 
	Population, 
	Date, 
	Total_cases,
    CASE
        WHEN Total_cases = 0 THEN 0
        ELSE (CAST(Total_cases AS FLOAT) / CAST(Population AS FLOAT)) * 100
    END AS InfectPercentage
FROM DataPortfolioDb..CovidTab1
WHERE Location = 'United States';


-- Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) AS HighInfectCount, 
    MAX((CAST(total_cases AS FLOAT) / Population)) * 100 AS HighInfectedPop
FROM DataPortfolioDb..CovidTab1
where continent is not null
GROUP BY Location, Population
ORDER BY HighInfectedPop DESC;

-- Countries with Highest Death count Per population

SELECT Location, Population, MAX(Total_Deaths) AS HighDeathCount, 
    MAX((CAST(Total_Deaths AS FLOAT) / Population)) * 100 AS HighDeathRate
FROM DataPortfolioDb..CovidTab1
where continent is not null
GROUP BY Location, Population
ORDER BY HighDeathCount DESC;



--Continents with highest Death

SELECT

Location,Max(Total_deaths) as TotalDeathCount
From DataPortfolioDb..CovidTab1
Where continent is null
Group by location
order by TotalDeathCount desc

--Global Death rate per cases

SELECT 
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS INT)) AS total_deaths,
    CASE 
        WHEN SUM(new_cases) = 0 THEN 0
        ELSE (SUM(CAST(new_deaths AS INT)) * 100.0) / NULLIF(SUM(new_cases), 0)
    END AS GlobalDeathPercentage
FROM 
    DataPortfolioDb..CovidTab1
WHERE 
    continent IS NOT NULL
ORDER BY 
    1, 2;

--Total Vaccination per location.


SELECT 
    tab1.continent,
    tab1.location,
    tab1.date,
    tab1.population,
    tab2.new_vaccinations,
    SUM(CONVERT(INT, tab2.[new_vaccinations])) OVER (PARTITION BY tab1.location order by tab1.location,tab1.date) as TotalVaccinations
FROM 
    DataPortfolioDb..CovidTab1 tab1
JOIN 
    DataPortfolioDb..CovidTab2 tab2
ON 
    tab1.location = tab2.location
    AND tab1.date = tab2.date
WHERE 
    tab1.continent IS NOT NULL
    AND tab2.new_vaccinations IS NOT NULL 
ORDER BY 2,3;
--CTE

WITH VaccinationSummary AS (
    SELECT 
        tab1.continent,
        tab1.location,
        tab1.date,
        tab1.population,
        tab2.new_vaccinations,
        SUM(CONVERT(INT, tab2.new_vaccinations)) OVER (PARTITION BY tab1.location ORDER BY tab1.location, tab1.date) AS TotalVaccinations
    FROM 
        DataPortfolioDb..CovidTab1 tab1
    JOIN 
        DataPortfolioDb..CovidTab2 tab2
    ON 
        tab1.location = tab2.location
        AND tab1.date = tab2.date
    WHERE 
        tab1.continent IS NOT NULL
        AND tab2.new_vaccinations IS NOT NULL 
)
SELECT * ,(TotalVaccinations/population)*100 as VaccinationPerctge
FROM VaccinationSummary
ORDER BY location, date;

--temp table 

Drop Table if exists #TempVaccPeople

CREATE TABLE #TempVaccpeople (
    continent VARCHAR(255),
    location VARCHAR(255),
    date DATE,
    population INT,
    new_vaccinations INT,
    TotalVaccinations INT
);

INSERT INTO #TempVaccpeople(continent, location, date, population, new_vaccinations, TotalVaccinations)
SELECT 
    tab1.continent,
    tab1.location,
    tab1.date,
    tab1.population,
    tab2.new_vaccinations,
    SUM(CONVERT(INT, tab2.new_vaccinations)) OVER (PARTITION BY tab1.location ORDER BY tab1.location, tab1.date) AS TotalVaccinations
FROM 
    DataPortfolioDb..CovidTab1 tab1
JOIN 
    DataPortfolioDb..CovidTab2 tab2
ON 
    tab1.location = tab2.location
    AND tab1.date = tab2.date
WHERE 
    tab1.continent IS NOT NULL
   AND tab2.new_vaccinations IS NOT NULL;
	
	SELECT 
    *,
    (CONVERT(DECIMAL(18, 2), TotalVaccinations) / population) * 100 AS VaccinationPerctge 
FROM 
    #TempVaccpeople
ORDER BY 
    location, date;

--Creating Views
--1 VaccinePercentview

CREATE VIEW VaccinePercent AS
SELECT 
    tab1.continent,
    tab1.location,
    tab1.date,
    tab1.population,
    tab2.new_vaccinations,
    SUM(CONVERT(INT, tab2.new_vaccinations)) OVER (PARTITION BY tab1.location ORDER BY tab1.location, tab1.date) AS TotalVaccinations,
    (CONVERT(DECIMAL(18, 2), SUM(CONVERT(INT, tab2.new_vaccinations)) OVER (PARTITION BY tab1.location ORDER BY tab1.location, tab1.date)) / tab1.population) * 100 AS VaccinationPercentage
FROM 
    DataPortfolioDb..CovidTab1 tab1
JOIN 
    DataPortfolioDb..CovidTab2 tab2
ON 
    tab1.location = tab2.location
    AND tab1.date = tab2.date
WHERE 
    tab1.continent IS NOT NULL
    AND tab2.new_vaccinations IS NOT NULL;
	
	--2 HighDeathLocview

CREATE VIEW HighDeathLoc AS

Select Location,Max(Total_deaths) as TotalDeathCount
From DataPortfolioDb..CovidTab1
Where continent is null
Group by location

--3 BurundiStatsView
CREATE VIEW BurundiStatsView AS
WITH BurundiStats AS (
    SELECT 
        Location, 
        Population, 
        Date, 
        Total_cases,
        CASE
            WHEN Total_cases = 0 THEN 0
            ELSE (CAST(Total_cases AS FLOAT) / CAST(Population AS FLOAT)) * 100
        END AS InfectPercentage,
        MAX(Total_Deaths) AS DeathCount, 
        MAX((CAST(Total_Deaths AS FLOAT) / Population)) * 100 AS DeathRate
    FROM 
        DataPortfolioDb..CovidTab1
    WHERE 
        Location = 'Burundi'
    GROUP BY 
        Location, 
        Population, 
        Date, 
        Total_cases
)

SELECT 
    Location, 
    Population, 
    Date, 
    Total_cases,
    InfectPercentage,
    DeathCount, 
    DeathRate
FROM 
    BurundiStats;

--4 EuropeStatsView
CREATE VIEW EuropeStatsView AS
WITH EuropeStats AS (
    SELECT 
        Location, 
        Population, 
        Date, 
        Total_cases,
        CASE
            WHEN Total_cases = 0 THEN 0
            ELSE (CAST(Total_cases AS FLOAT) / CAST(Population AS FLOAT)) * 100
        END AS InfectPercentage,
        MAX(Total_Deaths) AS DeathCount, 
        MAX((CAST(Total_Deaths AS FLOAT) / Population)) * 100 AS DeathRate
    FROM 
        DataPortfolioDb..CovidTab1
    WHERE 
        Location = 'Europe'
    GROUP BY 
        Location, 
        Population, 
        Date, 
        Total_cases
)

SELECT 
    Location, 
    Population, 
    Date, 
    Total_cases,
    InfectPercentage,
    DeathCount, 
    DeathRate
FROM 
    EuropeStats;

--5 AfricaStatsView 
CREATE VIEW AfricaStatsView AS
WITH AfricaStats AS (
    SELECT 
        Location, 
        Population, 
        Date, 
        Total_cases,
        CASE
            WHEN Total_cases = 0 THEN 0
            ELSE (CAST(Total_cases AS FLOAT) / CAST(Population AS FLOAT)) * 100
        END AS InfectPercentage,
        MAX(Total_Deaths) AS DeathCount, 
        MAX((CAST(Total_Deaths AS FLOAT) / Population)) * 100 AS DeathRate
    FROM 
        DataPortfolioDb..CovidTab1
    WHERE 
        Location = 'Africa'
    GROUP BY 
        Location, 
        Population, 
        Date, 
        Total_cases
)

SELECT 
    Location, 
    Population, 
    Date, 
    Total_cases,
    InfectPercentage,
    DeathCount, 
    DeathRate
FROM 
    AfricaStats;

--6 NorthAmericaStatsView
CREATE VIEW NorthAmericaStatsView AS
WITH NorthAmericaStats AS (
    SELECT 
        Location, 
        Population, 
        Date, 
        Total_cases,
        CASE
            WHEN Total_cases = 0 THEN 0
            ELSE (CAST(Total_cases AS FLOAT) / CAST(Population AS FLOAT)) * 100
        END AS InfectPercentage,
        MAX(Total_Deaths) AS DeathCount, 
        MAX((CAST(Total_Deaths AS FLOAT) / Population)) * 100 AS DeathRate
    FROM 
        DataPortfolioDb..CovidTab1
    WHERE 
        Location = 'Europe'
    GROUP BY 
        Location, 
        Population, 
        Date, 
        Total_cases
)

SELECT 
    Location, 
    Population, 
    Date, 
    Total_cases,
    InfectPercentage,
    DeathCount, 
    DeathRate
FROM 
    NorthAmericaStats;

--7 SouthAmericaStatsview
CREATE VIEW SouthAmericaStatsView AS
WITH SouthAmericaStats AS (
    SELECT 
        Location, 
        Population, 
        Date, 
        Total_cases,
        CASE
            WHEN Total_cases = 0 THEN 0
            ELSE (CAST(Total_cases AS FLOAT) / CAST(Population AS FLOAT)) * 100
        END AS InfectPercentage,
        MAX(Total_Deaths) AS DeathCount, 
        MAX((CAST(Total_Deaths AS FLOAT) / Population)) * 100 AS DeathRate
    FROM 
        DataPortfolioDb..CovidTab1
    WHERE 
        Location = 'South America'
    GROUP BY 
        Location, 
        Population, 
        Date, 
        Total_cases
)

SELECT 
    Location, 
    Population, 
    Date, 
    Total_cases,
    InfectPercentage,
    DeathCount, 
    DeathRate
FROM 
    SouthAmericaStats;

--8 OceaniaStatsview
CREATE VIEW OceaniaStatsView AS
WITH OceaniaStats AS (
    SELECT 
        Location, 
        Population, 
        Date, 
        Total_cases,
        CASE
            WHEN Total_cases = 0 THEN 0
            ELSE (CAST(Total_cases AS FLOAT) / CAST(Population AS FLOAT)) * 100
        END AS InfectPercentage,
        MAX(Total_Deaths) AS DeathCount, 
        MAX((CAST(Total_Deaths AS FLOAT) / Population)) * 100 AS DeathRate
    FROM 
        DataPortfolioDb..CovidTab1
    WHERE 
        Location = 'Oceania'
    GROUP BY 
        Location, 
        Population, 
        Date, 
        Total_cases
)

SELECT 
    Location, 
    Population, 
    Date, 
    Total_cases,
    InfectPercentage,
    DeathCount, 
    DeathRate
FROM 
    OceaniaStats;

--9 AsiaStatsview
CREATE VIEW AsiaStatsView AS
WITH AsiaStats AS (
    SELECT 
        Location, 
        Population, 
        Date, 
        Total_cases,
        CASE
            WHEN Total_cases = 0 THEN 0
            ELSE (CAST(Total_cases AS FLOAT) / CAST(Population AS FLOAT)) * 100
        END AS InfectPercentage,
        MAX(Total_Deaths) AS DeathCount, 
        MAX((CAST(Total_Deaths AS FLOAT) / Population)) * 100 AS DeathRate
    FROM 
        DataPortfolioDb..CovidTab1
    WHERE 
        Location = 'Asia'
    GROUP BY 
        Location, 
        Population, 
        Date, 
        Total_cases
)

SELECT 
    Location, 
    Population, 
    Date, 
    Total_cases,
    InfectPercentage,
    DeathCount, 
    DeathRate
FROM 
    AsiaStats;









   

