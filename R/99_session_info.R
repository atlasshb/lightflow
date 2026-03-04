source(file.path("R", "00_packages.R"))

out_file <- file.path(paths$root, "session_info.txt")

con <- file(out_file, open = "wt")
on.exit(close(con), add = TRUE)

writeLines(paste0("Session info generated on: ", Sys.time()), con = con)
writeLines("", con = con)
writeLines("=== sessionInfo() ===", con = con)
writeLines(capture.output(sessionInfo()), con = con)
writeLines("", con = con)

tracked_packages <- c(
  "tidyverse",
  "eurostat",
  "sf",
  "giscoR",
  "ggplot2",
  "dplyr",
  "readr",
  "tidyr",
  "scales",
  "stringr",
  "lubridate",
  "janitor",
  "viridis"
)

pkg_info <- installed.packages() |>
  as.data.frame() |>
  dplyr::filter(Package %in% tracked_packages) |>
  dplyr::arrange(Package) |>
  dplyr::select(Package, Version, LibPath)

writeLines("=== Key package versions ===", con = con)
writeLines(capture.output(print(pkg_info, row.names = FALSE)), con = con)

message("99_session_info.R completed.")
