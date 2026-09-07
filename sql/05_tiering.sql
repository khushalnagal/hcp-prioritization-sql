-- 05_tiering.sql
-- Adds Frequency/Volume quartiles, then assigns a tier using Recency + Frequency + Volume
-- Recency is computed relative to the latest year present in the data, not hardcoded.

DROP TABLE IF EXISTS hcp_tiered;

CREATE TABLE hcp_tiered AS
WITH quartiles AS (
    SELECT
        npi,
        specialty,
        state,
        top_drug_name,
        last_active_year,
        total_claims,
        total_spend,
        NTILE(4) OVER (ORDER BY total_claims) AS claims_quartile,
        NTILE(4) OVER (ORDER BY total_spend)  AS spend_quartile
    FROM hcp_rfv
),
latest_year AS (
    SELECT MAX(last_active_year) AS max_year
    FROM hcp_rfv
)
SELECT
    q.npi,
    q.specialty,
    q.state,
    q.top_drug_name,
    q.last_active_year,
    q.total_claims,
    q.total_spend,
    q.claims_quartile,
    q.spend_quartile,
    CASE
        WHEN q.last_active_year = y.max_year
             AND q.spend_quartile = 4
             AND q.claims_quartile >= 3
            THEN 'High Priority'
        WHEN q.last_active_year >= y.max_year - 1
             AND q.spend_quartile >= 3
             AND q.claims_quartile >= 2
            THEN 'Growth'
        WHEN q.last_active_year >= y.max_year - 2
            THEN 'Maintenance'
        ELSE 'Dormant'
    END AS tier
FROM quartiles q
CROSS JOIN latest_year y;

SELECT
    tier,
    COUNT(*) AS hcp_count
FROM hcp_tiered
GROUP BY tier
ORDER BY
    CASE tier
        WHEN 'High Priority' THEN 1
        WHEN 'Growth'        THEN 2
        WHEN 'Maintenance'   THEN 3
        WHEN 'Dormant'       THEN 4
    END;
