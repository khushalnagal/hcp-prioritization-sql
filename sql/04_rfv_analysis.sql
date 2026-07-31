-- 04_rfv_analysis.sql
DROP TABLE IF EXISTS hcp_rfv;
CREATE TABLE hcp_rfv AS
-- still one row per doctor per drug per year, just standardizes specialty/state per doctor before the final GROUP BY collapses it
WITH resolved AS (
    SELECT
        c.npi,
        CASE UPPER(COALESCE(NULLIF(s.specialty, ''), 'Unspecified'))
            WHEN 'CARDIOLOGIST' THEN 'CARDIOLOGY'
            WHEN 'ENDOCRINOLOGIST' THEN 'ENDOCRINOLOGY'
            WHEN 'NEPHROLOGIST' THEN 'NEPHROLOGY'
            WHEN 'NEUROLOGIST' THEN 'NEUROLOGY'
            WHEN 'INT. MEDICINE' THEN 'INTERNAL MEDICINE'
            WHEN 'GERIATRICS' THEN 'GERIATRIC MEDICINE'
            WHEN 'NP' THEN 'NURSE PRACTITIONER'
            WHEN 'PA' THEN 'PHYSICIAN ASSISTANT'
            WHEN 'FAMILY PRACTICE' THEN 'FAMILY MEDICINE'
            ELSE UPPER(COALESCE(NULLIF(s.specialty, ''), 'Unspecified'))
        END AS specialty,
        s.state,
        c.claim_year,
        c.total_rx_claims,
        c.total_drug_spend
    FROM hcp_data_clean_final c
    JOIN (
            SELECT npi, specialty, state
            FROM (
                    SELECT npi, specialty, state,
                       ROW_NUMBER() OVER (PARTITION BY npi ORDER BY claim_year DESC) AS rn
                    FROM hcp_data_clean_final
			     ) ranked
            WHERE rn = 1
		 ) s 
    ON c.npi = s.npi
),
top_drug AS (
    -- one row per doctor: their single top drug by total spend, same ranking pattern as specialty resolution above
    SELECT npi, drug_name AS top_drug_name
    FROM (
            SELECT npi, drug_name,
                   ROW_NUMBER() OVER (PARTITION BY npi ORDER BY SUM(total_drug_spend) DESC) AS rn
            FROM hcp_data_clean_final
            GROUP BY npi, drug_name
         ) x
    WHERE rn = 1
)
SELECT
    r.npi, r.specialty, r.state,
    MAX(r.claim_year)        AS last_active_year,
    SUM(r.total_rx_claims)   AS total_claims,
    SUM(r.total_drug_spend)  AS total_spend,
    t.top_drug_name
FROM resolved r
JOIN top_drug t ON r.npi = t.npi
GROUP BY r.npi, r.specialty, r.state, t.top_drug_name;

SELECT COUNT(*) AS total_hcps FROM hcp_rfv;
