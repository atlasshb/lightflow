# Spain Housing Crisis Figures - Reproducible Pipeline

## Run order
Run scripts from the project root in this exact order:

1. `Rscript R/01_load_local_data.R`
2. `Rscript R/02_fetch_eurostat_api.R`
3. `Rscript R/03_clean_transform.R`
4. `Rscript R/04_plot_figures.R`
5. `Rscript R/99_session_info.R`

`R/00_packages.R` is sourced by each script and handles package loading/installation.

## Output locations
- Cleaned datasets: `data_clean/*.rds`
- Figures (PNG): `figures/png/figure_1.png` ... `figure_5.png`
- Figures (PDF): `figures/pdf/figure_1.pdf` ... `figure_5.pdf`
- Docs:
  - `docs/local_data_audit.md`
  - `docs/data_dictionary.md`
  - `docs/map_join_diagnostics.md`
  - `docs/README.md` (this file)
- Session info: `session_info.txt`

## Figure summary and exact filters

### Figure 1 - Rental Price Index vs Wage Index (Spain, 2010-2023)
- Source A: Eurostat `prc_hicp_ainr`
  - `freq = A`, `unit = INX_A_AVG`, `geo = ES`, `coicop18 = CP041` (actual rentals for housing)
- Source B: Eurostat `nama_10r_2lp10`
  - `freq = A`, `geo = ES`, `nace_r2 = TOTAL`, `na_item = D1_SAL_PER`, `unit = EUR`
- Transformation:
  - `index_t = (value_t / value_2015) * 100` for each series.

### Figure 2 - Housing Cost Overburden Rate by Age Group (Spain, 2010-2023)
- Source: Eurostat `ilc_lvho07a`
  - `geo = ES`, `unit = PC`, `incgrp = TOTAL`, `sex = T`
  - ages used directly: `Y16-29`, `Y_GE65`, plus helper ages `Y18-24`, `Y25-29`, `Y18-64`
- Population source for derivation: Eurostat `demo_pjan`
  - `geo = ES`, `sex = T`, `unit = NR`
- Transformation:
  - `30-64` is derived by population-weighted algebra from available age bins.

### Figure 3 - Tourism Pressure Map (NUTS3, Spain)
- Source: Eurostat `tour_occ_nin3`
  - `unit = NR`, `c_resid = TOTAL`, `nace_r2 = I551-I553`, `geo = ES***` (NUTS3), `TIME_PERIOD >= 2020`
- Geometry: GISCO via `giscoR::gisco_get_nuts(year = 2021, nuts_level = 3)`
- Year selection rule:
  - latest year with maximum NUTS3 coverage (selected year: 2024).

### Figure 4 - New Dwellings Supply per 1,000 Inhabitants by Building Type (Spain, 2000-2024)
- Core permits source: Eurostat `sts_cobp_a`
  - indicator: `indic_bt = BPRM_DW`, `geo = ES`, `freq = A`, `s_adj = NSA`
  - total observed counts series: `cpa2_1 = CPA_F41001_X_410014`, `unit = THS`
  - type indices: `unit = I21`, `cpa2_1 in {CPA_F410011, CPA_F410012_410013, CPA_F41001_X_410014}`
- Population source: Eurostat `demo_pjan` with `geo = ES`, `sex = T`, `age = TOTAL`, `unit = NR`
- Baseline composition proxy source: local `dwelings.csv` (`cens_21dwbo_r2`, Spain 2021)
- Transformation:
  - Convert total `THS` to number of dwellings.
  - Backfill 2000-2004 total using I21 index anchored to observed 2021 total.
  - Estimate composition shares with index evolution plus 2021 baseline shares.
  - Split multi-dwelling into `2-dwelling` and `3+` using 2021 within-multi proportions.
  - Compute per-capita rate: `(estimated dwellings / population) * 1000`.

### Figure 5 - Share of Multi-Dwelling Residential Buildings in Total by NUTS2 (2021)
- Source: local `dwelings.csv` (`cens_21dwbo_r2`, year 2021)
- Numerator: `Three or more dwelling residential buildings`
- Denominator: `Total`
- Formula:
  - `share_multi_dwelling = (numerator / denominator) * 100`
- Geometry: GISCO via `giscoR::gisco_get_nuts(year = 2021, nuts_level = 2)`
- Join method:
  - Local region labels normalized and mapped to NUTS2 codes using local `housingcostoverburdenrate.csv` code-name pairs.

## Assumptions recorded
- In this Windows shell, `/mnt/data/...` was not mounted; scripts therefore resolve input files by checking `/mnt/data` first and then project-local copies.
- `25171.csv` was audited as INE IPV (house price index) metadata and not used in the 5 requested final figures.
- Figure 2 uses a derived `30-64` age series because `ilc_lvho07a` does not expose a direct `Y30-64` series in the current API response.
- Figure 4 uses documented proxy decomposition because no single annual Spain series with direct raw counts for `1`, `2`, and `3+` dwellings per building was available in one Eurostat endpoint.

## Extraction date
- Eurostat/GISCO extraction date used in captions and docs: `2026-03-03`.
