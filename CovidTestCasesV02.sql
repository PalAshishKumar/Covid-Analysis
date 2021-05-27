SELECT *
FROM TestCases.dbo.CovidDeaths
WHERE location LIKE '%India%'
ORDER BY location, date;

SELECT * 
From TestCases.dbo.CovidVaccinations
WHERE location LIKE '%India%'
ORDER BY location, date;

--Looking for people who are waiting for second Vaccine dose

SELECT
	--date,
	location,
	SUM(CAST(people_fully_vaccinated AS numeric))/SUM(CAST(people_vaccinated AS numeric))*100 as SecondDoseWaitingPercent
FROM TestCases.dbo.CovidVaccinations
--WHERE location LIKE '%India%'
GROUP BY location--,date
ORDER BY 2 desc

--Looking for facility index
--Sanitizing facility over locations

SELECT 
	location,
	handwashing_facilities
From TestCases.dbo.CovidVaccinations
WHERE continent IS NOT NULL
GROUP BY location, handwashing_facilities
ORDER BY 2 desc;

--hospital bed availability per thousand people over locations on 16th May 2021

SELECT 
	location,
	hospital_beds_per_thousand
From TestCases.dbo.CovidVaccinations
--WHERE location LIKE '%India%'
GROUP BY location, hospital_beds_per_thousand
ORDER BY 2 desc;

--Tests vs Deaths 

SELECT
	Death.location,
	--Death.date,
	MAX(CAST(Vaccine.total_tests AS numeric)) AS Total_Tests,
	MAX(CAST (Death.total_deaths AS numeric)) AS Total_Deaths
From TestCases.dbo.CovidVaccinations as Vaccine
JOIN TestCases.dbo.CovidDeaths as Death 
	ON Vaccine.date = Death.date 
	AND Vaccine.location=Death.location
--WHERE Death.location LIKE '%India%'
GROUP BY 
	Death.location
	--total_deaths, 
	--total_tests, 
	--death.date
ORDER BY 1;
	

--Rate of increase per day
--Rate pf Increase in Death Per Day and Vaccinations Per Day and Tests Per Day
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
	AND Vaccine.location = Death.location
WHERE Death.location LIKE '%India%'
ORDER BY Death.location, Death.date;



--Death affected by different diseases

SELECT 
	Death.location,
	CAST(Vaccine.cardiovasc_death_rate AS float) AS HeartRelatedDeathRate,
	CAST(Vaccine.diabetes_prevalence AS numeric) AS DiabetesRelatedDeathRate,
	(CAST(Vaccine.female_smokers AS numeric)+CAST(Vaccine.male_smokers AS numeric)) as DeathRateRelatedToSmoking
FROM TestCases.dbo.CovidDeaths Death
JOIN TestCases.dbo.CovidVaccinations Vaccine
	ON Death.date = Vaccine.date
	AND Death.location = Vaccine.location
WHERE 
	Death.continent IS NOT NULL
	--AND Death.location LIKE '%India%'
GROUP BY 
	Death.location, 
	Vaccine.cardiovasc_death_rate, 
	Vaccine.diabetes_prevalence, 
	Vaccine.female_smokers, 
	Vaccine.male_smokers
ORDER BY Death.location;


--Looking for the strictness over time

SELECT 
	location,
	date,
	stringency_index
From TestCases.dbo.CovidVaccinations
--WHERE location LIKE '%India%'
GROUP BY location, stringency_index,date
ORDER BY location, date;


--Looking for most prone people's deathrate over globe
--people aged over 60 + People with lung and heart related problems

SELECT 
	location,
	MAX(aged_65_older+aged_70_older+diabetes_prevalence+cardiovasc_death_rate+CAST(female_smokers AS float)+CAST(male_smokers AS float)) AS PronePeopleDeathRate
From TestCases.dbo.CovidVaccinations 
--WHERE Vaccine.location LIKE '%India%'
GROUP BY location
ORDER BY location;


--Looking for indepth analysis of India's Covid situation

--Looking for Total Death Cases over India statewise 

SELECT 
	States,
	MAX(Confirmed) AS TotalCases
FROM 
	(
	SELECT
		CASE
			WHEN State LIKE '%Tel__gana%' THEN 'Telangana'
			WHEN State LIKE '%Daman%' THEN 'Daman & Diu'
			WHEN State NOT LIKE '%Tel%' AND State NOT LIKE '%Daman%' THEN State
			END AS States,
		Date,
		Time,
		Cured,
		Deaths,
		Confirmed
	FROM TestCases.dbo.CovidIndia
	) AS CovidIndia
WHERE States NOT LIKE '%reassigned%'
AND States NOT LIKE '%Unassigned%'
GROUP BY States
ORDER BY 2 DESC;


--Increase in Cases, Deaths w.r.t time

SELECT 
	States,
	Date,
	Confirmed AS IncreaseCases,
	Deaths
FROM
	(
	SELECT
		CASE
			WHEN State LIKE '%Tel__gana%' THEN 'Telangana'
			WHEN State LIKE '%Daman%' THEN 'Daman & Diu'
			WHEN State NOT LIKE '%Tel%' AND State NOT LIKE '%Daman%' THEN State
			END AS States,
		Date,
		Time,
		Cured,
		Deaths,
		Confirmed
	FROM TestCases.dbo.CovidIndia
	) AS CovidIndia

ORDER BY 1


--looking at Movement in number in Vaccine site over time

SELECT
	State,
	PARSE([Updated On] as date USING 'de-DE') AS Date,
	[Total Sites ] AS TotalActiveSites
FROM TestCases.dbo.CovidIndiaVaccine
WHERE State NOT LIKE '%India%'
ORDER BY 1,2

--At India Level

SELECT
	State,
	PARSE([Updated On] as date USING 'de-DE') AS Date,
	[Total Sites ] AS TotalActiveSites
FROM TestCases.dbo.CovidIndiaVaccine
WHERE State LIKE '%India%'
ORDER BY 1,2

--Looking for people who need to have second dose

SELECT
	State,
	MAX([First Dose Administered]-[Second Dose Administered]) AS WaitingForSecondDose	
FROM TestCases.dbo.CovidIndiaVaccine
WHERE State NOT LIKE '%India%'
GROUP BY State;

--Over date at India level

SELECT
	PARSE([Updated On] as date USING 'de-DE') AS Date,
	State,
	MAX([First Dose Administered]-[Second Dose Administered]) AS WaitingForSecondDose	
FROM TestCases.dbo.CovidIndiaVaccine
WHERE State LIKE '%India%'
GROUP BY State, [Updated On]
ORDER BY 1;


--Difference in availability of Covaxin VS CoviShield over states each day

SELECT
	PARSE([Updated On] as date USING 'de-DE') AS Date,
	State,
	[Total CoviShield Administered],
	[Total Covaxin Administered],
	[Total CoviShield Administered]-[Total Covaxin Administered] AS DifferenceInAvailability
FROM TestCases.dbo.CovidIndiaVaccine
WHERE State NOT LIKE '%India%'
ORDER BY 1,2;

--Looking for any adverse affects after Vaccine

SELECT
	PARSE([Updated On] as date USING 'de-DE') AS Date,
	AEFI,
	State
FROM TestCases.dbo.CovidIndiaVaccine
GROUP BY AEFI,State,[Updated On]
ORDER BY 1;

--Percent of Male, Female Vaccinated over their respect gender

SELECT
	MAX([Male(Individuals Vaccinated)])/717100970*100 AS MaleOverMaleVaccinated,
	MAX([Female(Individuals Vaccinated)])/662903415*100 AS FemaleOverFemaleVaccinated
FROM TestCases.dbo.CovidIndiaVaccine


--Checking if Location are listed correctly or not

SELECT
	IIF(COUNT(*)<>0,'FAILURE','PASS') AS TestLocationData
FROM TestCases.dbo.CovidDeaths a
JOIN TestCases.dbo.CovidDeaths b
	ON a.continent = b.location;



--Checking if population count is correct or not (before or after dates)

SELECT
	location,
	population,
	IIF(MIN(population)=MAX(population),'FAILURE','PASS') AS TestPopluation
FROM TestCases.dbo.CovidDeaths
WHERE population IS NOT NULL
GROUP BY location, population
ORDER BY 1;


