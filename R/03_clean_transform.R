source(file.path("R", "00_packages.R"))

standardize_text <- function(x) {
  x |>
    stringi::stri_trans_general("Latin-ASCII") |>
    stringr::str_to_lower() |>
    stringr::str_replace_all("[^a-z0-9]+", " ") |>
    stringr::str_squish()
}

local_25171 <- readRDS(file.path(paths$data_raw, "local_25171_raw.rds"))
local_dwelings <- readRDS(file.path(paths$data_raw, "local_dwelings_raw.rds"))
local_overburden <- readRDS(file.path(paths$data_raw, "local_housingcostoverburdenrate_raw.rds"))

prc_hicp_ainr <- readRDS(file.path(paths$data_raw, "eurostat_prc_hicp_ainr.rds"))
nama_10r_2lp10 <- readRDS(file.path(paths$data_raw, "eurostat_nama_10r_2lp10.rds"))
ilc_lvho07a <- readRDS(file.path(paths$data_raw, "eurostat_ilc_lvho07a.rds"))
tour_occ_nin3 <- readRDS(file.path(paths$data_raw, "eurostat_tour_occ_nin3.rds"))
sts_cobp_a <- readRDS(file.path(paths$data_raw, "eurostat_sts_cobp_a.rds"))
demo_pjan <- readRDS(file.path(paths$data_raw, "eurostat_demo_pjan.rds"))

extraction_date <- extract_date()

# Figure 1: Rental price index vs wage index (2015=100)
rent_raw <- prc_hicp_ainr |>
  dplyr::filter(
    freq == "A",
    geo == "ES",
    unit == "INX_A_AVG",
    coicop18 == "CP041",
    TIME_PERIOD >= 2010,
    TIME_PERIOD <= 2023
  ) |>
  dplyr::transmute(year = as.integer(TIME_PERIOD), rent_value = values)

wage_raw <- nama_10r_2lp10 |>
  dplyr::filter(
    freq == "A",
    geo == "ES",
    nace_r2 == "TOTAL",
    na_item == "D1_SAL_PER",
    unit == "EUR",
    TIME_PERIOD >= 2010,
    TIME_PERIOD <= 2023
  ) |>
  dplyr::transmute(year = as.integer(TIME_PERIOD), wage_value = values)

rent_base_2015 <- rent_raw |>
  dplyr::filter(year == 2015) |>
  dplyr::pull(rent_value)

wage_base_2015 <- wage_raw |>
  dplyr::filter(year == 2015) |>
  dplyr::pull(wage_value)

figure_1_clean <- rent_raw |>
  dplyr::inner_join(wage_raw, by = "year") |>
  dplyr::mutate(
    rent_index_2015 = (rent_value / rent_base_2015) * 100,
    wage_index_2015 = (wage_value / wage_base_2015) * 100
  ) |>
  dplyr::select(year, rent_index_2015, wage_index_2015) |>
  tidyr::pivot_longer(
    cols = c(rent_index_2015, wage_index_2015),
    names_to = "series",
    values_to = "index_2015_100"
  ) |>
  dplyr::mutate(
    series = dplyr::recode(
      series,
      rent_index_2015 = "Rental price index (HICP CP041)",
      wage_index_2015 = "Compensation per employee"
    )
  )

saveRDS(figure_1_clean, file.path(paths$data_clean, "figure_1_rent_vs_wage_index.rds"))

# Figure 2: Housing cost overburden by age group (with derived 30-64)
ilc_age_core <- ilc_lvho07a |>
  dplyr::filter(
    geo == "ES",
    unit == "PC",
    incgrp == "TOTAL",
    sex == "T",
    age %in% c("Y16-29", "Y18-24", "Y25-29", "Y18-64", "Y_GE65"),
    TIME_PERIOD >= 2010,
    TIME_PERIOD <= 2023
  ) |>
  dplyr::select(TIME_PERIOD, age, rate = values) |>
  tidyr::pivot_wider(names_from = age, values_from = rate)

population_single_age <- demo_pjan |>
  dplyr::filter(
    geo == "ES",
    sex == "T",
    unit == "NR",
    TIME_PERIOD >= 2010,
    TIME_PERIOD <= 2023
  ) |>
  dplyr::mutate(age_num = suppressWarnings(as.integer(sub("Y", "", age)))) |>
  dplyr::filter(!is.na(age_num))

population_groups <- population_single_age |>
  dplyr::group_by(TIME_PERIOD) |>
  dplyr::summarise(
    pop_18_24 = sum(values[age_num >= 18 & age_num <= 24], na.rm = TRUE),
    pop_25_29 = sum(values[age_num >= 25 & age_num <= 29], na.rm = TRUE),
    pop_18_64 = sum(values[age_num >= 18 & age_num <= 64], na.rm = TRUE),
    pop_30_64 = sum(values[age_num >= 30 & age_num <= 64], na.rm = TRUE),
    .groups = "drop"
  )

figure_2_wide <- ilc_age_core |>
  dplyr::inner_join(population_groups, by = "TIME_PERIOD") |>
  dplyr::mutate(
    rate_18_29 = (`Y18-24` * pop_18_24 + `Y25-29` * pop_25_29) / (pop_18_24 + pop_25_29),
    rate_30_64 = (`Y18-64` * pop_18_64 - rate_18_29 * (pop_18_24 + pop_25_29)) / pop_30_64
  ) |>
  dplyr::transmute(
    year = as.integer(TIME_PERIOD),
    `16-29` = `Y16-29`,
    `30-64` = rate_30_64,
    `65+` = `Y_GE65`
  )

figure_2_clean <- figure_2_wide |>
  tidyr::pivot_longer(
    cols = c(`16-29`, `30-64`, `65+`),
    names_to = "age_group",
    values_to = "overburden_rate"
  )

saveRDS(figure_2_clean, file.path(paths$data_clean, "figure_2_overburden_age_groups.rds"))

# Figure 3: Tourism pressure map (NUTS3 latest complete year)
tourism_nuts3 <- tour_occ_nin3 |>
  dplyr::filter(
    stringr::str_starts(geo, "ES"),
    nchar(geo) == 5,
    unit == "NR",
    c_resid == "TOTAL",
    nace_r2 == "I551-I553",
    TIME_PERIOD >= 2020
  )

tourism_coverage <- tourism_nuts3 |>
  dplyr::group_by(TIME_PERIOD) |>
  dplyr::summarise(regions_with_data = sum(!is.na(values)), .groups = "drop")

max_coverage <- max(tourism_coverage$regions_with_data, na.rm = TRUE)
figure_3_year <- tourism_coverage |>
  dplyr::filter(regions_with_data == max_coverage) |>
  dplyr::summarise(year = max(TIME_PERIOD, na.rm = TRUE)) |>
  dplyr::pull(year)

tourism_latest <- tourism_nuts3 |>
  dplyr::filter(TIME_PERIOD == figure_3_year) |>
  dplyr::transmute(geo = geo, nights_spent = values)

nuts3_es <- giscoR::gisco_get_nuts(
  year = "2021",
  epsg = "4326",
  resolution = "20",
  nuts_level = 3
) |>
  dplyr::filter(CNTR_CODE == "ES") |>
  dplyr::select(NUTS_ID, NAME_LATN, geometry)

figure_3_map <- nuts3_es |>
  dplyr::left_join(tourism_latest, by = c("NUTS_ID" = "geo"))

saveRDS(figure_3_map, file.path(paths$data_clean, "figure_3_tourism_nuts3_map.rds"))
saveRDS(
  tibble::tibble(latest_complete_year = figure_3_year),
  file.path(paths$data_clean, "figure_3_metadata.rds")
)

# Figure 4: New dwellings supply per capita by building type
permits_total_ths <- sts_cobp_a |>
  dplyr::filter(
    freq == "A",
    geo == "ES",
    indic_bt == "BPRM_DW",
    cpa2_1 == "CPA_F41001_X_410014",
    s_adj == "NSA",
    unit == "THS",
    TIME_PERIOD >= 2000,
    TIME_PERIOD <= 2024
  ) |>
  dplyr::transmute(year = as.integer(TIME_PERIOD), total_dwellings_obs = values * 1000)

permits_index_i21 <- sts_cobp_a |>
  dplyr::filter(
    freq == "A",
    geo == "ES",
    indic_bt == "BPRM_DW",
    cpa2_1 %in% c("CPA_F41001_X_410014", "CPA_F410011", "CPA_F410012_410013"),
    s_adj == "NSA",
    unit == "I21",
    TIME_PERIOD >= 2000,
    TIME_PERIOD <= 2024
  ) |>
  dplyr::transmute(year = as.integer(TIME_PERIOD), cpa2_1, index_i21 = values) |>
  tidyr::pivot_wider(names_from = cpa2_1, values_from = index_i21)

anchor_total_2021 <- permits_total_ths |>
  dplyr::filter(year == 2021) |>
  dplyr::pull(total_dwellings_obs)

if (length(anchor_total_2021) == 0 || is.na(anchor_total_2021)) {
  stop("Could not anchor total dwelling permits to 2021 observed THS data.")
}

total_series <- permits_index_i21 |>
  dplyr::mutate(
    total_dwellings_from_index = (`CPA_F41001_X_410014` / 100) * anchor_total_2021
  ) |>
  dplyr::left_join(permits_total_ths, by = "year") |>
  dplyr::mutate(
    total_dwellings = dplyr::coalesce(total_dwellings_obs, total_dwellings_from_index)
  ) |>
  dplyr::select(year, total_dwellings, `CPA_F410011`, `CPA_F410012_410013`)

spain_census_2021 <- local_dwelings |>
  dplyr::filter(
    geo == "Spain",
    TIME_PERIOD == 2021,
    building %in% c(
      "One-dwelling residential buildings",
      "Two-dwelling residential buildings",
      "Three or more dwelling residential buildings",
      "Total"
    )
  ) |>
  dplyr::select(building, OBS_VALUE) |>
  tidyr::pivot_wider(names_from = building, values_from = OBS_VALUE)

share_one_base <- spain_census_2021$`One-dwelling residential buildings` / spain_census_2021$Total
share_two_base <- spain_census_2021$`Two-dwelling residential buildings` / spain_census_2021$Total
share_three_base <- spain_census_2021$`Three or more dwelling residential buildings` / spain_census_2021$Total
share_multi_base <- share_two_base + share_three_base

share_two_within_multi <- share_two_base / share_multi_base
share_three_within_multi <- share_three_base / share_multi_base

supply_by_type <- total_series |>
  dplyr::mutate(
    one_proxy = share_one_base * (`CPA_F410011` / 100),
    multi_proxy = share_multi_base * (`CPA_F410012_410013` / 100),
    proxy_sum = one_proxy + multi_proxy,
    share_one = one_proxy / proxy_sum,
    share_multi = multi_proxy / proxy_sum,
    share_two = share_multi * share_two_within_multi,
    share_three = share_multi * share_three_within_multi,
    dwellings_one = total_dwellings * share_one,
    dwellings_two = total_dwellings * share_two,
    dwellings_three_plus = total_dwellings * share_three
  ) |>
  dplyr::select(year, dwellings_one, dwellings_two, dwellings_three_plus)

spain_population <- demo_pjan |>
  dplyr::filter(
    geo == "ES",
    sex == "T",
    age == "TOTAL",
    unit == "NR",
    TIME_PERIOD >= 2000,
    TIME_PERIOD <= 2024
  ) |>
  dplyr::transmute(year = as.integer(TIME_PERIOD), population = values)

figure_4_clean <- supply_by_type |>
  dplyr::left_join(spain_population, by = "year") |>
  dplyr::mutate(
    per_1000_one = (dwellings_one / population) * 1000,
    per_1000_two = (dwellings_two / population) * 1000,
    per_1000_three_plus = (dwellings_three_plus / population) * 1000
  ) |>
  dplyr::select(year, per_1000_one, per_1000_two, per_1000_three_plus) |>
  tidyr::pivot_longer(
    cols = c(per_1000_one, per_1000_two, per_1000_three_plus),
    names_to = "building_type",
    values_to = "new_dwellings_per_1000"
  ) |>
  dplyr::mutate(
    building_type = dplyr::recode(
      building_type,
      per_1000_one = "1-dwelling building",
      per_1000_two = "2-dwelling building",
      per_1000_three_plus = "3+ dwelling building"
    )
  )

saveRDS(figure_4_clean, file.path(paths$data_clean, "figure_4_supply_per_capita_by_type.rds"))

# Figure 5: NUTS2 share of multi-dwelling residential buildings
geo_lookup <- local_overburden |>
  dplyr::distinct(geo_code = geo, geo_name = `Geopolitical entity (reporting)`) |>
  dplyr::filter(stringr::str_detect(geo_code, "^ES[0-9A-Z]{2}$")) |>
  dplyr::mutate(geo_name_norm = standardize_text(geo_name))

dwellings_nuts <- local_dwelings |>
  dplyr::mutate(geo_name_norm = standardize_text(geo)) |>
  dplyr::left_join(geo_lookup, by = "geo_name_norm")

figure_5_raw <- dwellings_nuts |>
  dplyr::filter(
    TIME_PERIOD == 2021,
    building %in% c("Three or more dwelling residential buildings", "Total"),
    !is.na(geo_code),
    stringr::str_detect(geo_code, "^ES[0-9A-Z]{2}$")
  ) |>
  dplyr::select(geo_code, geo_label = geo, building, OBS_VALUE) |>
  tidyr::pivot_wider(names_from = building, values_from = OBS_VALUE) |>
  dplyr::mutate(
    share_multi_dwelling = (`Three or more dwelling residential buildings` / Total) * 100
  )

nuts2_es <- giscoR::gisco_get_nuts(
  year = "2021",
  epsg = "4326",
  resolution = "20",
  nuts_level = 2
) |>
  dplyr::filter(CNTR_CODE == "ES") |>
  dplyr::select(NUTS_ID, NAME_LATN, geometry)

figure_5_map <- nuts2_es |>
  dplyr::left_join(figure_5_raw, by = c("NUTS_ID" = "geo_code"))

saveRDS(figure_5_map, file.path(paths$data_clean, "figure_5_multi_dwelling_share_nuts2_map.rds"))

# Map join diagnostics
fig3_data_unmatched <- dplyr::anti_join(
  tourism_latest,
  sf::st_drop_geometry(nuts3_es),
  by = c("geo" = "NUTS_ID")
)

fig3_geom_unmatched <- dplyr::anti_join(
  sf::st_drop_geometry(nuts3_es),
  tourism_latest,
  by = c("NUTS_ID" = "geo")
)

fig5_data_unmatched <- dplyr::anti_join(
  figure_5_raw,
  sf::st_drop_geometry(nuts2_es),
  by = c("geo_code" = "NUTS_ID")
)

fig5_geom_unmatched <- dplyr::anti_join(
  sf::st_drop_geometry(nuts2_es),
  figure_5_raw,
  by = c("NUTS_ID" = "geo_code")
)

diag_lines <- c(
  "# Map Join Diagnostics",
  "",
  paste0("- Generated on: ", extraction_date),
  "",
  "## Figure 3 (NUTS3 tourism map)",
  paste0("- Latest complete year selected: ", figure_3_year),
  paste0("- Geometry regions (ES NUTS3): ", nrow(nuts3_es)),
  paste0("- Data regions: ", nrow(tourism_latest)),
  paste0("- Data codes unmatched in geometry: ", nrow(fig3_data_unmatched)),
  paste0("- Geometry codes unmatched in data: ", nrow(fig3_geom_unmatched)),
  if (nrow(fig3_data_unmatched) > 0) paste0("- Unmatched data codes: ", paste(fig3_data_unmatched$geo, collapse = ", ")) else "- Unmatched data codes: none",
  if (nrow(fig3_geom_unmatched) > 0) paste0("- Unmatched geometry codes: ", paste(fig3_geom_unmatched$NUTS_ID, collapse = ", ")) else "- Unmatched geometry codes: none",
  "",
  "## Figure 5 (NUTS2 multi-dwelling share map)",
  paste0("- Geometry regions (ES NUTS2): ", nrow(nuts2_es)),
  paste0("- Data regions: ", nrow(figure_5_raw)),
  paste0("- Data codes unmatched in geometry: ", nrow(fig5_data_unmatched)),
  paste0("- Geometry codes unmatched in data: ", nrow(fig5_geom_unmatched)),
  if (nrow(fig5_data_unmatched) > 0) paste0("- Unmatched data codes: ", paste(fig5_data_unmatched$geo_code, collapse = ", ")) else "- Unmatched data codes: none",
  if (nrow(fig5_geom_unmatched) > 0) paste0("- Unmatched geometry codes: ", paste(fig5_geom_unmatched$NUTS_ID, collapse = ", ")) else "- Unmatched geometry codes: none"
)

writeLines(diag_lines, file.path(paths$docs, "map_join_diagnostics.md"))

# Data dictionary
dict_lines <- c(
  "# Data Dictionary",
  "",
  paste0("- Generated on: ", extraction_date),
  "",
  "## `data_clean/figure_1_rent_vs_wage_index.rds`",
  "- `year`: integer year (2010-2023).",
  "- `series`: `Rental price index (HICP CP041)` or `Compensation per employee`.",
  "- `index_2015_100`: rebased index value where 2015 = 100.",
  "",
  "## `data_clean/figure_2_overburden_age_groups.rds`",
  "- `year`: integer year (2010-2023).",
  "- `age_group`: `16-29`, `30-64`, `65+`.",
  "- `overburden_rate`: housing cost overburden rate (%).",
  "- Note: `30-64` is derived from Eurostat age bins using population-weighted algebra (`ilc_lvho07a` + `demo_pjan`).",
  "",
  "## `data_clean/figure_3_tourism_nuts3_map.rds`",
  "- `NUTS_ID`: NUTS3 region code.",
  "- `NAME_LATN`: Latin-script region name from GISCO.",
  "- `nights_spent`: annual nights spent in tourist accommodation (`tour_occ_nin3`, unit `NR`, residents `TOTAL`).",
  "- `geometry`: `sf` polygon geometry for mapping.",
  "",
  "## `data_clean/figure_3_metadata.rds`",
  "- `latest_complete_year`: latest year with full NUTS3 coverage used in Figure 3.",
  "",
  "## `data_clean/figure_4_supply_per_capita_by_type.rds`",
  "- `year`: integer year (2000-2024).",
  "- `building_type`: `1-dwelling building`, `2-dwelling building`, `3+ dwelling building`.",
  "- `new_dwellings_per_1000`: estimated new dwellings per 1,000 inhabitants.",
  "- Note: built from Eurostat building permits (`sts_cobp_a`) and population (`demo_pjan`) with documented proxy assumptions for type decomposition.",
  "",
  "## `data_clean/figure_5_multi_dwelling_share_nuts2_map.rds`",
  "- `NUTS_ID`: NUTS2 region code.",
  "- `NAME_LATN`: Latin-script region name from GISCO.",
  "- `geo_label`: local region label from `dwelings.csv`.",
  "- `Three or more dwelling residential buildings`: numerator category value.",
  "- `Total`: denominator category value across building types.",
  "- `share_multi_dwelling`: `(Three or more dwelling residential buildings / Total) * 100`.",
  "- `geometry`: `sf` polygon geometry for mapping."
)

writeLines(dict_lines, file.path(paths$docs, "data_dictionary.md"))

message("03_clean_transform.R completed.")
