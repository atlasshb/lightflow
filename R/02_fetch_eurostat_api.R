source(file.path("R", "00_packages.R"))

fetch_or_load_eurostat <- function(code) {
  cache_file <- file.path(paths$data_raw, paste0("eurostat_", code, ".rds"))

  if (file.exists(cache_file)) {
    dat <- readRDS(cache_file)
    message(glue::glue("Loaded cached Eurostat dataset: {code}"))
    return(dat)
  }

  dat <- eurostat::get_eurostat(
    id = code,
    time_format = "num",
    cache = TRUE
  )
  saveRDS(dat, cache_file)
  message(glue::glue("Downloaded and cached Eurostat dataset: {code}"))
  dat
}

dataset_codes <- c(
  "prc_hicp_ainr",
  "nama_10r_2lp10",
  "ilc_lvho07a",
  "tour_occ_nin3",
  "sts_cobp_a",
  "demo_pjan"
)

downloaded <- purrr::set_names(
  lapply(dataset_codes, fetch_or_load_eurostat),
  dataset_codes
)

manifest <- purrr::imap_dfr(downloaded, function(dat, code) {
  has_time <- "TIME_PERIOD" %in% names(dat)
  tibble::tibble(
    dataset_code = code,
    rows = nrow(dat),
    cols = ncol(dat),
    min_time = if (has_time) suppressWarnings(min(dat$TIME_PERIOD, na.rm = TRUE)) else NA_real_,
    max_time = if (has_time) suppressWarnings(max(dat$TIME_PERIOD, na.rm = TRUE)) else NA_real_,
    extracted_on = extract_date()
  )
})

readr::write_csv(manifest, file.path(paths$data_raw, "eurostat_manifest.csv"))

message("02_fetch_eurostat_api.R completed.")
