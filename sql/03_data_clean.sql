-- 03_data_clean.sql
-- Cleans hcp_data_raw using 5 rules identified during data profiling.
-- Each row must pass ALL 5 checks to make it into hcp_data_clean.
-- Updated: added 'state' column to support territory-based filtering in Power BI.
use hcp_prescriber_intel;

DROP TABLE IF EXISTS hcp_data_clean;
DROP TABLE IF EXISTS hcp_data_clean_final;

CREATE TABLE hcp_data_clean AS
SELECT
    npi,
    TRIM(specialty_description)             AS specialty,
    TRIM(provider_state)                    AS state,                                      -- added for territory filtering
    TRIM(drug_name)                         AS drug_name,
    TRIM(drug_type)                         AS drug_type,
    CAST(year AS UNSIGNED)                  AS claim_year,
    CAST(total_claim_count AS UNSIGNED)     AS total_rx_claims,
    CAST(total_drug_cost AS DECIMAL(12,2))  AS total_drug_spend,
    CAST(bene_count AS UNSIGNED)            AS unique_patient_count
FROM hcp_data_raw
WHERE
    (npi IS NOT NULL AND TRIM(npi) != '')                                                  -- drop null/blank NPI
    AND provider_country = 'US'                                                            -- CMS data only reflects the US system
    AND (ge65_suppress_flag IS NULL OR TRIM(TRAILING '\r' FROM ge65_suppress_flag) != '#') -- '#' = suppressed low count, not zero (strip trailing \r from Windows line endings)
    AND total_claim_count != '0'                                                           -- zero-activity rows
    AND total_drug_cost >= 0;                                                              -- negative cost = bad data entry

SELECT COUNT(*) AS clean_row_count FROM hcp_data_clean;                                    -- expect ~857,756

-- Verify the 5-rule drop count matches actual rows removed (checks WHERE clause correctness)
SELECT COUNT(*) AS rows_dropped
FROM hcp_data_raw
WHERE
    (npi IS NULL OR TRIM(npi) = '')
    OR provider_country != 'US'
    OR TRIM(TRAILING '\r' FROM ge65_suppress_flag) = '#'
    OR total_claim_count = '0'
    OR total_drug_cost < 0;                                                                -- expect ~142,244 dropped

-- Confirm no exact-duplicate rows exist (same npi+drug+year+claims+cost+patients) before aggregating
SELECT COUNT(*) AS exact_duplicate_groups
FROM (
    SELECT npi, drug_name, claim_year, total_rx_claims, total_drug_spend, unique_patient_count, COUNT(*) AS cnt
    FROM hcp_data_clean
    GROUP BY npi, drug_name, claim_year, total_rx_claims, total_drug_spend, unique_patient_count
    HAVING COUNT(*) > 1
) AS exact_dupes;                                                                          -- 0 = safe to aggregate below

-- Some (npi, drug_name, claim_year) combos repeat with different numbers = real separate activity, not duplicates -> aggregate via SUM
CREATE TABLE hcp_data_clean_final AS
SELECT
    npi,
    specialty,
    state,                                                                                  -- carried through for territory filtering
    drug_name,
    drug_type,
    claim_year,
    SUM(total_rx_claims)      AS total_rx_claims,
    SUM(total_drug_spend)     AS total_drug_spend,
    SUM(unique_patient_count) AS unique_patient_count
FROM hcp_data_clean
GROUP BY npi, specialty, state, drug_name, drug_type, claim_year;

SELECT COUNT(*) AS final_clean_row_count FROM hcp_data_clean_final;                        -- expect close to 856,931















