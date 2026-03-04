# Data Dictionary

- Generated on: 2026-03-03

## `data_clean/figure_1_rent_vs_wage_index.rds`
- `year`: integer year (2010-2023).
- `series`: `Rental price index (HICP CP041)` or `Compensation per employee`.
- `index_2015_100`: rebased index value where 2015 = 100.

## `data_clean/figure_2_overburden_age_groups.rds`
- `year`: integer year (2010-2023).
- `age_group`: `16-29`, `30-64`, `65+`.
- `overburden_rate`: housing cost overburden rate (%).
- Note: `30-64` is derived from Eurostat age bins using population-weighted algebra (`ilc_lvho07a` + `demo_pjan`).

## `data_clean/figure_3_tourism_nuts3_map.rds`
- `NUTS_ID`: NUTS3 region code.
- `NAME_LATN`: Latin-script region name from GISCO.
- `nights_spent`: annual nights spent in tourist accommodation (`tour_occ_nin3`, unit `NR`, residents `TOTAL`).
- `geometry`: `sf` polygon geometry for mapping.

## `data_clean/figure_3_metadata.rds`
- `latest_complete_year`: latest year with full NUTS3 coverage used in Figure 3.

## `data_clean/figure_4_supply_per_capita_by_type.rds`
- `year`: integer year (2000-2024).
- `building_type`: `1-dwelling building`, `2-dwelling building`, `3+ dwelling building`.
- `new_dwellings_per_1000`: estimated new dwellings per 1,000 inhabitants.
- Note: built from Eurostat building permits (`sts_cobp_a`) and population (`demo_pjan`) with documented proxy assumptions for type decomposition.

## `data_clean/figure_5_multi_dwelling_share_nuts2_map.rds`
- `NUTS_ID`: NUTS2 region code.
- `NAME_LATN`: Latin-script region name from GISCO.
- `geo_label`: local region label from `dwelings.csv`.
- `Three or more dwelling residential buildings`: numerator category value.
- `Total`: denominator category value across building types.
- `share_multi_dwelling`: `(Three or more dwelling residential buildings / Total) * 100`.
- `geometry`: `sf` polygon geometry for mapping.
