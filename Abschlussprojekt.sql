-- Final Project SQL Course
-- German Note: Ich schreibe dieses Projekt auf Englisch, damit es potentielle Arbeitgeber ohne deutsche Sprachkenntnisse einfacher lesen können.
-- 		Die Präsentation ist selbstverständlich auf Deutsch.
/*	To the reader of this project:
	Please Note that this is a project that is supposed to be executed 100% in SQL with exception only to the visualization through graphs that may be executed with an external tool
    after the final export of the table from SQL. The objective is to write correct select requests for accurate data export such that employers can see what to expect.
    This being said, of course analysis outside of this specific project would usually be done in Excel, Python, R, Power BI, or other tools.
    This is why statistical analysis for this project is limited (e.g. in terms of significance tests) that I would usually execute for different projects within different tools
    after Data Export from SQL. */

-- Index

-- 34	-- 0) Creating Database and Loading Data
-- 83	-- 1) Data Exploration and Cleaning
-- 122	-- 1.1) Invalid Employment Length
-- 143	-- 1.3) Income, Loan Amount, and Loan Percentage Income
-- 226	-- 1.4) Age
-- 239	-- 2) Cleaning
-- 299	-- 3) Feature Engineering
-- 565	-- 4) Analysis
-- 574	-- 4.1) Creating Tables
-- 644	-- 4.2) Calculating Correlations
-- 1374	-- 4.3) Correlations with t-significance tests
-- 2039	-- 4.4) Calculating probabilities
-- 2091	-- 5) Building the actual grading system
-- 2100	-- 5.1) Building a Scoring Table based on correlations
-- 2170	-- 5.2) Normalizing, Standardizing and Weighting Data
-- 2241	-- 5.3) Developing the final Score Table
-- 2361	-- 6) Determining the optimal interest rate
-- 2382	-- 6.1) Calculating the risk eliminating interest rate
-- 2455	-- 6.2) Which monthly amount relative to income can an idividual sustain?
-- 2532	-- 6.3) Earnings Calculations and Model Comparison

-- 0) Creating Database and Loading Data

DROP DATABASE IF EXISTS credit_risk_dataset;

CREATE DATABASE credit_risk_dataset;

USE credit_risk_dataset;

CREATE TABLE credit_risk (
person_age INT,
person_income INT,
person_home_ownership VARCHAR(20),
person_emp_length DOUBLE NULL,
loan_intent VARCHAR(30),
loan_grade VARCHAR(5),
loan_amnt INT,
loan_int_rate DOUBLE NULL,
loan_status INT,
loan_percent_income DOUBLE,
cb_person_default_on_file VARCHAR(5),
cb_person_cred_hist_length INT
);

SET GLOBAL local_infile = 1;

SHOW GLOBAL VARIABLES LIKE 'local_infile';

LOAD DATA LOCAL INFILE 'C:/Users/JacobStank/Documents/Unterrichtsmaterialien/Unterrichtsmaterialien/04. SQL/Abschlussprojekt/credit_risk_dataset.csv'
INTO TABLE credit_risk
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(person_age, person_income, person_home_ownership,
@emp_length, loan_intent, loan_grade, loan_amnt,
@int_rate, loan_status, loan_percent_income,
cb_person_default_on_file, cb_person_cred_hist_length)
SET
person_emp_length = NULLIF(@emp_length, ''),
loan_int_rate = NULLIF(@int_rate, '');

-- Adding a Primary Key
-- ALTER TABLE credit_risk
-- DROP COLUMN credit_id;

ALTER TABLE credit_risk
ADD COLUMN credit_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;

-- 0) Creating Database and Loading Data
-- --------------------------------------------------------------------------------------------------
-- 1.1) Invalid Employment Length

SELECT * FROM credit_risk LIMIT 100;

-- We immediately see that Employment Length is sometimes bigger than personal age, which is invalid
-- This could be due to an insertion / typing error, or it could be set intentionally to achieve a higher credit score and a lower interest rate
-- Feature Engineering: To analyze this usecase numerically, I will create a new column to calculate the difference between Employment Length and Age
-- 	Specifically: One starts to work with 18 years. Theoretically, it is possible to work at the same firm beginning at that age (e.g. if the firm is family property)
--  This is why all emp lenth values that are bigger than Age - 18 should be considered to be invalid and should be replaced by NULL values
--  Since intentional corruption must be considered, the difference should be kept previously to later measure the effect on credit score, interest rate and default risk

ALTER TABLE credit_risk
ADD COLUMN emp_age_diff INT;

UPDATE credit_risk
SET emp_age_diff = (person_age - 18) - person_emp_length;

-- confirming new column
SELECT * FROM credit_risk LIMIT 100;

-- checking, how many invalid values there actually exist
SELECT
    SUM(CASE WHEN emp_age_diff < 0 THEN 1 ELSE 0 END) AS invalid_values,
    SUM(CASE WHEN emp_age_diff >= 0 THEN 1 ELSE 0 END) AS valid_values,
    SUM(CASE WHEN emp_age_diff < 0 THEN 1 ELSE 0 END) / (SUM(CASE WHEN emp_age_diff < 0 THEN 1 ELSE 0 END) + SUM(CASE WHEN emp_age_diff >= 0 THEN 1 ELSE 0 END)) AS persentage_invalid_values
FROM credit_risk;
-- 24.73% of invalid values is very high to be an occasional insertion/typing error, it indicates that the false values might have been set intentionally
-- At this point, we are still in the data exploration and cleansing steps, the analysis of this will be left for later

-- Setting Invalid Values to NULL in person_emp_length:
UPDATE credit_risk
SET person_emp_length = NULL
WHERE emp_age_diff < 0;

-- confirming correctly set NULL values for person_emp_length:
SELECT * FROM credit_risk LIMIT 100;

-- 1.1) Invalid Employment Length
-- --------------------------------------------------------------------------------------------------
-- 1.2) Counting the NULL Values for all columns

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN person_age IS NULL THEN 1 ELSE 0 END) AS person_age_null_count,
    SUM(CASE WHEN person_income IS NULL THEN 1 ELSE 0 END) AS person_income_null_count,
    SUM(CASE WHEN person_home_ownership IS NULL THEN 1 ELSE 0 END) AS person_home_ownership_null_count,
    SUM(CASE WHEN person_emp_length IS NULL THEN 1 ELSE 0 END) AS person_emp_length_null_count,
    SUM(CASE WHEN loan_intent IS NULL THEN 1 ELSE 0 END) AS loan_intent_null_count,
    SUM(CASE WHEN loan_grade IS NULL THEN 1 ELSE 0 END) AS loan_grade_null_count,
    SUM(CASE WHEN loan_amnt IS NULL THEN 1 ELSE 0 END) AS loan_amnt_null_count,
    SUM(CASE WHEN loan_int_rate IS NULL THEN 1 ELSE 0 END) AS loan_int_rate_null_count,
    SUM(CASE WHEN loan_status IS NULL THEN 1 ELSE 0 END) AS loan_status_null_count,
    SUM(CASE WHEN loan_percent_income IS NULL THEN 1 ELSE 0 END) AS loan_percent_income_null_count,
    SUM(CASE WHEN cb_person_default_on_file IS NULL THEN 1 ELSE 0 END) AS cb_person_default_on_file_null_count,
    SUM(CASE WHEN cb_person_cred_hist_length IS NULL THEN 1 ELSE 0 END) AS cb_person_cred_hist_length_null_count,
    SUM(CASE WHEN emp_age_diff IS NULL THEN 1 ELSE 0 END) AS emp_age_diff_null_count
FROM credit_risk;

-- 1.2) Counting the NULL Values for all columns
-- --------------------------------------------------------------------------------------------------
-- 1.3) Income, Loan Amount, and Loan Percentage Income

-- Feature Engineering: Creating a new Column that shows 1 if the percentage of Loan Amount from the given Income equals the Loan Percent Income column, else it shows 0
-- ALTER TABLE credit_risk
-- DROP COLUMN loan_income_consistency;

ALTER TABLE credit_risk
ADD COLUMN loan_income_consistency INT;

-- SELECT ROUND(loan_amnt/person_income,2) FROM credit_risk LIMIT 100;

UPDATE credit_risk
SET loan_income_consistency = 
	CASE
		WHEN ROUND(loan_amnt/person_income,2) = loan_percent_income THEN 1	-- The loan_percent_income column has 2 decimals
        ELSE 0
    END;
    
-- confirming new column
SELECT * FROM credit_risk LIMIT 100;

-- We see several zeros. The question is if these are rounding mistakes or entirely inconsistent calculations
-- Feature Engineering: Creating 2 new columns. One in which we see the calculated loan percent income and one in which we see the difference

-- ALTER TABLE credit_risk
-- DROP COLUMN loan_percent_income_calculated;

-- ALTER TABLE credit_risk
-- DROP COLUMN loan_percent_income_diff;

ALTER TABLE credit_risk
ADD COLUMN loan_percent_income_calculated DOUBLE;

ALTER TABLE credit_risk
ADD COLUMN loan_percent_income_diff DOUBLE;

-- MY SQL refuses to calculate the decimals right away, wherefore it's needed to use CAST(... AS DECIMAL(4,2))
-- Checking maximum values to confirm all values are within the defnied intervall
SELECT MAX(loan_percent_income) FROM credit_risk;
SELECT MAX(loan_percent_income_calculated) FROM credit_risk;

-- Filling the new columns
UPDATE credit_risk
SET loan_percent_income_calculated = 
	ROUND(
		CAST(loan_amnt AS DECIMAL(10,2)) / NULLIF(CAST(person_income AS DECIMAL(10,2)), 0),
        2);

UPDATE credit_risk
SET loan_percent_income_diff =
    ROUND(
            CAST(loan_percent_income AS DECIMAL(10,2)) 
          - CAST(loan_percent_income_calculated AS DECIMAL(10,2)),
    2);

-- confirming new columns
SELECT * FROM credit_risk LIMIT 100;

-- checking, how many inconsistent combinations actually exist
SELECT
    SUM(CASE WHEN loan_percent_income_diff = 0.00 THEN 1 ELSE 0 END) AS consistent_values,
    SUM(CASE WHEN loan_percent_income_diff <> 0.00 AND loan_percent_income_diff IS NOT NULL THEN 1 ELSE 0 END) AS inconsistent_values,
    SUM(CASE WHEN loan_percent_income_diff <> 0.00 AND loan_percent_income_diff IS NOT NULL THEN 1 ELSE 0 END) / 
		(SUM(CASE WHEN loan_percent_income_diff = 0.00 THEN 1 ELSE 0 END) + SUM(CASE WHEN loan_percent_income_diff <> 0.00 AND loan_percent_income_diff IS NOT NULL THEN 1 ELSE 0 END))
        AS persentage_invalid_values
FROM credit_risk;
-- It is found that 652 rows are inconsistent, which is 2% of all value pairs

-- Now the question is: How big is the difference? Are we talking about little percentage numbers or lagers deviations?
SELECT credit_id, loan_percent_income_diff FROM credit_risk
WHERE loan_percent_income_diff <> 0.00
ORDER BY loan_percent_income_diff;
-- We see high differences of up to 9 Percentage Points but also only 1 Percentage Point

-- A Group By select could give a better overview of how the deviances are distributed
SELECT loan_percent_income_diff, COUNT(credit_id) AS `Number of Credits given` FROM credit_risk
WHERE loan_percent_income_diff <> 0.00
GROUP BY loan_percent_income_diff ORDER BY loan_percent_income_diff;
-- We see that 338 of 652 rows deviate stronger than by 1 percentage point. 1 PP could be a rounding error, bigger than 1 is definitely unclean data
-- The dataset is large enough that clearing all inconsistent rows still gives robust results, wherefore, I decide to clear all rows in the actual cleaning step

-- 1.3) Income, Loan Amount, and Loan Percentage Income
-- --------------------------------------------------------------------------------------------------
-- 1.4) Age

SELECT person_age, COUNT(credit_id) AS `Number of Credits given` FROM credit_risk
GROUP BY person_age ORDER BY person_age;

-- Some people are very old Ages 123 and 144 are ages that officially have never been reached in any nation, that keeps records in the digital age
-- Therefore, 5 values are false
-- Proceed: A clean dataset is to be made. Later we should look at the outliers again and check if they benifited somehow due to higher age
-- Note: Many banks tend to set a limit for until when a credit can be taken. This limit is set due to Life expectance to reduce risk of default due to death
-- 	It is possible that such limit is lifted for this dataset, because of some internal policy that another person can commit to taking over the cost upon death of the credit taker

-- 1.4) Age
-- --------------------------------------------------------------------------------------------------
-- 2) Cleaning

-- 3 Things have been identified that need to be considered in the cleaning step.
-- From 1.1) Invalid Employment Length: The Employment Length is too long considering the age to whom the credit is given
-- 			24.73% of the Dataset is affected by this, we are talking about a realtively large issue. Just ignoring roughly 1/4 of the dataset could skew the data
-- 			However, when calculating with this data, those values should not be included at all. 
-- 			They have already been replaced with NULL values, the information is stored in the emp_age_diff column
-- FROM 1.3) Income, Loan Amount, and Loan Percentage Income: Those three values are sometimes inconsistent and don't add up
-- 			It is unclear which of the 3 values is correct and which is wrong, wherefore, it makes sense to ignore all three of them
-- 			Roughly 2% of the Dataset is affected. The Dataset is large enough to clean them and still receive roboust results
-- 			These values should be compared to the results of the clean Data afterwards.
-- 1.4) Age: It is too high for many credits given. 5 Values are entirely impossible and will be cleared
-- 			Besides, there are very high numbers for age on specific rows which are very atypical in our modern world
-- 			Most banks would not give credits to that old people due to the risk of debtors death before the debt is returned
-- 			In this datasheet, it will be assumed that the bank has it's reasons to give credits to these people. Therefore this data will not be cleansed.
-- 			An example could be an internal policy that a younger person has to comitt to take over the credit at the event of the debtors death

-- Duplicates Note: Please note that there is no indicator for a unique row besides the Primary Key that has been added in step 0).
-- Thereofre it is very much possible to have two identical rows that referr to two different credits given
-- This is why no duplicates will be removed from the dataset.

-- Proceeding:
-- 2 further tables will be created:
-- credit_risk_clean_light:
-- 		Here, the invalid employment length will not be cleansed, though the NULL values are correctly applied. All other cleaning steps will be applied as described
-- credit_risk_clean_hard:
-- 		Here, all cleaning steps previously mentioned will be applied, also all lines with false employment data will be removed from this table
-- The goal is to compare the results of both tables to check for potential effects of false employment length given

-- Creating the lightly cleansed table

CREATE TABLE credit_risk_clean_light AS
SELECT * FROM credit_risk;

-- Deleting all rows where a persons age is higher than 122, which is the oldest person known to have lived in the digital age

DELETE FROM credit_risk_clean_light
WHERE person_age > 122;
-- 5 rows affected

-- Deleting all rows where Income, Loan Amount, and Loan Percentage Income are inconsistent

DELETE FROM credit_risk_clean_light
WHERE loan_percent_income_diff <> 0.00;
-- 652 rows effected

-- lightly cleansed table successfully created
-- creating hard cleansed table

CREATE TABLE credit_risk_clean_hard AS
SELECT * FROM credit_risk_clean_light;

-- Deleting all rows with an invalid Employment Length

DELETE FROM credit_risk_clean_hard
WHERE emp_age_diff < 0;
-- 7674 rows affected

-- 2) Cleaning
-- --------------------------------------------------------------------------------------------------
-- 3) Feature Engineering

-- A few columns have already been added
-- emp_age_diff to check the difference between the the employment length and the maximum possible employment length. This feature can be kept for analysis.
-- loan_percent_income_calculated which is the reconstructed column loan_percent_income based on income and loan_amnt.
-- 		This is always equal to loan_percent_income in the cleansed tables and can be dropped
-- loan_percent_income_diff which is the difference between loan_percent_income_calculated and loan_percent_income.
-- 		This is always 0 in the cleansed tables and can be dropped

ALTER TABLE credit_risk_clean_light
DROP COLUMN loan_percent_income_calculated;

ALTER TABLE credit_risk_clean_light
DROP COLUMN loan_percent_income_diff;

ALTER TABLE credit_risk_clean_hard
DROP COLUMN loan_percent_income_calculated;

ALTER TABLE credit_risk_clean_hard
DROP COLUMN loan_percent_income_diff;

-- New Feature: To be paid yearly
-- Unfortunately, no loan term is given within the data. This would be useful to determine how much the debtor has to pay back per year and how many % that is measured by income
-- While this still makes sense next to the loan percent to income, it will be assumed a loan term of 10 years for each debtor
-- This is not 100% accurate, usually a higher interest rate is demanded for a longer term, yet, it could indicate if the weight of the loan is too high for the debtor to carry

ALTER TABLE credit_risk
ADD COLUMN yearly_amount DOUBLE;

UPDATE credit_risk
SET yearly_amount = ROUND(loan_amnt * ( (loan_int_rate / 100) * POWER(1 + (loan_int_rate / 100), 10) ) / ( POWER(1 + (loan_int_rate / 100), 10) - 1 ),2);

ALTER TABLE credit_risk_clean_light
ADD COLUMN yearly_amount DOUBLE;

UPDATE credit_risk_clean_light
SET yearly_amount = ROUND(loan_amnt * ( (loan_int_rate / 100) * POWER(1 + (loan_int_rate / 100), 10) ) / ( POWER(1 + (loan_int_rate / 100), 10) - 1 ),2);

ALTER TABLE credit_risk_clean_hard
ADD COLUMN yearly_amount DOUBLE;

UPDATE credit_risk_clean_hard
SET yearly_amount = ROUND(loan_amnt * ( (loan_int_rate / 100) * POWER(1 + (loan_int_rate / 100), 10) ) / ( POWER(1 + (loan_int_rate / 100), 10) - 1 ),2);

SELECT * FROM credit_risk_clean_hard LIMIT 100;

-- It is also important how much this is in percentage measured by the income. Adding Feature

ALTER TABLE credit_risk
ADD COLUMN yr_amnt_to_income DOUBLE;

UPDATE credit_risk
SET yr_amnt_to_income = yearly_amount / person_income;

ALTER TABLE credit_risk_clean_light
ADD COLUMN yr_amnt_to_income DOUBLE;

UPDATE credit_risk_clean_light
SET yr_amnt_to_income = yearly_amount / person_income;

ALTER TABLE credit_risk_clean_hard
ADD COLUMN yr_amnt_to_income DOUBLE;

UPDATE credit_risk_clean_hard
SET yr_amnt_to_income = yearly_amount / person_income;

-- Loan Grade: A Numeric value is much better for analysis. Korrelations are much easier to calculate this way.
-- Loan Grade Num: Loan Grade transformed into a numeric value: A -> 1, B -> 2, etc

ALTER TABLE credit_risk
ADD COLUMN loan_grade_num INT;

UPDATE credit_risk
SET loan_grade_num =
	CASE
		WHEN loan_grade = 'A' THEN 1
        WHEN loan_grade = 'B' THEN 2
        WHEN loan_grade = 'C' THEN 3
        WHEN loan_grade = 'D' THEN 4
        WHEN loan_grade = 'E' THEN 5
        WHEN loan_grade = 'F' THEN 6
        WHEN loan_grade = 'G' THEN 7
	END;

ALTER TABLE credit_risk_clean_light
ADD COLUMN loan_grade_num INT;

UPDATE credit_risk_clean_light
SET loan_grade_num =
	CASE
		WHEN loan_grade = 'A' THEN 1
        WHEN loan_grade = 'B' THEN 2
        WHEN loan_grade = 'C' THEN 3
        WHEN loan_grade = 'D' THEN 4
        WHEN loan_grade = 'E' THEN 5
        WHEN loan_grade = 'F' THEN 6
        WHEN loan_grade = 'G' THEN 7
	END;

ALTER TABLE credit_risk_clean_hard
ADD COLUMN loan_grade_num INT;

UPDATE credit_risk_clean_hard
SET loan_grade_num =
	CASE
		WHEN loan_grade = 'A' THEN 1
        WHEN loan_grade = 'B' THEN 2
        WHEN loan_grade = 'C' THEN 3
        WHEN loan_grade = 'D' THEN 4
        WHEN loan_grade = 'E' THEN 5
        WHEN loan_grade = 'F' THEN 6
        WHEN loan_grade = 'G' THEN 7
	END;
    
-- cb_person_default_on_file Frühere Zahlungsausfälle in der Kredithistorie Y = Yes, N = No
-- Changing these Values to a numeric format (1 = Yes, 0 = No) enables analysis like correlation analysis
    
ALTER TABLE credit_risk
ADD COLUMN cb_person_default_on_file_num INT;

UPDATE credit_risk
SET cb_person_default_on_file_num =
	CASE
		WHEN cb_person_default_on_file = 'Y' THEN 1
        WHEN cb_person_default_on_file = 'N' THEN 0
        ELSE NULL
	END;
    
ALTER TABLE credit_risk_clean_light
ADD COLUMN cb_person_default_on_file_num INT;

UPDATE credit_risk_clean_light
SET cb_person_default_on_file_num =
	CASE
		WHEN cb_person_default_on_file = 'Y' THEN 1
        WHEN cb_person_default_on_file = 'N' THEN 0
        ELSE NULL
	END;
    
ALTER TABLE credit_risk_clean_hard
ADD COLUMN cb_person_default_on_file_num INT;

UPDATE credit_risk_clean_hard
SET cb_person_default_on_file_num =
	CASE
		WHEN cb_person_default_on_file = 'Y' THEN 1
        WHEN cb_person_default_on_file = 'N' THEN 0
        ELSE NULL
	END;
    
-- Later on in this file the decision will be made to drop analyzing the hard cleansed and the regular table to only proceed
-- 	analyzing the lightly cleansed table. More on that in 4.2) Calculating Correlations
-- In the following part of this section, another table will be created to create dummy variables of nominal data that cannot
-- 	be brought into any continuous order

CREATE TABLE credit_risk_clean_light_dummy AS
SELECT * FROM credit_risk_clean_light;

-- Adding Columns for Home Ownership Dummy Variables

ALTER TABLE credit_risk_clean_light_dummy
ADD COLUMN home_ownership_rent_dummy INT;

ALTER TABLE credit_risk_clean_light_dummy
ADD COLUMN home_ownership_own_dummy INT;

ALTER TABLE credit_risk_clean_light_dummy
ADD COLUMN home_ownership_mortgage_dummy INT;

ALTER TABLE credit_risk_clean_light_dummy
ADD COLUMN home_ownership_other_dummy INT;

-- Setting Dummy Variables

UPDATE credit_risk_clean_light_dummy
SET home_ownership_rent_dummy =
	CASE
		WHEN person_home_ownership = 'RENT' THEN 1
        ELSE 0
    END;

UPDATE credit_risk_clean_light_dummy
SET home_ownership_own_dummy =
	CASE
		WHEN person_home_ownership = 'OWN' THEN 1
        ELSE 0
    END;
    
UPDATE credit_risk_clean_light_dummy
SET home_ownership_mortgage_dummy =
	CASE
		WHEN person_home_ownership = 'MORTGAGE' THEN 1
        ELSE 0
    END;
    
UPDATE credit_risk_clean_light_dummy
SET home_ownership_other_dummy =
	CASE
		WHEN person_home_ownership = 'OTHER' THEN 1
        ELSE 0
    END;
    
-- Adding Columns for Loan Intent Dummy Variables

ALTER TABLE credit_risk_clean_light_dummy
ADD COLUMN loan_intent_debtconsolidation_dummy INT;

ALTER TABLE credit_risk_clean_light_dummy
ADD COLUMN loan_intent_education_dummy INT;

ALTER TABLE credit_risk_clean_light_dummy
ADD COLUMN loan_intent_homeimprovement_dummy INT;

ALTER TABLE credit_risk_clean_light_dummy
ADD COLUMN loan_intent_medical_dummy INT;

ALTER TABLE credit_risk_clean_light_dummy
ADD COLUMN loan_intent_personal_dummy INT;

ALTER TABLE credit_risk_clean_light_dummy
ADD COLUMN loan_intent_venture_dummy INT;

UPDATE credit_risk_clean_light_dummy
SET loan_intent_debtconsolidation_dummy =
	CASE
		WHEN loan_intent = 'DEBTCONSOLIDATION' THEN 1
        ELSE 0
    END;
    
UPDATE credit_risk_clean_light_dummy
SET loan_intent_education_dummy =
	CASE
		WHEN loan_intent = 'EDUCATION' THEN 1
        ELSE 0
    END;
    
UPDATE credit_risk_clean_light_dummy
SET loan_intent_homeimprovement_dummy =
	CASE
		WHEN loan_intent = 'HOMEIMPROVEMENT' THEN 1
        ELSE 0
    END;
    
UPDATE credit_risk_clean_light_dummy
SET loan_intent_medical_dummy =
	CASE
		WHEN loan_intent = 'MEDICAL' THEN 1
        ELSE 0
    END;
    
UPDATE credit_risk_clean_light_dummy
SET loan_intent_personal_dummy =
	CASE
		WHEN loan_intent = 'PERSONAL' THEN 1
        ELSE 0
    END;
    
UPDATE credit_risk_clean_light_dummy
SET loan_intent_venture_dummy =
	CASE
		WHEN loan_intent = 'VENTURE' THEN 1
        ELSE 0
    END;

-- 3) Feature Engineering
-- --------------------------------------------------------------------------------------------------
-- 4) Analysis

SELECT * FROM credit_risk;

SELECT * FROM credit_risk_clean_light;

SELECT * FROM credit_risk_clean_hard;

-- --------------------------------------------------------------------------------------------------
-- 4.1) Creating Tables

SELECT
	CASE
		WHEN person_income < 40000 THEN 'low (<40K)'
        WHEN person_income BETWEEN 40000 AND 70000 THEN 'middle (40K - 70K)'
        WHEN person_income > 70000 THEN 'high (>70K)'
	END AS `Income Class`,
    COUNT(credit_id) AS `Number of Credits given`,
    SUM(loan_status)/Count(credit_id) AS `Default Percentage`,
    SUM(cb_person_default_on_file = 'Y') / COUNT(credit_id) AS `Previously Defaulted Percentage`,
    ROUND(AVG(person_age),2) AS `Average Age`,
    ROUND(AVG(loan_amnt),2) AS `Loan Amount Average`,
    ROUND(AVG(person_emp_length),2) AS `Employment Length Average`,
    ROUND(AVG(loan_int_rate),2) AS `Interest Rate Average`,
    ROUND(AVG(loan_percent_income),2) AS `Loan Percentage of Income Average`,
    ROUND(AVG(cb_person_cred_hist_length),2) AS `Average Credit History Length`,
    ROUND(AVG(yearly_amount),2) AS `Average Yearly Debt Weight (10 yrs assumed)`,
    ROUND(AVG(yr_amnt_to_income),2) AS `Average Yearly Weight to Income`
FROM credit_risk
GROUP BY `Income Class`;

SELECT
	CASE
		WHEN person_income < 40000 THEN 'low (<40K)'
        WHEN person_income BETWEEN 40000 AND 70000 THEN 'middle (40K - 70K)'
        WHEN person_income > 70000 THEN 'high (>70K)'
	END AS `Income Class`,
    COUNT(credit_id) AS `Number of Credits given`,
    SUM(loan_status)/Count(credit_id) AS `Default Percentage`,
    SUM(cb_person_default_on_file = 'Y') / COUNT(credit_id) AS `Previously Defaulted Percentage`,
    ROUND(AVG(person_age),2) AS `Average Age`,
    ROUND(AVG(loan_amnt),2) AS `Loan Amount Average`,
    ROUND(AVG(person_emp_length),2) AS `Employment Length Average`,
    ROUND(AVG(loan_int_rate),2) AS `Interest Rate Average`,
    ROUND(AVG(loan_percent_income),2) AS `Loan Percentage of Income Average`,
    ROUND(AVG(cb_person_cred_hist_length),2) AS `Average Credit History Length`,
    ROUND(AVG(yearly_amount),2) AS `Average Yearly Debt Weight (10 yrs assumed)`,
    ROUND(AVG(yr_amnt_to_income),2) AS `Average Yearly Weight to Income`
FROM credit_risk_clean_light
GROUP BY `Income Class`;

SELECT
	CASE
		WHEN person_income < 40000 THEN 'low (<40K)'
        WHEN person_income BETWEEN 40000 AND 70000 THEN 'middle (40K - 70K)'
        WHEN person_income > 70000 THEN 'high (>70K)'
	END AS `Income Class`,
    COUNT(credit_id) AS `Number of Credits given`,
    SUM(loan_status)/Count(credit_id) AS `Default Percentage`,
    SUM(cb_person_default_on_file = 'Y') / COUNT(credit_id) AS `Previously Defaulted Percentage`,
    ROUND(AVG(person_age),2) AS `Average Age`,
    ROUND(AVG(loan_amnt),2) AS `Loan Amount Average`,
    ROUND(AVG(person_emp_length),2) AS `Employment Length Average`,
    ROUND(AVG(loan_int_rate),2) AS `Interest Rate Average`,
    ROUND(AVG(loan_percent_income),2) AS `Loan Percentage of Income Average`,
    ROUND(AVG(cb_person_cred_hist_length),2) AS `Average Credit History Length`,
    ROUND(AVG(yearly_amount),2) AS `Average Yearly Debt Weight (10 yrs assumed)`,
    ROUND(AVG(yr_amnt_to_income),2) AS `Average Yearly Weight to Income`
FROM credit_risk_clean_hard
GROUP BY `Income Class`;

-- Conclusions from this overview:
-- The numbers vary but the dependencies visible in these tables are true for all three of them
-- The lower the income, the lower the employment length, the average credit history length
-- The lower the income, the higher the Default Likelihood
-- The lower the income, the higher the Loan Percentage of Income and the Average Yearly Weight to Income

-- 4.1) Creating Tables
-- --------------------------------------------------------------------------------------------------
-- 4.2) Calculating Correlations

-- Note: The Pearson Correlation Coefficient is of very limited use here because it only measures the linear correlation in changes.
-- 			It would be much better to make a multiple linear regression analysis with significance tests, however,
-- 			this is not possible in MY SQL. This would be one of those steps that should be undertaken with external tools
-- 			like Python in a regular project.

SELECT
-- Income and Age
	ROUND(
		(AVG(person_income * person_age) - AVG(person_income) * AVG(person_age)) 
		/ 
		(STDDEV(person_income) * STDDEV(person_age)),
	2) AS `Correlation Income and Age`,
-- Income and Employment Length
	ROUND(
		(AVG(person_income * person_emp_length) - AVG(person_income) * AVG(person_emp_length)) 
		/ 
		(STDDEV(person_income) * STDDEV(person_emp_length)),
	2) AS `Correlation Income and Employment Length`,
-- Income and Loan Amount
	ROUND(
		(AVG(person_income * loan_amnt) - AVG(person_income) * AVG(loan_amnt)) 
		/ 
		(STDDEV(person_income) * STDDEV(loan_amnt)),
	2) AS `Correlation Income and Loan Amount`,
-- Income and Loan Status
	ROUND(
		(AVG(person_income * loan_status) - AVG(person_income) * AVG(loan_status)) 
		/ 
		(STDDEV(person_income) * STDDEV(loan_status)),
	2) AS `Correlation Income and Loan Status`,
-- Income and Percentage of Loan Amount on Income
	ROUND(
		(AVG(person_income * loan_percent_income) - AVG(person_income) * AVG(loan_percent_income)) 
		/ 
		(STDDEV(person_income) * STDDEV(loan_percent_income)),
	2) AS `Correlation Income and Loan Percentage of Income`,
-- Income and Credit History Length
	ROUND(
		(AVG(person_income * cb_person_cred_hist_length) - AVG(person_income) * AVG(cb_person_cred_hist_length)) 
		/ 
		(STDDEV(person_income) * STDDEV(cb_person_cred_hist_length)),
	2) AS `Correlation Income and Credit History Length`,
-- Income and Yearly Credit Amount
	ROUND(
		(AVG(person_income * yearly_amount) - AVG(person_income) * AVG(yearly_amount)) 
		/ 
		(STDDEV(person_income) * STDDEV(yearly_amount)),
	2) AS `Correlation Income and Yearly Amount Paid Back (assuming 10 yr term)`,
-- Income and Yearly Credit Amount to Income (in %)
	ROUND(
		(AVG(person_income * yr_amnt_to_income) - AVG(person_income) * AVG(yr_amnt_to_income)) 
		/ 
		(STDDEV(person_income) * STDDEV(yr_amnt_to_income)),
	2) AS `Correlation Income and Yearly Amount Paid Back in relation to Income (in %, assuming 10 yr term)`,
-- -- Income and Loan Income Consistency
	ROUND(
		(AVG(person_income * loan_income_consistency) - AVG(person_income) * AVG(loan_income_consistency)) 
		/ 
		(STDDEV(person_income) * STDDEV(loan_income_consistency)),
	2) AS `Correlation Income and Loan Income Consistency`
FROM credit_risk;

-- Correlation Lightly Cleansed Data

SELECT
-- Income and Age
	ROUND(
		(AVG(person_income * person_age) - AVG(person_income) * AVG(person_age)) 
		/ 
		(STDDEV(person_income) * STDDEV(person_age)),
	2) AS `Correlation Income and Age`,
-- Income and Employment Length
	ROUND(
		(AVG(person_income * person_emp_length) - AVG(person_income) * AVG(person_emp_length)) 
		/ 
		(STDDEV(person_income) * STDDEV(person_emp_length)),
	2) AS `Correlation Income and Employment Length`,
-- Income and Loan Amount
	ROUND(
		(AVG(person_income * loan_amnt) - AVG(person_income) * AVG(loan_amnt)) 
		/ 
		(STDDEV(person_income) * STDDEV(loan_amnt)),
	2) AS `Correlation Income and Loan Amount`,
-- Income and Loan Status
	ROUND(
		(AVG(person_income * loan_status) - AVG(person_income) * AVG(loan_status)) 
		/ 
		(STDDEV(person_income) * STDDEV(loan_status)),
	2) AS `Correlation Income and Loan Status`,
-- Income and Percentage of Loan Amount on Income
	ROUND(
		(AVG(person_income * loan_percent_income) - AVG(person_income) * AVG(loan_percent_income)) 
		/ 
		(STDDEV(person_income) * STDDEV(loan_percent_income)),
	2) AS `Correlation Income and Loan Percentage of Income`,
-- Income and Credit History Length
	ROUND(
		(AVG(person_income * cb_person_cred_hist_length) - AVG(person_income) * AVG(cb_person_cred_hist_length)) 
		/ 
		(STDDEV(person_income) * STDDEV(cb_person_cred_hist_length)),
	2) AS `Correlation Income and Credit History Length`,
-- Income and Yearly Credit Amount
	ROUND(
		(AVG(person_income * yearly_amount) - AVG(person_income) * AVG(yearly_amount)) 
		/ 
		(STDDEV(person_income) * STDDEV(yearly_amount)),
	2) AS `Correlation Income and Yearly Amount Paid Back (assuming 10 yr term)`,
-- Income and Yearly Credit Amount to Income (in %)
	ROUND(
		(AVG(person_income * yr_amnt_to_income) - AVG(person_income) * AVG(yr_amnt_to_income)) 
		/ 
		(STDDEV(person_income) * STDDEV(yr_amnt_to_income)),
	2) AS `Correlation Income and Yearly Amount Paid Back in relation to Income (in %, assuming 10 yr term)`
FROM credit_risk_clean_light;

-- Correlation Hard Cleansed Data

SELECT
-- Income and Age
	ROUND(
		(AVG(person_income * person_age) - AVG(person_income) * AVG(person_age)) 
		/ 
		(STDDEV(person_income) * STDDEV(person_age)),
	2) AS `Correlation Income and Age`,
-- Income and Employment Length
	ROUND(
		(AVG(person_income * person_emp_length) - AVG(person_income) * AVG(person_emp_length)) 
		/ 
		(STDDEV(person_income) * STDDEV(person_emp_length)),
	2) AS `Correlation Income and Employment Length`,
-- Income and Loan Amount
	ROUND(
		(AVG(person_income * loan_amnt) - AVG(person_income) * AVG(loan_amnt)) 
		/ 
		(STDDEV(person_income) * STDDEV(loan_amnt)),
	2) AS `Correlation Income and Loan Amount`,
-- Income and Loan Status
	ROUND(
		(AVG(person_income * loan_status) - AVG(person_income) * AVG(loan_status)) 
		/ 
		(STDDEV(person_income) * STDDEV(loan_status)),
	2) AS `Correlation Income and Loan Status`,
-- Income and Percentage of Loan Amount on Income
	ROUND(
		(AVG(person_income * loan_percent_income) - AVG(person_income) * AVG(loan_percent_income)) 
		/ 
		(STDDEV(person_income) * STDDEV(loan_percent_income)),
	2) AS `Correlation Income and Loan Percentage of Income`,
-- Income and Credit History Length
	ROUND(
		(AVG(person_income * cb_person_cred_hist_length) - AVG(person_income) * AVG(cb_person_cred_hist_length)) 
		/ 
		(STDDEV(person_income) * STDDEV(cb_person_cred_hist_length)),
	2) AS `Correlation Income and Credit History Length`,
-- Income and Yearly Credit Amount
	ROUND(
		(AVG(person_income * yearly_amount) - AVG(person_income) * AVG(yearly_amount)) 
		/ 
		(STDDEV(person_income) * STDDEV(yearly_amount)),
	2) AS `Correlation Income and Yearly Amount Paid Back (assuming 10 yr term)`,
-- Income and Yearly Credit Amount to Income (in %)
	ROUND(
		(AVG(person_income * yr_amnt_to_income) - AVG(person_income) * AVG(yr_amnt_to_income)) 
		/ 
		(STDDEV(person_income) * STDDEV(yr_amnt_to_income)),
	2) AS `Correlation Income and Yearly Amount Paid Back in relation to Income (in %, assuming 10 yr term)`
FROM credit_risk_clean_hard;

-- NOTE: There are NULL Values for Employment Length in the non hard cleansed tables
-- 			and there are NULL Values for the Interest Rate in all tables.
-- 			These correlations are incorrect and can maximal serve as approximations because the NULL value per line is not
-- 			calculated for average and stdv values while for the income the line is included
-- 			Therefore, I will calculate those correlations again, ignoring those lines.

-- At this point: It is visible that Correlations and Averages do not deviate by much between original, light clean and hard clean data
-- For Time Reasons, I will continue with the light clean dataset only

SELECT
-- Interest Rate & Income
	ROUND(
		(AVG(person_income * loan_int_rate) - AVG(person_income) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(person_income) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Income`,
-- Interest Rate & Age
	ROUND(
		(AVG(person_age * loan_int_rate) - AVG(person_age) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(person_age) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rage & Age`,
-- Interest Rate & Age
	ROUND(
		(AVG(person_age * loan_int_rate) - AVG(person_age) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(person_age) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Age`,
-- Interest Rate & Employment Length
	ROUND(
		(AVG(person_emp_length * loan_int_rate) - AVG(person_emp_length) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(person_emp_length) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Employment Length`,
-- Interest Rate & Loan Amount
	ROUND(
		(AVG(loan_amnt * loan_int_rate) - AVG(loan_amnt) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(loan_amnt) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Loan Amount`,
-- Interest Rate & Loan Status
	ROUND(
		(AVG(loan_status * loan_int_rate) - AVG(loan_status) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(loan_status) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Loan Status`,
-- Interest Rate & Percentage of Lone Amount to Income
	ROUND(
		(AVG(loan_percent_income * loan_int_rate) - AVG(loan_percent_income) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(loan_percent_income) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Loan Amount / Income`,
-- Interest Rate & Credit History
	ROUND(
		(AVG(cb_person_cred_hist_length * loan_int_rate) - AVG(cb_person_cred_hist_length) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(cb_person_cred_hist_length) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Credit History`,
-- Interest Rate & Employment Age Difference
	ROUND(
		(AVG(emp_age_diff * loan_int_rate) - AVG(emp_age_diff) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(emp_age_diff) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Employment Age Difference`,
-- Interest Rate & Yearly Amount
	ROUND(
		(AVG(yearly_amount * loan_int_rate) - AVG(yearly_amount) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(yearly_amount) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Yearly Debt to be paid back (assuming 10 yr term)`,
-- Interest Rate & Yearly Amount / Income
	ROUND(
		(AVG(yr_amnt_to_income * loan_int_rate) - AVG(yr_amnt_to_income) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(yr_amnt_to_income) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Yearly Debt to be paid back / Income (assuming 10 yr term)`,
-- Interest Rate & Loan Grade
	ROUND(
		(AVG(loan_grade_num * loan_int_rate) - AVG(loan_grade_num) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(loan_grade_num) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Loan Grade`
FROM credit_risk_clean_light
WHERE loan_int_rate IS NOT NULL;

-- Inserting Dummy Table into the Feature Engineering section. Calculating Correlations with Dummy variables. 

SELECT * FROM credit_risk_clean_light_dummy LIMIT 100;

SELECT
-- Interest Rate & Default on File (this one had been missing before)
	ROUND(
		(AVG(cb_person_default_on_file_num * loan_int_rate) - AVG(cb_person_default_on_file_num) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(cb_person_default_on_file_num) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Default on File`,
-- Interest Rate & Default on Rent Ownership Dummy
	ROUND(
		(AVG(home_ownership_rent_dummy * loan_int_rate) - AVG(home_ownership_rent_dummy) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(home_ownership_rent_dummy) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Rent Ownership Dummy`,
-- Interest Rate & Default on Own Ownership Dummy
	ROUND(
		(AVG(home_ownership_own_dummy * loan_int_rate) - AVG(home_ownership_own_dummy) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(home_ownership_own_dummy) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Own Ownership Dummy`,
-- Interest Rate & Default on Mortgage Ownership Dummy
	ROUND(
		(AVG(home_ownership_mortgage_dummy * loan_int_rate) - AVG(home_ownership_mortgage_dummy) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(home_ownership_mortgage_dummy) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Mortgage Ownership Dummy`,
-- Interest Rate & Default on Other Ownership Dummy
	ROUND(
		(AVG(home_ownership_other_dummy * loan_int_rate) - AVG(home_ownership_other_dummy) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(home_ownership_other_dummy) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Other Ownership Dummy`
FROM credit_risk_clean_light_dummy
WHERE loan_int_rate IS NOT NULL;

SELECT
-- Interest Rate & Default on Debtconsolidation Purpose Dummy
	ROUND(
		(AVG(loan_intent_debtconsolidation_dummy * loan_int_rate) - AVG(loan_intent_debtconsolidation_dummy) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(loan_intent_debtconsolidation_dummy) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Debt Consolidation Purpose Dummy`,
-- Interest Rate & Education Purpose Dummy
	ROUND(
		(AVG(loan_intent_education_dummy * loan_int_rate) - AVG(loan_intent_education_dummy) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(loan_intent_education_dummy) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Education Purpose Dummy`,
-- Interest Rate & Homeimprovement Purpose Dummy
	ROUND(
		(AVG(loan_intent_homeimprovement_dummy * loan_int_rate) - AVG(loan_intent_homeimprovement_dummy) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(loan_intent_homeimprovement_dummy) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Home Improvement Purpose Dummy`,
-- Interest Rate & Medical Purpose Dummy
	ROUND(
		(AVG(loan_intent_medical_dummy * loan_int_rate) - AVG(loan_intent_medical_dummy) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(loan_intent_medical_dummy) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Medical Purpose Dummy`,
-- Interest Rate & Personal Purpose Dummy
	ROUND(
		(AVG(loan_intent_personal_dummy * loan_int_rate) - AVG(loan_intent_personal_dummy) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(loan_intent_personal_dummy) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Medical Purpose Dummy`,
-- Interest Rate & Venture Purpose Dummy
	ROUND(
		(AVG(loan_intent_venture_dummy * loan_int_rate) - AVG(loan_intent_venture_dummy) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(loan_intent_venture_dummy) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Venture Purpose Dummy`
FROM credit_risk_clean_light_dummy
WHERE loan_int_rate IS NOT NULL;

-- Calculating employment length again, for it was not restrained to exclude NULL values in the calculation before:

SELECT * FROM credit_risk_clean_light_dummy LIMIT 100;

SELECT
	ROUND(
		(AVG(person_emp_length * loan_int_rate) - AVG(person_emp_length) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(person_emp_length) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Employment Length`
FROM credit_risk_clean_light_dummy
WHERE loan_int_rate IS NOT NULL
AND person_emp_length IS NOT NULL;

-- Given that the correlation with Employment Length is 0, it is interesting if the correlation with Employment Rage Age Difference
-- Employment Age Difference includes all values that are inconsistent with the persons age.
-- It is possible that therefore people believe it plays a role while it actually doesn't and therefore fake the employment length.

SELECT
	ROUND(
		(AVG(emp_age_diff * loan_int_rate) - AVG(emp_age_diff) * AVG(loan_int_rate)) 
		/ 
		(STDDEV(emp_age_diff) * STDDEV(loan_int_rate)),
	2) AS `Correlation Interest Rate & Employment Length Age Difference`
FROM credit_risk_clean_light_dummy
WHERE loan_int_rate IS NOT NULL;

-- The result (0.05) is still very close to 0, meaning there is no impact. It is possible that people fake this number out of a
-- 	false believe, however, the interest rate is determined by different facotrs. It can also be cause by a technical error.

-- Since the correlation between interest rate and loan grade is really high it can be assumed that the loan grade is the
-- 	primary factor that determines the interest rate, which makes sense from an intuitive perspective
-- Therefore the correlations between the variables and the loan grade should be checked. They will likely be similar to
-- 	the correlations with the interest rate
-- Note: It is not clear if the loan grade is continuous or ordinal.

SELECT
-- Loan Grade & Income
	ROUND(
		(AVG(person_income * loan_grade_num) - AVG(person_income) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(person_income) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Income`,
-- Loan Grade & Age
	ROUND(
		(AVG(person_age * loan_grade_num) - AVG(person_age) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(person_age) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Age`,
-- Loan Grade & Loan Amount
	ROUND(
		(AVG(loan_amnt * loan_grade_num) - AVG(loan_amnt) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(loan_amnt) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Loan Amount`,
-- Loan Grade & Loan Status
	ROUND(
		(AVG(loan_status * loan_grade_num) - AVG(loan_status) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(loan_status) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Loan Status`,
-- Loan Grade & Percentage of Lone Amount to Income
	ROUND(
		(AVG(loan_percent_income * loan_grade_num) - AVG(loan_percent_income) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(loan_percent_income) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Loan Amount / Income`,
-- Loan Grade & Credit History
	ROUND(
		(AVG(cb_person_cred_hist_length * loan_grade_num) - AVG(cb_person_cred_hist_length) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(cb_person_cred_hist_length) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Credit History`,
-- Loan Grade & Employment Age Difference
	ROUND(
		(AVG(emp_age_diff * loan_grade_num) - AVG(emp_age_diff) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(emp_age_diff) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Employment Age Difference`,
-- Loan Grade & Yearly Amount
	ROUND(
		(AVG(yearly_amount * loan_grade_num) - AVG(yearly_amount) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(yearly_amount) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Yearly Debt to be paid back (assuming 10 yr term)`,
-- Loan Grade & Yearly Amount / Income
	ROUND(
		(AVG(yr_amnt_to_income * loan_grade_num) - AVG(yr_amnt_to_income) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(yr_amnt_to_income) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Yearly Debt to be paid back / Income (assuming 10 yr term)`,
-- Loan Grade & Default on File
	ROUND(
		(AVG(cb_person_default_on_file_num * loan_grade_num) - AVG(cb_person_default_on_file_num) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(cb_person_default_on_file_num) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Default on File`
FROM credit_risk_clean_light;

SELECT
-- Loan Grade & Employment Length
	ROUND(
		(AVG(person_emp_length * loan_grade_num) - AVG(person_emp_length) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(person_emp_length) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Employment Length`
FROM credit_risk_clean_light
WHERE person_emp_length IS NOT NULL;

-- Ownership Correlation:

SELECT
-- Loan Grade & Default on Rent Ownership Dummy
	ROUND(
		(AVG(home_ownership_rent_dummy * loan_grade_num) - AVG(home_ownership_rent_dummy) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(home_ownership_rent_dummy) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Rent Ownership Dummy`,
-- Loan Grade & Default on Own Ownership Dummy
	ROUND(
		(AVG(home_ownership_own_dummy * loan_grade_num) - AVG(home_ownership_own_dummy) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(home_ownership_own_dummy) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Own Ownership Dummy`,
-- Loan Grade & Default on Mortgage Ownership Dummy
	ROUND(
		(AVG(home_ownership_mortgage_dummy * loan_grade_num) - AVG(home_ownership_mortgage_dummy) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(home_ownership_mortgage_dummy) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Mortgage Ownership Dummy`,
-- Loan Grade & Default on Other Ownership Dummy
	ROUND(
		(AVG(home_ownership_other_dummy * loan_grade_num) - AVG(home_ownership_other_dummy) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(home_ownership_other_dummy) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Other Ownership Dummy`
FROM credit_risk_clean_light_dummy
WHERE loan_int_rate IS NOT NULL;

-- Loan Purpose Dummy
SELECT
-- Loan Grade & Default on Debtconsolidation Purpose Dummy
	ROUND(
		(AVG(loan_intent_debtconsolidation_dummy * loan_grade_num) - AVG(loan_intent_debtconsolidation_dummy) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(loan_intent_debtconsolidation_dummy) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Debt Consolidation Purpose Dummy`,
-- Loan Grade & Education Purpose Dummy
	ROUND(
		(AVG(loan_intent_education_dummy * loan_grade_num) - AVG(loan_intent_education_dummy) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(loan_intent_education_dummy) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Education Purpose Dummy`,
-- Loan Grade & Homeimprovement Purpose Dummy
	ROUND(
		(AVG(loan_intent_homeimprovement_dummy * loan_grade_num) - AVG(loan_intent_homeimprovement_dummy) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(loan_intent_homeimprovement_dummy) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Home Improvement Purpose Dummy`,
-- Loan Grade & Medical Purpose Dummy
	ROUND(
		(AVG(loan_intent_medical_dummy * loan_grade_num) - AVG(loan_intent_medical_dummy) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(loan_intent_medical_dummy) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Medical Purpose Dummy`,
-- Loan Grade & Personal Purpose Dummy
	ROUND(
		(AVG(loan_intent_personal_dummy * loan_grade_num) - AVG(loan_intent_personal_dummy) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(loan_intent_personal_dummy) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Medical Purpose Dummy`,
-- Loan Grade & Venture Purpose Dummy
	ROUND(
		(AVG(loan_intent_venture_dummy * loan_grade_num) - AVG(loan_intent_venture_dummy) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(loan_intent_venture_dummy) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Venture Purpose Dummy`
FROM credit_risk_clean_light_dummy
WHERE loan_int_rate IS NOT NULL;

-- Loan Status Correlations:

SELECT
-- Loan Status & Income
	ROUND(
		(AVG(person_income * loan_status) - AVG(person_income) * AVG(loan_status)) 
		/ 
		(STDDEV(person_income) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Income`,
-- Loan Status & Age
	ROUND(
		(AVG(person_age * loan_status) - AVG(person_age) * AVG(loan_status)) 
		/ 
		(STDDEV(person_age) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Age`,
-- Loan Status & Loan Amount
	ROUND(
		(AVG(loan_amnt * loan_status) - AVG(loan_amnt) * AVG(loan_status)) 
		/ 
		(STDDEV(loan_amnt) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Loan Amount`,
-- Loan Grade & Loan Status
	ROUND(
		(AVG(loan_status * loan_grade_num) - AVG(loan_status) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(loan_status) * STDDEV(loan_grade_num)),
	2) AS `Correlation Loan Grade & Loan Status`,
-- Loan Status & Percentage of Lone Amount to Income
	ROUND(
		(AVG(loan_percent_income * loan_status) - AVG(loan_percent_income) * AVG(loan_status)) 
		/ 
		(STDDEV(loan_percent_income) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Loan Amount / Income`,
-- Loan Status & Credit History
	ROUND(
		(AVG(cb_person_cred_hist_length * loan_status) - AVG(cb_person_cred_hist_length) * AVG(loan_status)) 
		/ 
		(STDDEV(cb_person_cred_hist_length) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Credit History`,
-- Loan Status & Employment Age Difference
	ROUND(
		(AVG(emp_age_diff * loan_status) - AVG(emp_age_diff) * AVG(loan_status)) 
		/ 
		(STDDEV(emp_age_diff) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Employment Age Difference`,
-- Loan Status & Yearly Amount
	ROUND(
		(AVG(yearly_amount * loan_status) - AVG(yearly_amount) * AVG(loan_status)) 
		/ 
		(STDDEV(yearly_amount) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Yearly Debt to be paid back (assuming 10 yr term)`,
-- Loan Status & Yearly Amount / Income
	ROUND(
		(AVG(yr_amnt_to_income * loan_status) - AVG(yr_amnt_to_income) * AVG(loan_status)) 
		/ 
		(STDDEV(yr_amnt_to_income) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Yearly Debt to be paid back / Income (assuming 10 yr term)`,
-- Loan Status & Default on File
	ROUND(
		(AVG(cb_person_default_on_file_num * loan_status) - AVG(cb_person_default_on_file_num) * AVG(loan_status)) 
		/ 
		(STDDEV(cb_person_default_on_file_num) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Default on File`
FROM credit_risk_clean_light;

SELECT
-- Loan Status & Employment Length
	ROUND(
		(AVG(person_emp_length * loan_status) - AVG(person_emp_length) * AVG(loan_status)) 
		/ 
		(STDDEV(person_emp_length) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Employment Length`
FROM credit_risk_clean_light
WHERE person_emp_length IS NOT NULL;

-- Ownership Correlation
SELECT
-- Loan Status & Default on Rent Ownership Dummy
	ROUND(
		(AVG(home_ownership_rent_dummy * loan_status) - AVG(home_ownership_rent_dummy) * AVG(loan_status)) 
		/ 
		(STDDEV(home_ownership_rent_dummy) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Rent Ownership Dummy`,
-- Loan Status & Default on Own Ownership Dummy
	ROUND(
		(AVG(home_ownership_own_dummy * loan_status) - AVG(home_ownership_own_dummy) * AVG(loan_status)) 
		/ 
		(STDDEV(home_ownership_own_dummy) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Own Ownership Dummy`,
-- Loan Status & Default on Mortgage Ownership Dummy
	ROUND(
		(AVG(home_ownership_mortgage_dummy * loan_status) - AVG(home_ownership_mortgage_dummy) * AVG(loan_status)) 
		/ 
		(STDDEV(home_ownership_mortgage_dummy) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Mortgage Ownership Dummy`,
-- Loan Status & Default on Other Ownership Dummy
	ROUND(
		(AVG(home_ownership_other_dummy * loan_status) - AVG(home_ownership_other_dummy) * AVG(loan_status)) 
		/ 
		(STDDEV(home_ownership_other_dummy) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Other Ownership Dummy`
FROM credit_risk_clean_light_dummy;

-- Loan Purpose Correlation

SELECT
-- Loan Status & Default on Debtconsolidation Purpose Dummy
	ROUND(
		(AVG(loan_intent_debtconsolidation_dummy * loan_status) - AVG(loan_intent_debtconsolidation_dummy) * AVG(loan_status)) 
		/ 
		(STDDEV(loan_intent_debtconsolidation_dummy) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Debt Consolidation Purpose Dummy`,
-- Loan Status & Education Purpose Dummy
	ROUND(
		(AVG(loan_intent_education_dummy * loan_status) - AVG(loan_intent_education_dummy) * AVG(loan_status)) 
		/ 
		(STDDEV(loan_intent_education_dummy) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Education Purpose Dummy`,
-- Loan Status & Homeimprovement Purpose Dummy
	ROUND(
		(AVG(loan_intent_homeimprovement_dummy * loan_status) - AVG(loan_intent_homeimprovement_dummy) * AVG(loan_status)) 
		/ 
		(STDDEV(loan_intent_homeimprovement_dummy) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Home Improvement Purpose Dummy`,
-- Loan Status & Medical Purpose Dummy
	ROUND(
		(AVG(loan_intent_medical_dummy * loan_status) - AVG(loan_intent_medical_dummy) * AVG(loan_status)) 
		/ 
		(STDDEV(loan_intent_medical_dummy) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Medical Purpose Dummy`,
-- Loan Status & Personal Purpose Dummy
	ROUND(
		(AVG(loan_intent_personal_dummy * loan_status) - AVG(loan_intent_personal_dummy) * AVG(loan_status)) 
		/ 
		(STDDEV(loan_intent_personal_dummy) * STDDEV(loan_status)),
	2) AS `Correlation Loan Grade & Medical Purpose Dummy`,
-- Loan Status & Venture Purpose Dummy
	ROUND(
		(AVG(loan_intent_venture_dummy * loan_status) - AVG(loan_intent_venture_dummy) * AVG(loan_status)) 
		/ 
		(STDDEV(loan_intent_venture_dummy) * STDDEV(loan_status)),
	2) AS `Correlation Loan Status & Venture Purpose Dummy`
FROM credit_risk_clean_light_dummy;

-- Summary Results:

-- Interest Rate:

-- Interest Rate correlates with Default on File (0.5), Loan Amount (0.13), Loan Status (0.32),
-- 	Loan Amount / Income (0.12, suprious correlation because it correlates with Loan Amount but not with Income),
-- 	Yearly Debt to be paid back (10 yr) (0.32, direct causal impact since the variable is calculated also based on interest rate),
-- 	Yearly Debt to be paid back / Income (0.32, also due to correlation with numerator, no corr to income),
-- 	Loan Grade (0.93, to be expected, it should be assumed that this has the biggest causal impact on interest rate due to policy)

-- Interest Rate does not correlate with Income (-0.01), Age (0.01), Employment Length (-0.05), and Credit History (0.02), and
-- 	Employment Length Diff (-0.05)

-- Interest Rate correlates with Rent Ownership (0.15) and Mortgage (-0.14)
-- The Correlation to Owning Property (-0.01) and Other (0.02) are disappearingly low

-- Interest Rate and Loan Intent have such a low correlation (max 0.03, min -0.03) that it can be assumed that they play no role
-- 	in evaluating the Interest Rate due the current process, or if they do, the role is that insignificant that the effect disappears

-- --

-- Loan Grade:

-- Loan Grade correlates with Default on File (0.54), Loan Amount (0.13), Loan Status (0.35), 
-- 	Loan Amount / Income (0.12 suprious correlation because it correlates with Loan Amount but not with Income),
-- 	Yearly Debt to be paid back (0.31, to be expected, since the interest rate is input and is determined by grade),
-- 	Yearly Debt to be paid back / Income (0.32, same)

-- Loan Grade does not correlate with Income (-0.01), Age (0.01), Credit History (0.01), Employment Age Diff (0.05),

-- Loan Grade correlates with Rent (0.13) and Mortgage (-0.12) Ownership
-- Loan Grade does not correlate with Own (-0.02) and Other (0.01) Ownership

-- Loan Grade does not correlate with any Purpose Dummy. Highest: Home Improvement (0.04), Lowest: Medical (-0.04)

-- --

-- So far: Loan Interest Rate is determined by Loan Grade and Loan Grade primarily determined by Default on File
-- It is explicitly not determined by age, employment length and income
-- The question however is: What does the Loan Default really depend on?

-- --

-- Loan Status Correlations:

-- Loan Status Correlates with Income (-0.18), Loan Grade (0.35), Loan Amount / Income (0.39), Yearly Debt to be paid back (10 yr) (0.15),
-- 	Yearly Debt to be paid back / Income (10 yr) (0.44), Default on File (0.17), Employment Length (-0.1)

-- Loan Status does not correlate with Age (-0.02), Loan Amount (0.09), Credit History (-0,02), Employment Age Difference (0.03)

-- Loan Status does correlate with Ownership in terms of Rent (0.25), Own (-0.1), and Mortgage (-0.2).
-- Loan Status does not correlate with Other (0.01)

-- Loan Status does not correlate with 

-- --

-- What we see up to here (premiss: Loan Grade is the one determining factor to determine loan interest rage, r=0.93):

-- List of variables that do not play a role in determining the interest rate but do play a role in people defaulting: Variable (r with loan grade, r with loan status)
-- Income (-0.01, -0.18), Rent (0.13, 0.25), Mortgage (-0.12, -0.2), Own (-0.02, -0.1), Employment Length (0.05, -0.1)

-- List of variables that do not play a stronger in determining the interest rate but do play a role in people defaulting: Variable (r with loan grade, r with loan status)
-- Default on File (0.54, 0.17)

-- Correlation about the same
-- Loan Amount (0.13, 0.09)

-- both uncorrelated
-- Credit History (0.01, 0.01), Employment Age Diff (0.05, 0.03), Age (0.01, -0.02), Other (0.01, 0.01)

-- 4.2) Calculating Correlations
-- --------------------------------------------------------------------------------------------------
-- 4.3) Correlations with t-significance tests

-- To determine wether a variable should play a role in risk assessment, we need to assure that the correlation is different from 0
-- Therefore, in this section we calculate the relevant correlations again but this time we test them for statistical significance
-- For this, we use a t-test with the Nullhypothesis that the correlation r = 0
-- If a result is statistically significant (e.g. with the significance level of 5%) it means that r is different from 0 with
-- 	a likelihood of 95%.
-- This also means that for every 20 correlations that are tested, one will be evaluated as different from 0 with a significance
-- 	level of 5% on average by pure likelihood.

-- The correlations that are analyzed here are pre seleted from the previous section.

-- r (Interest Rate, Loan Status) 0.32***
WITH corr AS (									-- Using WITH to predefine values for t-significancetest
	SELECT
		COUNT(*) AS n,							-- High n (>1000) is absolutely necessary for significance evaluation to be correct
		(AVG(loan_int_rate * loan_status) - AVG(loan_int_rate) * AVG(loan_status)) 
		/ 
		(STDDEV(loan_int_rate) * STDDEV(loan_status)) AS r			-- Peason correlation coefficient
	FROM credit_risk_clean_light
    WHERE loan_int_rate IS NOT NULL
      AND loan_status IS NOT NULL
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				-- ABS is the absolute value (betrag) for a two sided t-test
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Interest Rate, Loan Status) 0.32***

-- r (Loan Grade, Loan Status) 0.36***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(loan_grade_num * loan_status) - AVG(loan_grade_num) * AVG(loan_status)) 
		/ 
		(STDDEV(loan_grade_num) * STDDEV(loan_status)) AS r			
	FROM credit_risk_clean_light
    WHERE loan_int_rate IS NOT NULL
      AND loan_status IS NOT NULL
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Grade, Loan Status) 0.36***

-- r (Loan Grade, Income) -0.01*
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(loan_grade_num * person_income) - AVG(loan_grade_num) * AVG(person_income)) 
		/ 
		(STDDEV(loan_grade_num) * STDDEV(person_income)) AS r			
	FROM credit_risk_clean_light
    WHERE loan_int_rate IS NOT NULL
      AND loan_status IS NOT NULL
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Grade, Income) -0.01*

-- r (Income, Loan Status) -0.19***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(person_income * loan_status) - AVG(person_income) * AVG(loan_status)) 
		/ 
		(STDDEV(person_income) * STDDEV(loan_status)) AS r			
	FROM credit_risk_clean_light
    WHERE loan_int_rate IS NOT NULL
      AND loan_status IS NOT NULL
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Income, Loan Status) -0.19***

-- r (Loan Grade, Loan Amount) 0.13***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(loan_amnt * loan_grade_num) - AVG(loan_amnt) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(loan_amnt) * STDDEV(loan_grade_num)) AS r			
	FROM credit_risk_clean_light
    WHERE loan_int_rate IS NOT NULL
      AND loan_status IS NOT NULL
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Grade, Loan Amount) 0.13***

-- r (Loan Status, Loan Amount) 0.09***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(loan_amnt * loan_status) - AVG(loan_amnt) * AVG(loan_status)) 
		/ 
		(STDDEV(loan_amnt) * STDDEV(loan_status)) AS r			
	FROM credit_risk_clean_light
    WHERE loan_int_rate IS NOT NULL
      AND loan_status IS NOT NULL
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Status, Loan Amount) 0.09***

-- r (Loan Grade, Age) 0.01**
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(person_age * loan_grade_num) - AVG(person_age) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(person_age) * STDDEV(loan_grade_num)) AS r			
	FROM credit_risk_clean_light
    WHERE loan_int_rate IS NOT NULL
      AND loan_status IS NOT NULL
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Grade, Age) 0.01**

-- r (Loan Status, Age) -0.02***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(person_age * loan_status) - AVG(person_age) * AVG(loan_status)) 
		/ 
		(STDDEV(person_age) * STDDEV(loan_status)) AS r			
	FROM credit_risk_clean_light
    WHERE loan_int_rate IS NOT NULL
      AND loan_status IS NOT NULL
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Status, Age) -0.02***

-- r (Loan Grade, Credit History) 0.01**
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(cb_person_cred_hist_length * loan_grade_num) - AVG(cb_person_cred_hist_length) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(cb_person_cred_hist_length) * STDDEV(loan_grade_num)) AS r			
	FROM credit_risk_clean_light
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Grade, Credit History) 0.01**

-- r (Loan Status, Credit History) -0.02***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(cb_person_cred_hist_length * loan_status) - AVG(cb_person_cred_hist_length) * AVG(loan_status)) 
		/ 
		(STDDEV(cb_person_cred_hist_length) * STDDEV(loan_status)) AS r			
	FROM credit_risk_clean_light
    WHERE loan_int_rate IS NOT NULL
      AND loan_status IS NOT NULL
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Status, Credit History) -0.02***

-- r (Loan Grade, Rent) 0.13***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(home_ownership_rent_dummy * loan_grade_num) - AVG(home_ownership_rent_dummy) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(home_ownership_rent_dummy) * STDDEV(loan_grade_num)) AS r			
	FROM credit_risk_clean_light_dummy
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Grade, Rent) 0.13***

-- r (Loan Status, Rent) 0.25***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(home_ownership_rent_dummy * loan_status) - AVG(home_ownership_rent_dummy) * AVG(loan_status)) 
		/ 
		(STDDEV(home_ownership_rent_dummy) * STDDEV(loan_status)) AS r			
	FROM credit_risk_clean_light_dummy
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Status, Rent) 0.25***

-- r (Loan Grade, Own) -0.01***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(home_ownership_own_dummy * loan_grade_num) - AVG(home_ownership_own_dummy) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(home_ownership_own_dummy) * STDDEV(loan_grade_num)) AS r			
	FROM credit_risk_clean_light_dummy
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Grade, Own) -0.01***

-- r (Loan Status, Own) -0.1***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(home_ownership_own_dummy * loan_status) - AVG(home_ownership_own_dummy) * AVG(loan_status)) 
		/ 
		(STDDEV(home_ownership_own_dummy) * STDDEV(loan_status)) AS r			
	FROM credit_risk_clean_light_dummy
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Status, Own) -0.1***

-- r (Loan Grade, Mortgage) -0.12***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(home_ownership_mortgage_dummy * loan_grade_num) - AVG(home_ownership_mortgage_dummy) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(home_ownership_mortgage_dummy) * STDDEV(loan_grade_num)) AS r			
	FROM credit_risk_clean_light_dummy
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Grade, Mortgage) -0.12***

-- r (Loan Status, Mortgage) -0.2***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(home_ownership_mortgage_dummy * loan_status) - AVG(home_ownership_mortgage_dummy) * AVG(loan_status)) 
		/ 
		(STDDEV(home_ownership_mortgage_dummy) * STDDEV(loan_status)) AS r			
	FROM credit_risk_clean_light_dummy
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Status, Mortgage) -0.2***

-- r (Loan Grade, Other) 0.02***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(home_ownership_other_dummy * loan_grade_num) - AVG(home_ownership_other_dummy) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(home_ownership_other_dummy) * STDDEV(loan_grade_num)) AS r			
	FROM credit_risk_clean_light_dummy
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Grade, Other) 0.02***

-- r (Loan Status, Other) 0.01**
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(home_ownership_other_dummy * loan_status) - AVG(home_ownership_other_dummy) * AVG(loan_status)) 
		/ 
		(STDDEV(home_ownership_other_dummy) * STDDEV(loan_status)) AS r			
	FROM credit_risk_clean_light_dummy
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Status, Mortgage) 0.01**

-- Result: All important key variables are statistically significant. All >0.1 or <-0.1 are significant on a significance level of 1%,
-- 	and even those closer to 0 are significant to at least a significance level of 10%.

-- 4.3) Correlations with t-significance tests
-- --------------------------------------------------------------------------------------------------
-- 4.4) Calculating probabilities

-- Starting with income and the loan default probability
WITH categorized AS (
    SELECT
        person_income,
        loan_status,
        NTILE(4) OVER (ORDER BY person_income) AS income_category
    FROM credit_risk_clean_light
)
SELECT
    income_category,
    COUNT(*) AS total_loans,
    SUM(loan_status) AS defaults,
    ROUND(SUM(loan_status) / COUNT(*), 4) AS default_probability
FROM categorized
GROUP BY income_category
ORDER BY income_category;
-- We see a clear tendency that the smaller the income the higher the defaults, yet defaults correlates with income on a relatively low scale: -0.19***
-- That is primarily because the default risk depends on various factors that themselves tend to correlate with defaults

SELECT * FROM credit_risk_clean_light LIMIT 100;

SELECT
	loan_grade,
    ROUND(AVG(person_income), 2) AS average_income,
    ROUND(AVG(loan_int_rate), 4) AS average_interest_rate,
    ROUND(AVG(cb_person_cred_hist_length), 4) AS average_credit_history_length,
    ROUND(AVG(cb_person_default_on_file_num), 4) AS percentage_people_defaulted_previously,
    ROUND(SUM(loan_status) / COUNT(*), 4) AS default_probability
FROM credit_risk_clean_light
GROUP BY loan_grade
ORDER BY loan_grade;

WITH categorized AS (
	SELECT
		loan_grade,
		person_income,
		loan_status,
		NTILE(4) OVER (ORDER BY person_income) AS income_category
	FROM credit_risk_clean_light
)
SELECT
	loan_grade,
	SUM(CASE WHEN income_category = 1 THEN 1 ELSE 0 END) AS `Loans in Income Category 1`,
    SUM(CASE WHEN income_category = 2 THEN 1 ELSE 0 END) AS `Loans in Income Category 2`,
    SUM(CASE WHEN income_category = 3 THEN 1 ELSE 0 END) AS `Loans in Income Category 3`,
    SUM(CASE WHEN income_category = 4 THEN 1 ELSE 0 END) AS `Loans in Income Category 4`,
    ROUND(SUM(loan_status) / COUNT(*), 4) AS default_probability
FROM categorized
GROUP BY loan_grade
ORDER BY loan_grade;

-- 4.4) Calculating probabilities
-- --------------------------------------------------------------------------------------------------
-- 5) Developing the Credit Risk model

-- What we have so far is linear correlation between factors. It would be much better to base the analysis on a multivariate linear regression with significance tests,
-- 	however, this is unrealistic to do within SQL, especially within the timeframe of the project (6 working days).
-- How to proceed: The values will be standardized to transform them into a comparable number without unit measuring. This is necessary because a high number (e.g. Income)
-- 	would impact the socoring much more than a relatively low number (e.g. a Dummy variable that is either 0 or 1)
-- The correlations will then weight these factors based on their linear dependency between them and the default of loans. These weights will then be included in a weight table.
-- A Score table will show which credit is scored in which way. This will serve as final table to evaluate the loans.

-- 5.1) Building a Scoring Table based on correlations

DROP TABLE IF EXISTS scoring_weights;

CREATE TABLE scoring_weights (
    weight_name_cor VARCHAR(50) PRIMARY KEY,
    weight DOUBLE
);

INSERT INTO scoring_weights VALUES
	('loan_status_&_person_income',
		(SELECT						
		(AVG(person_income * loan_status) - AVG(person_income) * AVG(loan_status)) 
		/ 
		(STDDEV(person_income) * STDDEV(loan_status)) AS r			
		FROM credit_risk_clean_light_dummy)
	),
    ('loan_status_&_person_emp_length',
		(SELECT						
		(AVG(person_emp_length * loan_status) - AVG(person_emp_length) * AVG(loan_status)) 
		/ 
		(STDDEV(person_emp_length) * STDDEV(loan_status)) AS r			
		FROM credit_risk_clean_light_dummy
        WHERE person_emp_length IS NOT NULL)
	),
        ('loan_status_&_loan_amnt',
		(SELECT						
		(AVG(loan_amnt * loan_status) - AVG(loan_amnt) * AVG(loan_status)) 
		/ 
		(STDDEV(loan_amnt) * STDDEV(loan_status)) AS r			
		FROM credit_risk_clean_light_dummy)
	),
        ('loan_status_&_loan_percent_income',
		(SELECT						
		(AVG(loan_percent_income * loan_status) - AVG(loan_percent_income) * AVG(loan_status)) 
		/ 
		(STDDEV(loan_percent_income) * STDDEV(loan_status)) AS r			
		FROM credit_risk_clean_light_dummy)
	),
		('loan_status_&_cb_person_default_on_file_num',
		(SELECT							
		(AVG(cb_person_default_on_file_num * loan_status) - AVG(cb_person_default_on_file_num) * AVG(loan_status)) 
		/ 
		(STDDEV(cb_person_default_on_file_num) * STDDEV(loan_status)) AS r			
		FROM credit_risk_clean_light_dummy)
	),
		('loan_status_&_home_ownership_rent_dummy',
		(SELECT							
		(AVG(home_ownership_rent_dummy * loan_status) - AVG(home_ownership_rent_dummy) * AVG(loan_status)) 
		/ 
		(STDDEV(home_ownership_rent_dummy) * STDDEV(loan_status)) AS r			
		FROM credit_risk_clean_light_dummy)
	),
		('loan_status_&_home_ownership_own_dummy',
		(SELECT							
		(AVG(home_ownership_own_dummy * loan_status) - AVG(home_ownership_own_dummy) * AVG(loan_status)) 
		/ 
		(STDDEV(home_ownership_own_dummy) * STDDEV(loan_status)) AS r			
		FROM credit_risk_clean_light_dummy)
	),
		('loan_status_&_home_ownership_mortgage_dummy',
		(SELECT							
		(AVG(home_ownership_mortgage_dummy * loan_status) - AVG(home_ownership_mortgage_dummy) * AVG(loan_status)) 
		/ 
		(STDDEV(home_ownership_mortgage_dummy) * STDDEV(loan_status)) AS r			
		FROM credit_risk_clean_light_dummy)
	);

-- 5.1) Building a Scoring Table based on correlations
-- --------------------------------------------------------------------------------------------------
-- 5.2) Normalizing, Standardizing and Weighting Data

SELECT * FROM credit_risk_clean_light LIMIT 10;

DROP TABLE IF EXISTS credit_risk_clean_light_standardized;

-- Dummy Variables will neither be normalized nor standardized. This decision is taken because Dummy Variables are either 0 or 1. If they are standardized then Dummy variables
-- 	with few 1 vaulues are overvalued. 
-- I check the distribution of the data by plotting all values of one variable as a histogram in Excel. This visual approximation must be enought because there are no tests for
-- 	variables to be normally distributed in SQL. If a Variable is heuristically normally distributed (more or less the same density around the arithmetic mean), it will directly
-- 	be standardized.
-- For variables that have a skew in their distribution (e.g. income) a normalization will take place before the standartization. As a normalization technique I chose to apply
-- 	the log function because this is know to especially reduce the effect of outliers.

-- Checking for Values <= 0 before applying log function, such values would not be defined for log.
SELECT MIN(person_income) FROM credit_risk_clean_light_dummy;
SELECT MIN(person_emp_length) FROM credit_risk_clean_light_dummy;
SELECT MIN(loan_amnt) FROM credit_risk_clean_light_dummy;			-- I didn't expect this to be <= 0 but double checking is safe

-- Creating Table
CREATE TABLE credit_risk_clean_light_standardized AS
-- Here, all features are normalized using the log function if their distribution it too heavily skewed.
WITH normalized_data AS(
	SELECT
		credit_id,
		log(person_income) AS person_income,
        log(person_emp_length+1) AS person_emp_length,		-- There are values of 0 in the variable. 0 is not defined. +1 gradually applies changes the data marginally but keeps the type of distribution
        log(loan_amnt) AS loan_amnt,
        loan_status,
        loan_percent_income,
        yearly_amount,
        yr_amnt_to_income,
        cb_person_default_on_file_num,
		home_ownership_rent_dummy,
		home_ownership_own_dummy,
		home_ownership_mortgage_dummy
	FROM credit_risk_clean_light_dummy)
-- here, the line "(a - AVG(a) OVER ()) / STDEV(a) OVER()" standardizes the data. This is simply the formula for standartization converted into my SQL code.
-- This formula is then set into () and multiplied with the weight being the correlation coefficient between the respective variable a and loan_status
-- The sum of this value will be what determines in which category the Debtor will end up
SELECT
	n.credit_id,
    ((n.person_income - AVG(n.person_income) OVER()) / STDDEV(n.person_income) OVER()) * w_income.weight AS person_income,
    ((n.person_emp_length - AVG(n.person_emp_length) OVER()) / STDDEV(n.person_emp_length) OVER()) * w_emp_length.weight AS person_emp_length,
    ((n.loan_amnt - AVG(n.loan_amnt) OVER()) / STDDEV(n.loan_amnt) OVER()) * w_loan_amnt.weight AS loan_amnt,
    n.loan_status,
    ((n.loan_percent_income - AVG(n.loan_percent_income) OVER()) / STDDEV(n.loan_percent_income) OVER()) * w_loan_percent_income.weight AS loan_percent_income,
    -- (yearly_amount - AVG(yearly_amount) OVER()) / STDDEV(yearly_amount) OVER() AS yearly_amount,
    -- (yr_amnt_to_income - AVG(yr_amnt_to_income) OVER()) / STDDEV(yr_amnt_to_income) OVER() AS yr_amnt_to_income,
    n.cb_person_default_on_file_num * w_default_on_file.weight AS cb_person_default_on_file_num,
    n.home_ownership_rent_dummy * w_home_ownership_rent_dummy.weight AS home_ownership_rent_dummy,
    n.home_ownership_own_dummy * w_home_ownership_own_dummy.weight AS home_ownership_own_dummy,
    n.home_ownership_mortgage_dummy * w_home_ownership_mortgage_dummy.weight AS home_ownership_mortgage_dummy
FROM normalized_data AS n
-- These Joins only exist to access the previously calculated correlation coefficients. I didn't want to add another layer to the structure so I tried to put it all into this table
JOIN scoring_weights AS w_income ON w_income.weight_name_cor = 'loan_status_&_person_income'
JOIN scoring_weights AS w_emp_length ON w_emp_length.weight_name_cor = 'loan_status_&_person_emp_length'
JOIN scoring_weights AS w_loan_amnt ON w_loan_amnt.weight_name_cor = 'loan_status_&_loan_amnt'
JOIN scoring_weights AS w_loan_percent_income ON w_loan_percent_income.weight_name_cor = 'loan_status_&_loan_percent_income'
JOIN scoring_weights AS w_default_on_file ON w_default_on_file.weight_name_cor = 'loan_status_&_cb_person_default_on_file_num'
JOIN scoring_weights AS w_home_ownership_rent_dummy ON w_home_ownership_rent_dummy.weight_name_cor = 'loan_status_&_home_ownership_rent_dummy'
JOIN scoring_weights AS w_home_ownership_own_dummy ON w_home_ownership_own_dummy.weight_name_cor = 'loan_status_&_home_ownership_own_dummy'
JOIN scoring_weights AS w_home_ownership_mortgage_dummy ON w_home_ownership_mortgage_dummy.weight_name_cor = 'loan_status_&_home_ownership_mortgage_dummy';
-- yearly_amount is dependent from the interest rate, this operation is to set an optimized interest rate. An iterative process like this could be applied in Python, yet not SQL.
-- loan status will be kept to measure the likelihood of the debtors paying the loan back after scoring
-- credit_id will be kept as primary key

SELECT * FROM credit_risk_clean_light_standardized LIMIT 50;

-- 5.2) Normalizing, Standardizing and Weighting Data
-- --------------------------------------------------------------------------------------------------
-- 5.3) Developing the final Score Table

-- We start off with credit_risk_clean_light_standardized that contains normalized, standardized and weighted Data that brings each loan into an ordinally scaled order
-- 	for loan default risk.
-- The goal is to put these loans into 6 groups, not with equally many loans in each, but with equally large portions of the final scoring value from max to min.

-- Creating the table
DROP TABLE IF EXISTS score;
    
CREATE TABLE score AS
SELECT
    credit_id,
    loan_status,
    CAST(
        ROUND(COALESCE(person_income, 0), 4) +
        ROUND(COALESCE(person_emp_length, 0), 4) +
        ROUND(COALESCE(loan_amnt, 0), 4) +
        ROUND(COALESCE(loan_percent_income, 0), 4) +
        ROUND(COALESCE(cb_person_default_on_file_num, 0), 4) +
        ROUND(COALESCE(home_ownership_rent_dummy, 0), 4) +
        ROUND(COALESCE(home_ownership_own_dummy, 0), 4) +
        ROUND(COALESCE(home_ownership_mortgage_dummy, 0), 4)
    AS DECIMAL(12,4)) AS score_value
FROM credit_risk_clean_light_standardized;

-- Determining a Risk Class Thresholds in a new Table
DROP TABLE IF EXISTS risk_threshold;

-- The idea is to have such a table such that we have an overview about the thresholds and can fill in the values into the score table
CREATE TABLE risk_threshold (
	risk_class_num INT PRIMARY KEY, 
    lower_threshold DOUBLE, 
    upper_threshold DOUBLE);

-- Variables are set such that they can be used for the calculation of the thresholds
SET @min_score = (SELECT MIN(score_value) FROM score);
SET @max_score = (SELECT MAX(score_value) FROM score);
SET @width = (@max_score - @min_score)/6;

-- Calculating thresholds and inserting them into the table
-- The +0.0001 incrementing is important to not have identical values within two different thresholds. It is important to round the Values on the 4th decimal, otherwise there
-- 	exist values for which no class is defined.
INSERT INTO risk_threshold (risk_class_num, lower_threshold, upper_threshold)
SELECT 1, ROUND(@min_score, 4), ROUND(@min_score + @width, 4)
UNION ALL
SELECT 2, ROUND(@min_score + @width + 0.0001, 4), ROUND(@min_score + 2*@width + 0.0001, 4)
UNION ALL
SELECT 3, ROUND(@min_score + 2*@width + 0.0002, 4), ROUND(@min_score + 3*@width + 0.0002, 4)
UNION ALL
SELECT 4, ROUND(@min_score + 3*@width + 0.0003, 4), ROUND(@min_score + 4*@width + 0.0003, 4)
UNION ALL
SELECT 5, ROUND(@min_score + 4*@width + 0.0004, 4), ROUND(@min_score + 5*@width + 0.0004, 4)
UNION ALL
SELECT 6, ROUND(@min_score + 5*@width + 0.0005, 4), ROUND(@max_score, 4);
-- Note: The higher the score value, the higher the default risk because the value is determined by correlations with loan_stats which is 1 if the client defaults and 0 if he/she
-- 	does not. So positive correlations mean the clients is more likely to default while lower correlations mean the client is less likely to default. Therefore, the lower the score
-- 	value the better.

SELECT * FROM risk_threshold;

-- Adding the risk class to the score table
ALTER TABLE score
ADD COLUMN risk_class_num INT;

-- With the combination of JOIN and BETWEEN we add the class depending in which class the score value is located
UPDATE score AS s
JOIN risk_threshold As r ON s.score_value BETWEEN r.lower_threshold AND r.upper_threshold
SET s.risk_class_num = r.risk_class_num;

-- Adding the Risk Class A-F. In terms of Data Management, this is redundant to risk_class_num, but we do it anyways becuase the employees are used to seeing A-F, not 1-6.
-- Existing tools within the departments might be calibrated to A-F. 1-6 will still be kept around because it is easier to calculate with.

-- Adding the column
ALTER TABLE score
ADD COLUMN risk_class VARCHAR(1);

-- Assingning letters to numeric values
UPDATE score
SET risk_class =
	CASE
		WHEN risk_class_num = 1 THEN "A"
        WHEN risk_class_num = 2 THEN "B"
        WHEN risk_class_num = 3 THEN "C"
        WHEN risk_class_num = 4 THEN "D"
        WHEN risk_class_num = 5 THEN "E"
        WHEN risk_class_num = 6 THEN "F"	-- No Else, because if a NULL value comes out the department comes back at us and we can fix a bug we might have overlooked.
    END;

SELECT * FROM score LIMIT 100;

-- Checking for NULL Values
SELECT *
FROM score
WHERE
    credit_id IS NULL
    OR score_value IS NULL
    OR risk_class_num IS NULL;
-- If you, dear revisor, excecute this command, there should be no NULL values.
-- However for me it was very useful, this way I found out that I had to change the score_value to a DECIMAL(something,4) such that no value falls between the thresholds.
-- Code from before has been adapted for bug fixing

-- Calculating the Default Likelihood
DROP TABLE IF EXISTS risk_default;

CREATE TABLE risk_default AS
SELECT risk_class_num, COUNT(credit_id) AS number_of_credits, SUM(loan_status)/COUNT(credit_id) AS default_likelihood FROM score
GROUP BY risk_class_num ORDER BY risk_class_num;

SELECT loan_grade, COUNT(credit_id) AS number_of_credits, SUM(loan_status)/COUNT(credit_id) AS default_likelihood FROM credit_risk_clean_light
GROUP BY loan_grade ORDER BY loan_grade;

ALTER TABLE score
ADD COLUMN default_risk DOUBLE;

UPDATE score AS s
JOIN risk_default AS rd ON s.risk_class_num = rd.risk_class_num
SET s.default_risk = rd.default_likelihood;

-- 5.3) Developing the final Score Table
-- --------------------------------------------------------------------------------------------------
-- 6) Determining the optimal interest rate

-- These things should be considered: Due to the law of great numbers, there is an optimal interest rate that eliminates risk for the loans. Meaning that the loans that do not
-- 	default make that much profit such that they compensate exactly for the loans that do default.
-- When considering this, loans that default still deliver returns. The question always is: At which point in time does the debtor default? This cannot be answered because we have
-- 	no information about neither loan term duration nor about the point in time at which the debtor defaults during the term duration.
-- As before we will therefore make hard assumptions to approximate a solution. We keep the assumption that each loan has a term duration of 10 years. We will furthermore assume
-- 	that when a debtor defaults he / she does so after half of the term duration, meaning 5 years.

-- Besides the risk eliminating interest rate, there is one factor we have not yet considered in our model, which is actually the strongest factor:
-- When the amount a client has to pay back is too heavy, the likelihood of this client defaulting increases drastically
-- This has been shown in the correlation analysis where this value in relation to income had the highest correlation with loan_status (debtors defaulting) compared to all other
-- 	variables. We could not include this into the model so far because the interest rate is an endogenously given variable, meaning we can control it. Thus, the interest rate must
-- 	be considered to be a result from this analysis, not an input. It would make sense to iteratively adapt the model based on changing the interest rate which, again, could be
-- 	done in other tools like python, but not within SQL.
-- Here, we will proceed by visualizing a curve of this value and the amount of people defaulting in form of a histogram (export to excel), and then heuristically selecting a value
-- 	by which the debtor's defaults rise significantly.

-- These two steps will result in an invervall of a minimum interest rate that will only eliminate risk and a maximum interest rate that could be set. The returns within these
-- 	bandwiths can be calculated and then be compared to the returns the bank had using the old model.

-- 6.1) Calculating the risk eliminating interest rate

-- Assumptions: Fixed Term of 10 Years for each loan, if a member defaults, the member defaults after 5 Years.
-- This can actually be calculated without programming anything. We use for the following the Loan Amount as K0, the amount the Loan has to return when fully returned Kt,
-- 	the Loan Term t (here assumed to be 10), the loan interest rate r, the default risk p, and the key interest rate given by the central bank i
-- We will assume that as opportunity cost, the bank could invest in Government Bonds that return the key interest rate i
-- The amount reutrned by the investment is by definition: Kt = (1 + r)^t * K0
-- Solving this formula for r returns: r = (Kt/K0)^(1/t) - 1
-- In this case Kt must return an equivalent to the starting loan rate, multiplied with the key interest rate (representing the opportinity cost) and the default likelihood
-- Here, we can devide the default likelihood by 2, because by assumption half of each loan is returned. If we knew how much percentage of the loans were returned before default
-- 	we could multiply this probability with such a percentage number (decimal format) per risk class instead.
-- Inserting this into the formula, we get: r = ( (1 + p/2 + i)^t K0 / K0)^1/t -1
-- This equation can be reduced to r = p/2 + i
-- This is our risk eliminating interest rate
-- This is a very simplified model. It can be improved by interest accumulation, default variance and other factors such as running costs for the administration of loans. To do this,
-- 	more respective data would be needed.
-- We assume a key interest rate of 2% or 0.02
-- 	see: https://www.aa.com.tr/en/economy/european-central-bank-holds-rates-steady-at-2-matching-expectations/3774838

-- Extending the table
ALTER TABLE score
ADD COLUMN loan_interest_rate_nocost DOUBLE;

UPDATE score
SET loan_interest_rate_nocost = 0.02 + default_risk/2;

-- Adding loan_amnt to the table
ALTER TABLE score
ADD COLUMN loan_amnt INT;

UPDATE score AS s
JOIN credit_risk AS cr ON s.credit_id = cr.credit_id
SET s.loan_amnt = cr.loan_amnt;

-- Calculating the capital value using the risk eliminating interest rate
SELECT MAX(loan_amnt) FROM score;

ALTER TABLE score
ADD COLUMN capital_value_nocost DECIMAL(10,2);

UPDATE score
SET capital_value_nocost = loan_amnt * POW((1 + loan_interest_rate_nocost), 10);

SELECT * FROM score LIMIT 100;

-- Now we calculate the capital value we would receive if the loan defaulted
ALTER TABLE score
ADD COLUMN cv_default_nocost DECIMAL(10,2);

UPDATE score
SET cv_default_nocost = loan_amnt * POW((1 + loan_interest_rate_nocost), 5);

SELECT * FROM score LIMIT 100;

WITH calcs AS(
	SELECT
		risk_class,
        SUM(CASE WHEN loan_status = 0 THEN capital_value_nocost ELSE cv_default_nocost END) AS amount_returned,
        SUM(loan_amnt) AS amount_given_as_loans
    FROM score
    GROUP BY risk_class ORDER BY risk_class)
SELECT
	risk_class,
	amount_returned,
    amount_given_as_loans,
    amount_returned - amount_given_as_loans AS earning
FROM calcs;

-- That looks really good. The problem is only that for several loans we suggest a much higher interest rate and therefore the likelihood for those loans to default increases as well
-- This is why step 2 must not be skipped.

-- 6.1) Calculating the risk eliminating interest rate
-- --------------------------------------------------------------------------------------------------
-- 6.2) Which monthly amount relative to income can an idividual sustain?

SELECT credit_id, loan_status, yr_amnt_to_income FROM credit_risk_clean_light_dummy;

WITH bucketed AS (
    SELECT
        credit_id,
        loan_status,
        yr_amnt_to_income,
        NTILE(50) OVER (ORDER BY yr_amnt_to_income DESC)
            AS yr_amnt_to_income_brackets
    FROM credit_risk_clean_light_dummy
)
SELECT
    yr_amnt_to_income_brackets,
    COUNT(credit_id) AS number_of_credits,
    SUM(loan_status) AS number_of_defaults,
    AVG(yr_amnt_to_income) AS avg_yr_amnt_to_income
FROM bucketed
GROUP BY yr_amnt_to_income_brackets
ORDER BY yr_amnt_to_income_brackets;

-- FROM the graph "Zusammenhang Zahlungen / Einkommen und Kreditausfälle" (to be found in the presentation) you can see that as clients have to pay back more than 4.3% of their
-- 	yearly income on average, credit defaults truly spike. So the approach will now be to prohibit such customers from receiving any loans.

SELECT COUNT(credit_id) AS number_of_credits FROM credit_risk_clean_light_dummy
WHERE yr_amnt_to_income > 0.043;
-- There are 6072 Loans affected under old interest rates.

ALTER TABLE score
ADD COLUMN yr_amnt_nocost DOUBLE;

UPDATE score
SET yr_amnt_nocost = ROUND(loan_amnt * ( (loan_interest_rate_nocost / 100) * POWER(1 + (loan_interest_rate_nocost / 100), 10) ) / ( POWER(1 + (loan_interest_rate_nocost / 100), 10) - 1 ),2);

ALTER TABLE score
ADD COLUMN yr_amnt_to_income_nocost DOUBLE;

ALTER TABLE score
ADD PRIMARY KEY (credit_id);

UPDATE score AS s
JOIN credit_risk_clean_light_dummy AS cr ON s.credit_id = cr.credit_id
SET s.yr_amnt_to_income_nocost = yr_amnt_nocost / cr.person_income;

SELECT * FROM score LIMIT 100;

SELECT COUNT(credit_id) AS number_of_credits FROM score
WHERE yr_amnt_to_income_nocost > 0.043;
-- There are 862 Loans that should not be made under the new interest rate suggestions. Under the old ones there have been 6072.

WITH calcs AS(
	SELECT
		risk_class,
        COUNT(credit_id) AS number_of_loans,
        SUM(CASE WHEN loan_status = 0 THEN capital_value_nocost ELSE cv_default_nocost END) AS amount_returned,
        SUM(loan_amnt) AS amount_given_as_loans
    FROM score
    WHERE yr_amnt_to_income_nocost > 0.043
    GROUP BY risk_class ORDER BY risk_class)
SELECT
	risk_class,
    number_of_loans,
	amount_returned,
    amount_given_as_loans,
    amount_returned - amount_given_as_loans AS earning
FROM calcs;
-- There are 203/7631 loans from group D, 606/1049 loans from group E, and 53/53 loans from group F affected.

SELECT
	risk_class,
	COUNT(credit_id) AS number_of_loans
FROM score
GROUP BY risk_class ORDER BY risk_class;

-- 6.2) Which monthly amount relative to income can an idividual sustain?
-- --------------------------------------------------------------------------------------------------
-- 6.3) Earnings Calculations and Model Comparison

WITH calcs AS(
	SELECT
		risk_class,
        COUNT(credit_id) AS number_of_loans,
        SUM(CASE WHEN loan_status = 0 THEN capital_value_nocost ELSE cv_default_nocost END) AS amount_returned,
        SUM(loan_amnt) AS amount_given_as_loans
    FROM score
    WHERE yr_amnt_to_income_nocost <= 0.043
    GROUP BY risk_class ORDER BY risk_class)
SELECT
	risk_class,
    number_of_loans,
	amount_returned,
    amount_given_as_loans,
    amount_returned - amount_given_as_loans AS earning
FROM calcs;
-- Total Earnings: 622,640,506.79 Currency Units (New Model, New Rule), this is an increase by 568% in comparison to the old model

WITH calcs AS(
	SELECT
		loan_grade,
        COUNT(credit_id) AS number_of_loans,
        SUM(CASE WHEN loan_status = 0 THEN yearly_amount * 10 ELSE yearly_amount * 5 END) AS amount_returned,
        SUM(loan_amnt) AS amount_given_as_loans
    FROM credit_risk_clean_light_dummy
    WHERE yr_amnt_to_income <= 0.043
    GROUP BY loan_grade ORDER BY loan_grade)
SELECT
	loan_grade,
    number_of_loans,
	amount_returned,
    amount_given_as_loans,
    amount_returned - amount_given_as_loans AS earning
FROM calcs;
-- Total Earnings: 107,127,050.85 Currency Units (Old Model, New Rule)

WITH calcs AS(
	SELECT
		loan_grade,
        COUNT(credit_id) AS number_of_loans,
        SUM(CASE WHEN loan_status = 0 THEN yearly_amount * 10 ELSE yearly_amount * 5 END) AS amount_returned,
        SUM(loan_amnt) AS amount_given_as_loans
    FROM credit_risk_clean_light_dummy
    GROUP BY loan_grade ORDER BY loan_grade)
SELECT
	loan_grade,
    number_of_loans,
	amount_returned,
    amount_given_as_loans,
    amount_returned - amount_given_as_loans AS earning
FROM calcs;
-- Total Earnings: 109,658,507.25 Currency Units (Old Model)

-- I had many more plans, but here I will stop because the time for coding is now over. After this, I will only code a few commands to generate statistics for the presentation
-- 	since I have to do them in SQL too.
-- My ideas on how to continue this project if I had more time:
-- 1) I could recalibrate the model given the excluded loans. Then I could recategorize them and find even more optimized interest rates
-- 2) I could include a margin within the existing interest rates. Because these are just to compensate for risk and opportunity cost. If a margin is included, earnings could be much
-- 		higher.
-- 3) I would build an entering table that would calculate new loans and automize the process, such that individuals cannot manipulate the interest rate anymore as management
-- 		suspected. This way, an automatically generated interest rate would be returned and restrictive rules could prevent impossible inputs (such as employment length)
-- 4) If I could get access to a better tool for Data Analysis I could work with better statistical tools, also analyzing non-linear multivariate relations and optimize the
-- 		prediction for the credit default risk. The interest rate could become much more continuous such that it does not depend only on brackets with thresholds. This way,
-- 		each individual could receive a personalized interest rate that would further maximize profits.
-- This is the end of the coding for this project besides commands for presentation creation.

-- Some select commands for the presentation
SELECT COUNT(credit_id) FROM credit_risk;

SELECT * FROM credit_risk_clean_light_dummy LIMIT 100;

SELECT
	loan_grade,
    ROUND(AVG(person_income), 2) AS average_income,
    ROUND(AVG(person_emp_length), 2) AS average_employment_length,
    ROUND(AVG(loan_int_rate), 4) AS average_interest_rate,
    ROUND(AVG(loan_amnt), 2) AS average_loan_amount,
    ROUND(AVG(cb_person_cred_hist_length), 4) AS average_credit_history_length,
    ROUND(AVG(cb_person_default_on_file_num), 4) AS percentage_people_defaulted_previously,
    ROUND(SUM(home_ownership_rent_dummy) / COUNT(credit_id), 2) AS percentage_renting_house,
    ROUND(SUM(home_ownership_own_dummy) / COUNT(credit_id), 2) AS percentage_owning_house,
    ROUND(SUM(home_ownership_mortgage_dummy) / COUNT(credit_id), 2) AS percentage_having_mortgage,
    ROUND(SUM(loan_status) / COUNT(*), 4) AS default_probability
FROM credit_risk_clean_light_dummy
GROUP BY loan_grade
ORDER BY loan_grade;

-- What we see up to here (premiss: Loan Grade is the one determining factor to determine loan interest rage, r=0.93):

-- List of variables that do not play a role in determining the interest rate but do play a role in people defaulting: Variable (r with loan grade, r with loan status)
-- Income (-0.01, -0.18), Rent (0.13, 0.25), Mortgage (-0.12, -0.2), Own (-0.02, -0.1), Employment Length (0.05, -0.1)

-- List of variables that do not play a stronger in determining the interest rate but do play a role in people defaulting: Variable (r with loan grade, r with loan status)
-- Default on File (0.54, 0.17)

-- Correlation about the same
-- Loan Amount (0.13, 0.09)

-- both uncorrelated
-- Credit History (0.01, 0.01), Employment Age Diff (0.05, 0.03), Age (0.01, -0.02), Other (0.01, 0.01)

-- r (Loan Grade, Employment Length) -0.05***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(person_emp_length * loan_grade_num) - AVG(person_emp_length) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(person_emp_length) * STDDEV(loan_grade_num)) AS r			
	FROM credit_risk_clean_light_dummy
    WHERE person_emp_length IS NOT NULL
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Grade, Employment Length) -0.05***

-- r (Loan Status, Employment Length) -0.1***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(person_emp_length * loan_status) - AVG(person_emp_length) * AVG(loan_status)) 
		/ 
		(STDDEV(person_emp_length) * STDDEV(loan_status)) AS r			
	FROM credit_risk_clean_light_dummy
    WHERE person_emp_length IS NOT NULL
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Status, Employment Length) -0.1***

SELECT * FROM credit_risk_clean_light_dummy LIMIT 10;

-- r (Loan Grade, Default on File) 0.54***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(cb_person_default_on_file_num * loan_grade_num) - AVG(cb_person_default_on_file_num) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(cb_person_default_on_file_num) * STDDEV(loan_grade_num)) AS r			
	FROM credit_risk_clean_light_dummy
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Grade, Default on File) 0.54***

-- r (Loan Status, Default on File) 0.17***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(cb_person_default_on_file_num * loan_status) - AVG(cb_person_default_on_file_num) * AVG(loan_status)) 
		/ 
		(STDDEV(cb_person_default_on_file_num) * STDDEV(loan_status)) AS r			
	FROM credit_risk_clean_light_dummy
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Status, Default on File) 0.17***

-- r (Loan Grade, Loan percent to Income) 0.12***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(loan_percent_income * loan_grade_num) - AVG(loan_percent_income) * AVG(loan_grade_num)) 
		/ 
		(STDDEV(loan_percent_income) * STDDEV(loan_grade_num)) AS r			
	FROM credit_risk_clean_light_dummy
    WHERE loan_percent_income IS NOT NULL
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Grade, Loan percent to income) 0.12***

-- r (Loan Status, Loan percent to income) 0.39***
WITH corr AS (									
	SELECT
		COUNT(*) AS n,							
		(AVG(loan_percent_income * loan_status) - AVG(loan_percent_income) * AVG(loan_status)) 
		/ 
		(STDDEV(loan_percent_income) * STDDEV(loan_status)) AS r			
	FROM credit_risk_clean_light_dummy
    WHERE loan_percent_income IS NOT NULL
),
t_calc AS(
	SELECT
		n,
        r,
        (n - 2) AS df,
        ROUND(r * SQRT((n - 2) / (1 - POW(r, 2))), 5) AS t_stat,
        ABS(r * SQRT((n - 2) / (1 - POW(r, 2)))) AS t_abs				
	FROM corr
)
SELECT
    n AS `Number of Rows`,
    ROUND(r, 2) AS `Pearson Correlation Coefficient`,
    df AS `Degrees of Freedom`,
    ROUND(t_stat, 2) AS `T-Statistic`,
    CASE
        WHEN t_abs > 2.576		
        THEN 'SIGNIFICANT (α = 0.01)'
        WHEN t_abs BETWEEN 1.96 AND 2.576
        THEN 'SIGNIFICANT (α = 0.05)'
        WHEN t_abs > 1.645
        THEN 'SIGNIFICANT (α = 0.10)'
        ELSE 'not significant (α = 0.10)'
    END AS significance
FROM t_calc;
-- r (Loan Status, Loan percent to Income) 0.39***

SELECT person_age, COUNT(credit_id) FROM credit_risk_clean_light_dummy
GROUP BY person_age ORDER BY person_age;

SELECT risk_class, COUNT(credit_id) AS amount_credits, SUM(loan_status)/COUNT(credit_id) AS default_probability FROM score
GROUP BY risk_class ORDER BY risk_class;

SELECT loan_grade, COUNT(credit_id) AS amount_credits, SUM(loan_status)/COUNT(credit_id) AS default_probability FROM credit_risk_clean_light
GROUP BY loan_grade ORDER BY loan_grade;

SELECT risk_class, ROUND(AVG(loan_interest_rate_nocost), 4) AS interest_rate, ROUND(AVG(default_risk), 4) AS default_risk FROM score
GROUP BY risk_class ORDER BY risk_class;

SELECT SUM(loan_status) FROM credit_risk_clean_light;

SELECT SUM(loan_status) FROM score
WHERE yr_amnt_to_income_nocost <= 0.043;