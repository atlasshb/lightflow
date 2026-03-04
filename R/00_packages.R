options(
  stringsAsFactors = FALSE,
  scipen = 999
)

major_minor <- paste0(
  R.version$major, ".",
  strsplit(R.version$minor, "\\.")[[1]][1]
)

if (.Platform$OS.type == "windows") {
  user_lib <- file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library", major_minor)
} else {
  user_lib <- file.path(path.expand("~"), "R", "library", major_minor)
}

dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(unique(c(user_lib, .libPaths())))

required_packages <- c(
  "tidyverse",
  "eurostat",
  "sf",
  "giscoR",
  "janitor",
  "lubridate",
  "scales",
  "glue",
  "stringi",
  "ragg",
  "viridis"
)

missing_packages <- setdiff(required_packages, rownames(installed.packages()))
if (length(missing_packages) > 0) {
  install.packages(
    missing_packages,
    repos = "https://cloud.r-project.org",
    dependencies = TRUE
  )
}

invisible(lapply(required_packages, function(pkg) {
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}))

atlas_project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)

atlas_paths <- function(root = atlas_project_root) {
  paths <- list(
    root = root,
    r = file.path(root, "R"),
    data_raw = file.path(root, "data_raw"),
    data_clean = file.path(root, "data_clean"),
    figures_png = file.path(root, "figures", "png"),
    figures_pdf = file.path(root, "figures", "pdf"),
    docs = file.path(root, "docs")
  )

  invisible(lapply(paths[c("r", "data_raw", "data_clean", "figures_png", "figures_pdf", "docs")], function(p) {
    dir.create(p, recursive = TRUE, showWarnings = FALSE)
  }))

  paths
}

paths <- atlas_paths()

extract_date <- function() {
  format(Sys.Date(), "%Y-%m-%d")
}
