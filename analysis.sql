-- DATABASE SETUP
CREATE DATABASE claims_data;
USE claims_data;

SELECT * FROM claims_data;

 -- FINANCIAL ANALYSIS

-- 1.1 Maximum and Minimum Patient Income
SELECT MIN(PatientIncome) AS Minimum_Income,
       MAX(PatientIncome) AS Maximum_Income
FROM claims_data;

-- 1.2 Add Columns for ID and Income Quartiles
ALTER TABLE claims_data ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;
ALTER TABLE claims_data ADD COLUMN income_quartile INT;

UPDATE claims_data c
JOIN (
    SELECT id, NTILE(4) OVER (ORDER BY PatientIncome) AS qtile
    FROM claims_data
) t ON c.id = t.id
SET c.income_quartile = t.qtile;

-- 1.3 Average Claim Amount by Income Quartile
SELECT income_quartile, AVG(ClaimAmount) AS avg_claim_amount
FROM claims_data
GROUP BY income_quartile;

-- 1.4 Total Claim Amount
SELECT SUM(ClaimAmount) AS total_claim_amount
FROM claims_data;

-- 1.5 Total Claim Amount by Claim Status
SELECT ClaimStatus, SUM(ClaimAmount) AS total_claim_amount
FROM claims_data
GROUP BY ClaimStatus;

 -- INCOME QUARTILE ANALYSIS--

-- 2.1 Income Quartiles: Total, Pending, Approved, Denied Percentages

SELECT 
    income_quartile,
    SUM(ClaimStatus='Approved')*100/COUNT(*) AS approval_rate,
    SUM(ClaimStatus='Pending')*100/COUNT(*) AS pending_rate,
    SUM(ClaimStatus='Denied')*100/COUNT(*) AS rejection_rate
FROM claims_data
GROUP BY income_quartile
ORDER BY income_quartile;

-- 2.2 Average Age by Income Quartile
SELECT income_quartile, AVG(PatientAge) AS avg_age
FROM claims_data
GROUP BY income_quartile;

-- 2.3 Claim Type Distribution in Quartiles
SELECT 
    income_quartile,
    SUM(ClaimType='Inpatient')*100/COUNT(*) AS inpatient_type,
    SUM(ClaimType='Outpatient')*100/COUNT(*) AS outpatient_type,
    SUM(ClaimType='Routine')*100/COUNT(*) AS routine_type,
    SUM(ClaimType='Emergency')*100/COUNT(*) AS emergency_type
FROM claims_data
GROUP BY income_quartile
ORDER BY income_quartile;

-- EMPLOYMENT STATUS ANALYSIS--

-- 3.2 Unemployed and Student Distribution by Quartile
SELECT income_quartile, 
       SUM(PatientEmploymentStatus='Unemployed') AS unemployed,
       SUM(PatientEmploymentStatus='Student') AS student,
       SUM(PatientEmploymentStatus='Employed') AS employed
FROM claims_data
GROUP BY income_quartile;

-- PROVIDER ANALYSIS--

-- 4.1 Providers with High Total Claim Amounts
SELECT ProviderID, ProviderSpecialty, SUM(ClaimAmount) AS total_claim_amount
FROM claims_data
GROUP BY ProviderID, ProviderSpecialty
HAVING SUM(ClaimAmount) > (
    SELECT AVG(total_claim)
    FROM (
        SELECT SUM(ClaimAmount) AS total_claim
        FROM claims_data
        GROUP BY ProviderID
    ) AS avg_data
)
ORDER BY total_claim_amount DESC;

-- 4.2 Provider Specialties: Approval Rates
SELECT ProviderSpecialty,
       COUNT(*) AS total_claims,
       SUM(ClaimStatus='Approved')*100/COUNT(*) AS approval_rate
FROM claims_data
GROUP BY ProviderSpecialty
ORDER BY approval_rate DESC;

-- 4.3 Average Patient Age by Provider Specialty

SELECT 
    ProviderSpecialty,
    AVG(PatientAge) AS avg_patient_age
FROM claims_data
WHERE (ProviderSpecialty = 'Pediatrics' AND PatientAge BETWEEN 0 AND 18)
   OR ProviderSpecialty IN ('Cardiology', 'Neurology', 'General Practice', 'Orthopedics')
GROUP BY ProviderSpecialty;

-- IMPACT OF INCOME QUARTILE ON CLAIM APPROVAL--

SELECT income_quartile,
       SUM(ClaimStatus='Approved')*100/COUNT(*) AS approval_rate,
       SUM(ClaimStatus='Pending')*100/COUNT(*) AS pending_rate,
       SUM(ClaimStatus='Denied')*100/COUNT(*) AS rejection_rate
FROM claims_data
GROUP BY income_quartile
ORDER BY income_quartile;

-- CLAIM SUBMISSION METHOD ANALYSIS--

SELECT ClaimSubmissionMethod,
       SUM(ClaimStatus='Approved')*100/COUNT(*) AS approval_rate,
       SUM(ClaimStatus='Pending')*100/COUNT(*) AS pending_rate,
       SUM(ClaimStatus='Denied')*100/COUNT(*) AS rejection_rate
FROM claims_data
GROUP BY ClaimSubmissionMethod
ORDER BY ClaimSubmissionMethod;

-- GENDER-BASED CLAIM ANALYSIS

SELECT PatientGender,
       SUM(ClaimStatus='Approved')*100/COUNT(*) AS approval_rate,
       SUM(ClaimStatus='Pending')*100/COUNT(*) AS pending_rate,
       SUM(ClaimStatus='Denied')*100/COUNT(*) AS rejection_rate
FROM claims_data
GROUP BY PatientGender;

-- MARITAL STATUS ANALYSIS--

SELECT PatientMaritalStatus, ClaimStatus, COUNT(*) AS total_claims
FROM claims_data
GROUP BY PatientMaritalStatus, ClaimStatus
ORDER BY PatientMaritalStatus, ClaimStatus;

-- MONTHLY CLAIM TRENDS --

SELECT DATE_FORMAT(STR_TO_DATE(ClaimDate, '%d/%m/%Y'), '%Y-%m') AS claim_month,
       COUNT(*) AS total_claims,
       SUM(ClaimStatus='Approved') AS approved_claims
FROM claims_data
GROUP BY claim_month
ORDER BY claim_month;

-- PROVIDER LOCATION PERFORMANCE --

SELECT ProviderLocation,
       COUNT(*) AS total_claims,
       SUM(ClaimStatus='Approved')*100/COUNT(*) AS approval_rate,
       AVG(ClaimAmount) AS avg_claim_amount
FROM claims_data
GROUP BY ProviderLocation
ORDER BY approval_rate DESC, avg_claim_amount ASC;
