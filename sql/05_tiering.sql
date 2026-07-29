-- 05_tiering.sql
-- Adds Frequency/Volume quartiles, then assigns a tier using Recency + Frequency + Volume

DROP TABLE IF EXISTS hcp_tiered;

CREATE TABLE hcp_tiered AS
SELECT
    npi,
    specialty,
    state,
    last_active_year,
    total_claims,
    total_spend,
    claims_quartile,
    spend_quartile,
    CASE
        WHEN last_active_year = 2022 AND spend_quartile = 4 AND claims_quartile >= 3 THEN 'High Priority'
        WHEN last_active_year IN (2021, 2022) AND spend_quartile >= 3 AND claims_quartile >= 2 THEN 'Growth'
        WHEN last_active_year IN (2020, 2021, 2022) THEN 'Maintenance'
        ELSE 'Dormant'
    END AS tier
FROM (
    SELECT
        npi,
        specialty,
        state,
        last_active_year,
        total_claims,
        total_spend,
        NTILE(4) OVER (ORDER BY total_claims) AS claims_quartile,
        NTILE(4) OVER (ORDER BY total_spend)  AS spend_quartile
    FROM hcp_rfv
) ranked;

SELECT tier, COUNT(*) AS hcp_count
FROM hcp_tiered
GROUP BY tier
ORDER BY hcp_count DESC;
