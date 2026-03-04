# Local Data Audit

- Audit date: 2026-03-03

## 1) `25171.csv`
- Loaded from: `C:/Users/HP/OneDrive/Documenten/MEGA/Atlas Corporation/Atlas Vault/03_Clients/Light Flow/25171.csv`
- Delimiter: tab (`\t`) | Encoding: ISO-8859-1
- Shape: 1500 rows x 6 columns
- Columns: National Total, Autonomous Communities and Cities, Index type, Indices and rates, Period, Total
- Time coverage (derived from `Period`): 2007 to 2025 (quarterly labels like `YYYYQI`)
- Distinct regional entries in `Autonomous Communities and Cities`: 19
- Missing values in `Total`: 0
- Interpretation: INE Tempus metadata (`SERIES_TABLA/25171`) includes series labels such as: Total Nacional. General. Indice.  | Total Nacional. General. Variacion trimestral.  | Total Nacional. General. Variacion anual. . This indicates table 25171 belongs to the INE House Price Index (IPV) operation.

## 2) `dwelings.csv`
- Loaded from: `C:/Users/HP/OneDrive/Documenten/MEGA/Atlas Corporation/Atlas Vault/03_Clients/Light Flow/dwelings.csv`
- Delimiter: comma | Encoding: ISO-8859-1
- Shape: 135 rows x 11 columns
- Time coverage (`TIME_PERIOD`): 2021
- Building categories: One-dwelling residential buildings | Residential buildings | Three or more dwelling residential buildings | Total | Two-dwelling residential buildings
- Distinct geographic labels (`geo`): 27
- Missing values in `OBS_VALUE`: 0
- Interpretation: Eurostat extract (`cens_21dwbo_r2`) with 2021 stock of conventional dwellings by building type and ownership status for Spain, NUTS1, and NUTS2 labels.

## 3) `housingcostoverburdenrate.csv`
- Loaded from: `C:/Users/HP/OneDrive/Documenten/MEGA/Atlas Corporation/Atlas Vault/03_Clients/Light Flow/housingcostoverburdenrate.csv`
- Delimiter: comma | Encoding: ISO-8859-1
- Shape: 135 rows x 17 columns
- Time coverage (`TIME_PERIOD`): 2021 to 2025
- Distinct geographic codes (`geo`): 27
- Missing values in `OBS_VALUE`: 0
- Interpretation: Eurostat extract (`ILC_LVHO07_R`) with annual housing cost overburden rates at national and NUTS regional levels.

## Notes
- `dwelings.csv` and `housingcostoverburdenrate.csv` are label-rich exports; geographies are partially in names and may require standardized joins to NUTS codes during cleaning.
