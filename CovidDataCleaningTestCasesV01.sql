--Data Cleaning

--We can use CTE or View for future use
--WITH INC_PerDay (location, date, new_deaths, total_deaths, IncreaseInDeathsPerDay, new_vaccinations, total_vaccinations, IncreaseInVaccinationPerDay)
--AS(
ALTER VIEW INC_PerDay AS
	SELECT 
		Death.location,
		Death.date,
		Death.new_deaths,
		Death.total_deaths,
		SUM(CAST(Death.new_deaths AS numeric)) OVER(PARTITION BY Death.location ORDER BY Death.location, Death.date) AS IncreaseInDeathsPerDay,
		Vaccine.new_vaccinations,
		Vaccine.total_vaccinations,
		SUM(CAST(Vaccine.new_vaccinations AS numeric)) OVER (PARTITION BY Vaccine.location ORDER BY Vaccine.location,Vaccine.date) AS IncreaseInVaccinationPerDay,
		Vaccine.new_tests,
		Vaccine.total_tests,
		SUM(CAST(Vaccine.new_tests AS numeric)) OVER (PARTITION BY Vaccine.location ORDER BY Vaccine.location, Vaccine.date) AS IncreaseInTestsPerDay
	From TestCases.dbo.CovidVaccinations Vaccine
	JOIN TestCases.dbo.CovidDeaths Death
		ON Vaccine.date = Death.date
		AND Vaccine.location = Death.location;
		--WHERE Death.location LIKE '%India%'


--Check if the number of Increase in Deaths per day, Increase in vaccine per day, Increase in test per day is correctly w.r.t to the given data
SELECT
	location,
	IncreaseInDeathsPerDay,
	IncreaseInVaccinationPerDay,
	IncreaseInTestsPerDay
FROM (
	SELECT
		location,
		IIF(CAST(total_deaths AS numeric) = (IncreaseInDeathsPerDay),'PASS','FAILURE')  AS IncreaseInDeathsPerDay,
		IIF(CAST(total_vaccinations AS numeric) = (IncreaseInVaccinationPerDay),'PASS','FAILURE') AS IncreaseInVaccinationPerDay,
		IIF(CAST(total_tests AS numeric) = (IncreaseInTestsPerDay),'PASS','FAILURE') AS IncreaseInTestsPerDay
	From INC_PerDay
	WHERE total_deaths IS NOT NULL
		AND total_tests IS NOT NULL
		AND total_vaccinations IS NOT NULL
		--AND location LIKE '%India%'
	) AS INC_PerDay
GROUP BY 
	location,
	IncreaseInDeathsPerDay,
	IncreaseInVaccinationPerDay,
	IncreaseInTestsPerDay
ORDER BY 1;


--Checking for the NULL values in total_deaths, total_vaccinations, total_tests as they are the cause of above case FAILURE

SELECT
	location
	Total_Death,
	Total_Vaccinations,
	Total_Tests
FROM
	(
	SELECT
		location,
		IIF(total_deaths IS NULL, 'FAILURE', 'PASS') AS Total_Death,
		IIF(total_vaccinations IS NULL, 'FAIULRE', 'PASS') AS Total_Vaccinations,
		IIF(total_tests IS NULL, 'FAILURE', 'PASS') AS Total_Tests
	FROM INC_PerDay
	) AS INC_PerDay
GROUP BY location,Total_Death, Total_tests, Total_vaccinations;
		

--Checking for date data usability

SELECT
	TimeInDatePartUsability
FROM(
	SELECT
		IIF(DATEPART(hh,date)=0 
			AND DATEPART(n,date)=0
			AND DATEPART(s,date)=0 
			AND DATEPART(ms,date)=0 
			AND DATEPART(ns,date)=0, 'FAILURE','PASS') AS TimeInDatePartUsability
	FROM TestCases.dbo.CovidDeaths
	) AS DatePartCheck
GROUP BY TimeInDatePartUsability;


SELECT
	location,
	population,
	MAX(CAST(total_deaths AS numeric)) 
FROM TestCases.dbo.CovidDeaths
GROUP BY population, location
ORDER BY 3 desc;
