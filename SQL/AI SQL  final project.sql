-- CREATING DATABASE to store and analyze 
CREATE DATABASE IF NOT EXISTS ai;
USE ai;
-- ----------------------------------------------------------------------
-- importing data from csv to ai database
SELECT* FROM ai_effect;
-- -----------------------------------------------------------------
-- CLEANING DATA
-- 1) Modifying first coulmn name from 'Job titiles' to 'Job_Title'
ALTER TABLE ai_effect
CHANGE COLUMN `Job Titiles` `Job_Title` VARCHAR(50);

-- 2) Modifying data type of the second coulmn 'AI Impact' from string to float beacuse (%) is a text value in MYSQL
UPDATE ai_effect
SET `AI Impact` = REPLACE(`AI Impact`, '%', '') / 100;
ALTER TABLE  ai_effect
MODIFY COLUMN `AI Impact` FLOAT;

-- modifying data type of 'job title' ,' Domain'
ALTER TABLE ai_effect
MODIFY COLUMN `Job_Title` VARCHAR(45),
MODIFY COLUMN Domain VARCHAR(45);

-- Detecing null values;
SELECT * FROM ai_effect
WHERE `AI Impact` IS NULL 
   OR Tasks IS NULL 
   OR `AI Models` IS NULL 
   OR AI_Workload_Ratio IS NULL 
   OR Domain IS NULL;

-- Detecting infinity values in ai_workload_ration
SELECT * 
FROM ai_effect
WHERE AI_Workload_Ratio = 'Infinity' 
   OR AI_Workload_Ratio = '-Infinity';
    
    -- detecting duplicated values in the whole table
SELECT*, COUNT(*)
FROM ai_effect
GROUP BY`Job_Title`, `AI Impact`,`AI Models`,Tasks,AI_Workload_Ratio ,`Domain`
HAVING COUNT(*) > 1;

-- -----------------------------------------------------------------------------------------------
-- Converting ERD Diagram into schema design which including 3 new tables with relationship
 -- (1) creating first table 'Domains'
CREATE TABLE IF NOT EXISTS ai.Domains (  Domain_Id INT NOT NULL AUTO_INCREMENT,
  Domain VARCHAR(45) NULL,  PRIMARY KEY (`Domain_Id`),
  UNIQUE INDEX Domain_Id_UNIQUE (`Domain_Id` ASC) VISIBLE)ENGINE = InnoDB;
  
  -- (2) creating second table 'impact'
CREATE TABLE IF NOT EXISTS ai.Impact (
  Impact_Id INT NOT NULL AUTO_INCREMENT,
  `AI Impact` FLOAT NULL,
  AI_Workload_Ratio DOUBLE NULL,
  Job_Id INT NOT NULL,
  PRIMARY KEY (`Impact_Id`),
  UNIQUE INDEX Impact_Id_UNIQUE (`Impact_Id` ASC) VISIBLE,
  INDEX fk_Impact_Jobs1_idx (`Job_Id` ASC) VISIBLE,
  UNIQUE INDEX Job_Id_UNIQUE (`Job_Id` ASC) VISIBLE,
  CONSTRAINT fk_Impact_Jobs1
    FOREIGN KEY (`Job_Id`)
    REFERENCES ai.Jobs (`Job_Id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

-- (3)creating third table 'Jobs'
CREATE TABLE IF NOT EXISTS ai.Jobs (
  Job_Id INT NOT NULL AUTO_INCREMENT,
  Job_Title VARCHAR(45) NULL,
  `AI models` INT NULL,
  Tasks INT NULL,
  Domain_Id INT NOT NULL,
  PRIMARY KEY (`Job_Id`),
  INDEX fk_Jobs_Domains_idx (`Domain_Id` ASC) VISIBLE,
  UNIQUE INDEX Job_Id_UNIQUE (`Job_Id` ASC) VISIBLE,
  UNIQUE INDEX Domain_Id_UNIQUE (`Domain_Id` ASC) VISIBLE,
  CONSTRAINT fk_Jobs_Domains
    FOREIGN KEY (`Domain_Id`)
    REFERENCES ai.Domains (`Domain_Id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;
-- -------------------------------------------------------------------------------------------

-- INSERTING DATA into new tables
-- (1)Inserting into the Domains
INSERT INTO ai.Domains (Domain)
SELECT DISTINCT Domain
FROM ai_effect;
-- (2) Inserting into Impact
INSERT INTO ai.Impact (`AI Impact`, AI_Workload_Ratio, Job_Id)
SELECT ae.`AI Impact`, ae.AI_Workload_Ratio, j.Job_Id
FROM ai_effect ae
JOIN ai.Jobs j ON ae.Job_Title = j.Job_Title;
-- (3) inserting into Jobs
INSERT INTO ai.Jobs (Job_Title, `AI models`, Tasks, Domain_Id)
SELECT ae.Job_Title, ae.`AI models`, ae.Tasks, d.Domain_Id
FROM ai_effect ae
JOIN ai.Domains d ON ae.Domain = d.Domain;
ALTER TABLE ai.Jobs
DROP INDEX Domain_Id_UNIQUE;
SELECT* FROM domains
SELECT* FROM Jobs;
SELECT* FROM Impact;
-- ---------------------------------------------------------------------------------------------
-- EXPLORING AND ANALYZING DATA
-- DOMAINS
   -- Summary statistcs and insights about "Domain' coulmn
   -- uniuqe Domains
   SELECT DISTINCT Domain       
FROM ai_effect;
 -- count of unique domains
SELECT COUNT(DISTINCT Domain) AS Unique_Domain_Count    
FROM ai_effect;

-- number of job title in each domain
SELECT Domain, COUNT(`Job_Title`) AS job_count          
FROM ai_effect 
GROUP BY Domain
ORDER BY job_count DESC;
  
  -- Top 10 domains affected by ai(Domain Vs AI impact)
  SELECT Domain, AVG(`AI Impact`) AS Average_AI_Impact  
FROM ai_effect
GROUP BY Domain
ORDER BY Average_AI_Impact DESC
LIMIT 10;

-- Domains where ai models are widely used (highest Ai models)
SELECT Domain, 
       AVG(`AI Models`) AS avg_ai_models
FROM ai_effect
GROUP BY Domain
ORDER BY avg_ai_models DESC
LIMIT 10;

-- Domains with the highest (tasks) human performance
SELECT Domain, Tasks
FROM ai_effect
ORDER BY Tasks desc
LIMIT 10;

-- Domains with the highest Ai workload ration
SELECT Domain, AVG((AI_Workload_Ratio)) AS avg_workload_ratio
FROM ai_effect
GROUP BY Domain
ORDER BY avg_workload_ratio DESC;

-- Counting total tasks and Ai models for each domain 
SELECT Domain, 
SUM(Tasks) AS total_tasks, 
       SUM(`AI Models`) AS total_ai_models
FROM ai_effect
GROUP BY Domain
ORDER BY total_tasks DESC;

-- JOB TITLES
-- Top 10 job titles affected by ai
SELECT`Job_Title`, `AI Impact`
FROM ai_effect
ORDER BY`AI Impact`DESC
LIMIT 10;
-- Bottom 10 Job titles affected by ai
SELECT`Job_Title`,`AI Impact`
FROM ai_effect
ORDER By`AI Impact`ASC
LIMIT 10;

-- Job titles with the  highest Ai workload ration
SELECT Job_Title, AI_Workload_ratio
FROM ai_effect
ORDER BY AI_Workload_Ratio DESC
LIMIT 10;

-- Job titles with the loewst Ai workload ration
SELECT Job_Title, AI_Workload_ratio
FROM ai_effect
ORDER BY AI_Workload_Ratio ASC
LIMIT 10;

-- Jobs with the highest number of tasks
SELECT Job_Title, Tasks
FROM ai_effect
ORDER BY Tasks DESC
LIMIT 10;

-- Jobs with the lowest number of tasks
SELECT Job_Title, Tasks
FROM ai_effect
ORDER BY Tasks DESC
LIMIT 10;

-- jobs with the most number of ai model
SELECT Job_Title, `AI Models`
FROM ai_effect
order by `AI models` DESC
LIMIT 10;

-- jobs with the lowest number of ai model
SELECT Job_Title, `AI Models`
FROM ai_effect
order by `AI models` ASC
LIMIT 10;

-- Compare and analyze the relationship  Ai pmact Vs Tasks .Jobtitles
SELECT Job_Title, `AI models`, AI_Workload_Ratio
FROM ai_effect
ORDER BY `AI models`, AI_Workload_Ratio DESC;

-- Jobs where ai impact below certain 50%
SELECT Job_Title, `AI Impact`
FROM ai_effect
WHERE `AI Impact` < 0.5
ORDER BY `AI Impact` ASC;

-- Jobs where ai impact above 80%
SELECT Job_Title, `AI Impact`
FROM ai_effect
WHERE `AI Impact` > 0.8
ORDER BY `AI Impact` ASC;

-- showing each domain and the job titles including with the ai impact for each job
SELECT 
    Domains.Domain, 
    Jobs.Job_Title, 
    Impact.`AI Impact`
FROM 
    Jobs
JOIN 
    Domains ON Jobs.Domain_Id = Domains.Domain_Id
JOIN 
    Impact ON Jobs.Job_Id = Impact.Job_Id
ORDER BY 
    Domains.Domain, 
    Impact.`AI Impact` DESC;
 
 -- showing each job title with its wokload ratio and ai impact
 SELECT 
    Jobs.Job_Title, 
    impact.`AI Impact`, 
    impact.AI_Workload_Ratio
FROM 
    Jobs
JOIN 
    impact ON Jobs.Job_Id = impact.Job_Id;
    
    -- showing jobs with the highest ai models >2000
    SELECT 
    Jobs.Job_Title, 
    Jobs.`AI Models`
FROM 
    Jobs
WHERE 
    Jobs.`AI Models` > 2000;