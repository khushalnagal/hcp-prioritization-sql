-- 05_tiering.sql
-- Adds Frequency/Volume quartiles, then assigns a tier using Recency + Frequency + Volume
-- Recency is computed relative to the latest year present in the data, not hardcoded.

DROP TABLE IF EXISTS hcp_tiered;

CREATE TABLE hcp_tiered AS
SELECT
    r.npi,
    r.specialty,
    r.state,
    r.last_active_year,
    r.total_claims,
    r.total_spend,
    r.claims_quartile,
    r.spend_quartile,
    CASE
        WHEN r.last_active_year = y.max_year AND r.spend_quartile = 4 AND r.claims_quartile >= 3 THEN 'High Priority'
        WHEN r.last_active_year >= y.max_year - 1 AND r.spend_quartile >= 3 AND r.claims_quartile >= 2 THEN 'Growth'
        WHEN r.last_active_year >= y.max_year - 2 THEN 'Maintenance'
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
) r
CROSS JOIN (SELECT MAX(last_active_year) AS max_year FROM hcp_rfv) y;

SELECT tier, COUNT(*) AS hcp_count
FROM hcp_tiered
GROUP BY tier
ORDER BY hcp_count DESC;
