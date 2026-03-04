source(file.path("R", "00_packages.R"))

locate_input_file <- function(filename) {
  candidates <- c(
    file.path("/mnt/data", filename),
    file.path(paths$root, filename),
    filename
  )
  existing <- candidates[file.exists(candidates)]
  if (length(existing) == 0) {
    stop(glue::glue("Input file not found: {filename}. Checked: {paste(candidates, collapse = ', ')}"))
  }
  normalizePath(existing[1], winslash = "/", mustWork = TRUE)
}

file_25171 <- locate_input_file("25171.csv")
file_dwelings <- locate_input_file("dwelings.csv")
file_overburden <- locate_input_file("housingcostoverburdenrate.csv")

local_25171 <- readr::read_delim(
  file = file_25171,
  delim = "\t",
  locale = readr::locale(encoding = "ISO-8859-1"),
  show_col_types = FALSE
)

local_dwelings <- readr::read_csv(
  file = file_dwelings,
  locale = readr::locale(encoding = "ISO-8859-1"),
  show_col_types = FALSE
)

local_overburden <- readr::read_csv(
  file = file_overburden,
  locale = readr::locale(encoding = "ISO-8859-1"),
  show_col_types = FALSE
)

saveRDS(local_25171, file.path(paths$data_raw, "local_25171_raw.rds"))
saveRDS(local_dwelings, file.path(paths$data_raw, "local_dwelings_raw.rds"))
saveRDS(local_overburden, file.path(paths$data_raw, "local_housingcostoverburdenrate_raw.rds"))

period_years <- suppressWarnings(as.integer(stringr::str_extract(local_25171$Period, "^[0-9]{4}")))

ine_series_meta <- tryCatch(
  jsonlite::fromJSON("https://servicios.ine.es/wstempus/js/es/SERIES_TABLA/25171"),
  error = function(e) NULL
)

ine_hint <- if (!is.null(ine_series_meta) && nrow(ine_series_meta) > 0) {
  meta_names_ascii <- stringi::stri_trans_general(head(unique(ine_series_meta$Nombre), 3), "Latin-ASCII")
  paste0(
    "INE Tempus metadata (`SERIES_TABLA/25171`) includes series labels such as: ",
    paste(meta_names_ascii, collapse = " | "),
    ". This indicates table 25171 belongs to the INE House Price Index (IPV) operation."
  )
} else {
  "INE metadata endpoint was not reachable during script execution; based on headers and values, this file appears to be an INE-style quarterly housing price index table."
}

audit_lines <- c(
  "# Local Data Audit",
  "",
  paste0("- Audit date: ", extract_date()),
  "",
  "## 1) `25171.csv`",
  paste0("- Loaded from: `", file_25171, "`"),
  "- Delimiter: tab (`\\t`) | Encoding: ISO-8859-1",
  paste0("- Shape: ", nrow(local_25171), " rows x ", ncol(local_25171), " columns"),
  paste0("- Columns: ", paste(names(local_25171), collapse = ", ")),
  paste0("- Time coverage (derived from `Period`): ", min(period_years, na.rm = TRUE), " to ", max(period_years, na.rm = TRUE), " (quarterly labels like `YYYYQI`)"),
  paste0("- Distinct regional entries in `Autonomous Communities and Cities`: ", dplyr::n_distinct(local_25171$`Autonomous Communities and Cities`, na.rm = TRUE)),
  paste0("- Missing values in `Total`: ", sum(is.na(local_25171$Total))),
  paste0("- Interpretation: ", ine_hint),
  "",
  "## 2) `dwelings.csv`",
  paste0("- Loaded from: `", file_dwelings, "`"),
  "- Delimiter: comma | Encoding: ISO-8859-1",
  paste0("- Shape: ", nrow(local_dwelings), " rows x ", ncol(local_dwelings), " columns"),
  paste0("- Time coverage (`TIME_PERIOD`): ", paste(sort(unique(local_dwelings$TIME_PERIOD)), collapse = ", ")),
  paste0("- Building categories: ", paste(sort(unique(local_dwelings$building)), collapse = " | ")),
  paste0("- Distinct geographic labels (`geo`): ", dplyr::n_distinct(local_dwelings$geo)),
  paste0("- Missing values in `OBS_VALUE`: ", sum(is.na(local_dwelings$OBS_VALUE))),
  "- Interpretation: Eurostat extract (`cens_21dwbo_r2`) with 2021 stock of conventional dwellings by building type and ownership status for Spain, NUTS1, and NUTS2 labels.",
  "",
  "## 3) `housingcostoverburdenrate.csv`",
  paste0("- Loaded from: `", file_overburden, "`"),
  "- Delimiter: comma | Encoding: ISO-8859-1",
  paste0("- Shape: ", nrow(local_overburden), " rows x ", ncol(local_overburden), " columns"),
  paste0("- Time coverage (`TIME_PERIOD`): ", min(local_overburden$TIME_PERIOD, na.rm = TRUE), " to ", max(local_overburden$TIME_PERIOD, na.rm = TRUE)),
  paste0("- Distinct geographic codes (`geo`): ", dplyr::n_distinct(local_overburden$geo)),
  paste0("- Missing values in `OBS_VALUE`: ", sum(is.na(local_overburden$OBS_VALUE))),
  "- Interpretation: Eurostat extract (`ILC_LVHO07_R`) with annual housing cost overburden rates at national and NUTS regional levels.",
  "",
  "## Notes",
  "- `dwelings.csv` and `housingcostoverburdenrate.csv` are label-rich exports; geographies are partially in names and may require standardized joins to NUTS codes during cleaning."
)

writeLines(audit_lines, file.path(paths$docs, "local_data_audit.md"))

message("01_load_local_data.R completed.")
