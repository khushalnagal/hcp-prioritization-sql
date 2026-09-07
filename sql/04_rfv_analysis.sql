-- ============================================================
-- 04_rfv_analysis.sql
-- Builds one row per doctor (npi) with:
--   - latest known specialty/state
--   - total claims + total spend across all years
--   - their single highest-spend drug
-- ============================================================

DROP TABLE IF EXISTS hcp_rfv;

CREATE TABLE hcp_rfv AS
WITH latest_info AS (
    -- one row per doctor: their specialty + state from the most recent year
    SELECT npi, specialty, state
    FROM (
        SELECT
            npi,
            specialty,
            state,
            ROW_NUMBER() OVER (PARTITION BY npi ORDER BY claim_year DESC) AS rn
        FROM hcp_data_clean_final
    ) AS ranked_info
    WHERE rn = 1
),

top_drug AS (
    -- one row per doctor: their highest-spend drug
    SELECT npi, drug_name AS top_drug_name
    FROM (
        SELECT
            npi,
            drug_name,
            SUM(total_drug_spend) AS drug_spend,
            ROW_NUMBER() OVER (PARTITION BY npi ORDER BY SUM(total_drug_spend) DESC) AS rn
        FROM hcp_data_clean_final
        GROUP BY npi, drug_name
    ) AS ranked_drug
    WHERE rn = 1
)

SELECT
    c.npi,
    l.specialty,
    l.state,
    MAX(c.claim_year)       AS last_active_year,
    SUM(c.total_rx_claims)  AS total_claims,
    SUM(c.total_drug_spend) AS total_spend,
    t.top_drug_name
FROM hcp_data_clean_final c
JOIN latest_info l ON c.npi = l.npi
JOIN top_drug t     ON c.npi = t.npi
GROUP BY c.npi, l.specialty, l.state, t.top_drug_name;


SELECT COUNT(*) AS total_hcps FROM hcp_rfv;
