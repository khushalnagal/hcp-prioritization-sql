-- 04_rfv_analysis.sql
-- Per-doctor Recency, Frequency, Volume, with specialty cleaned (uppercased, blanks -> 'Unspecified', variants merged e.g. CARDIOLOGIST -> CARDIOLOGY)

DROP TABLE IF EXISTS hcp_rfv;

CREATE TABLE hcp_rfv AS
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
            ELSE UPPER(COALESCE(NULLIF(s.specialty, ''), 'Unspecified'))
        END AS specialty,
        s.state,
        c.claim_year,
        c.total_rx_claims,
        c.total_drug_spend
    FROM hcp_data_clean_final c
    JOIN (
        -- latest known specialty/state per doctor (handles conflicting values across years)
        SELECT npi, specialty, state
        FROM (
            SELECT npi, specialty, state,
                   ROW_NUMBER() OVER (PARTITION BY npi ORDER BY claim_year DESC) AS rn
            FROM hcp_data_clean_final
        ) ranked
        WHERE rn = 1
    ) s ON c.npi = s.npi
)
SELECT
    npi,
    specialty,
    state,
    MAX(claim_year)        AS last_active_year,  -- Recency
    SUM(total_rx_claims)   AS total_claims,       -- Frequency
    SUM(total_drug_spend)  AS total_spend         -- Volume
FROM resolved
GROUP BY npi, specialty, state;

SELECT COUNT(*) AS total_hcps FROM hcp_rfv;  -- expect ~569,119