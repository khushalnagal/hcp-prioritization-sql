-- 02_load_data.sql
-- Loads raw CSV into the staging table
LOAD DATA LOCAL INFILE 'D:/pharma_hcp_intelligence/data/cms_raw.csv'
INTO TABLE hcp_data_raw
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM hcp_data_raw;	



SELECT ge65_suppress_flag, HEX(ge65_suppress_flag), COUNT(*)
FROM hcp_data_raw
WHERE ge65_suppress_flag LIKE '#%'
GROUP BY ge65_suppress_flag, HEX(ge65_suppress_flag)
LIMIT 10;