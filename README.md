# HCP Prioritization: SQL-Based Sales Targeting

**SQL + Power BI** project to identify which **healthcare providers (HCPs)** a pharma sales team should prioritize, using Medicare style prescriber data.

## Problem
A sales rep can't visit every prescriber. This project ranks HCPs using an **RFV framework** (Recency, Frequency, Volume) and sorts them into 4 tiers: **High Priority, Growth, Maintenance, Dormant.**

## Stack
**MySQL 8.0** for all cleaning and analysis. **Power BI** for the dashboard. Everything is SQL-driven.

## Pipeline
| Script | What it does |
|---|---|
| `01_create_tables.sql` | Creates database and raw staging table |
| `02_load_data.sql` | Loads CSV into MySQL, profiles data quality |
| `03_data_clean.sql` | Cleans and deduplicates (**5 rules**) |
| `04_rfv_analysis.sql` | Computes **Recency, Frequency, Volume** per HCP, plus each HCP's top drug by spend |
| `05_tiering.sql` | **Quartile ranking** and tier assignment, using Recency + Frequency + Volume |

## Cleaning Results
- **1,000,000** raw rows → **856,931** clean rows
- Rules applied: missing NPI, non-US rows, CMS-suppressed rows, zero-claim rows, negative cost rows
- Found and fixed a hidden **`\r` carriage return bug** silently breaking the suppression flag filter
- Merged specialty naming variants: `CARDIOLOGIST` → `CARDIOLOGY`, `NP` → `NURSE PRACTITIONER`, `INT. MEDICINE` → `INTERNAL MEDICINE`, `FAMILY PRACTICE` → `FAMILY MEDICINE` (verified via `DISTINCT` specialty check; `GENERAL PRACTICE` kept separate as a distinct credentialing category)

## Tier Breakdown
| Tier | HCPs | Share |
|---|---|---|
| Maintenance | 290,244 | 51.0% |
| Growth | 148,300 | 26.1% |
| **High Priority** | 73,891 | **13.0%** |
| **Dormant** | 56,684 | **10.0%** |

Tiering uses **Recency, Frequency (claim count quartile), and Volume (spend quartile)** together not spend alone so a doctor with one abnormally large claim can't outrank someone with consistent engagement. Recency is computed relative to the latest year present in the data (not hardcoded), so the logic doesn't need manual updates when new data loads.

## Dashboard
`powerbi/HCP.pbix` connects **directly** to the final `hcp_tiered` SQL table, no manual export step.
- **KPI cards:** Total HCPs, Target Coverage, High Priority HCPs, Dormant HCPs
- **Tier distribution** and spend by tier
- **Top specialties** and **top states** by HCP count
- **Ranked table** of top HCPs by spend, including each HCP's top drug by spend
- **Slicers:** specialty, state, tier

## Key Insights
- **High Priority tier is only 13.0% of HCPs but drives the largest share of prescribing spend** - opportunity is concentrated, not evenly spread
- **10% of HCPs are Dormant** - a clear, actionable re-engagement list for the sales team
- **High spend does not always mean High Priority** - Recency and Frequency pull some big spenders into Growth or Maintenance, which is why a single metric isn't enough
- Top specialties (**Cardiology, Internal Medicine, Family Medicine, Endocrinology**) align directly with the diabetes/cardiovascular drug focus
- HCP volume is spread across **many states**, supporting territory-level filtering for a national sales team

## Notes
- Source data is a **CMS Part D style synthetic dataset** with intentional, realistic data quality issues
- "HCP" is used deliberately instead of "doctor" - the dataset includes Nurse Practitioners and Physician Assistants, so HCP is the accurate umbrella term
- Raw data files are excluded via `.gitignore` due to size
