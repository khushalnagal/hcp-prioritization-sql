-- 01_create_tables.sql
-- Creates the database and raw staging table for HCP Prescriber Intelligence
-- Raw table mirrors the source CSV exactly (no renaming, no dropping, no type casting).
-- All transformations happen later in the cleaning step (03_cleaning.sql).

CREATE DATABASE IF NOT EXISTS hcp_prescriber_intel;
USE hcp_prescriber_intel;

CREATE TABLE hcp_data_raw (
    npi                         VARCHAR(20),
    provider_last_org_name      VARCHAR(100),
    provider_first_name         VARCHAR(100),
    provider_state              VARCHAR(10),
    provider_country            VARCHAR(10),
    specialty_description       VARCHAR(150),
    drug_name                   VARCHAR(150),
    drug_type                   VARCHAR(20),
    year                        VARCHAR(10),
    total_claim_count           VARCHAR(20),
    total_30_day_fill_count     VARCHAR(20),
    total_drug_cost             VARCHAR(30),
    total_day_supply            VARCHAR(20),
    bene_count                  VARCHAR(20),
    ge65_suppress_flag          VARCHAR(5)
);





