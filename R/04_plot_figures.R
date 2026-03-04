source(file.path("R", "00_packages.R"))

theme_atlas_policy <- function(base_size = 11, base_family = "sans") {
  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", size = base_size + 2),
      plot.subtitle = ggplot2::element_text(size = base_size, margin = ggplot2::margin(b = 8)),
      plot.caption = ggplot2::element_text(size = base_size - 2, hjust = 0, color = "#4D4D4D"),
      axis.title = ggplot2::element_text(face = "bold"),
      legend.title = ggplot2::element_text(face = "bold"),
      legend.position = "bottom"
    )
}

atlas_palette <- c(
  "Rental price index (HICP CP041)" = "#C0392B",
  "Compensation per employee" = "#1F618D",
  "16-29" = "#C0392B",
  "30-64" = "#2471A3",
  "65+" = "#117A65",
  "1-dwelling building" = "#1F618D",
  "2-dwelling building" = "#45B39D",
  "3+ dwelling building" = "#F5B041"
)

save_plot_both <- function(plot_obj, figure_id, width = 7.5, height = 5.2) {
  ggplot2::ggsave(
    filename = file.path(paths$figures_png, paste0(figure_id, ".png")),
    plot = plot_obj,
    width = width,
    height = height,
    dpi = 300
  )
  ggplot2::ggsave(
    filename = file.path(paths$figures_pdf, paste0(figure_id, ".pdf")),
    plot = plot_obj,
    width = width,
    height = height,
    device = cairo_pdf
  )
}

fig1_data <- readRDS(file.path(paths$data_clean, "figure_1_rent_vs_wage_index.rds"))
fig2_data <- readRDS(file.path(paths$data_clean, "figure_2_overburden_age_groups.rds"))
fig3_map <- readRDS(file.path(paths$data_clean, "figure_3_tourism_nuts3_map.rds"))
fig3_meta <- readRDS(file.path(paths$data_clean, "figure_3_metadata.rds"))
fig4_data <- readRDS(file.path(paths$data_clean, "figure_4_supply_per_capita_by_type.rds"))
fig5_map <- readRDS(file.path(paths$data_clean, "figure_5_multi_dwelling_share_nuts2_map.rds"))

caption_date <- extract_date()

# Figure 1
p1 <- ggplot2::ggplot(
  fig1_data,
  ggplot2::aes(x = year, y = index_2015_100, color = series)
) +
  ggplot2::geom_line(linewidth = 1.1) +
  ggplot2::scale_color_manual(values = atlas_palette[c(
    "Rental price index (HICP CP041)",
    "Compensation per employee"
  )]) +
  ggplot2::scale_x_continuous(breaks = seq(min(fig1_data$year), max(fig1_data$year), by = 2)) +
  ggplot2::labs(
    title = "Rental Price Index vs Wage Index in Spain",
    subtitle = "Rental prices increased faster than compensation per employee between 2010 and 2023.",
    x = NULL,
    y = "Index (2015=100)",
    color = NULL,
    caption = paste0(
      "Source: Eurostat (prc_hicp_ainr; nama_10r_2lp10). Extracted on ",
      caption_date,
      "."
    )
  ) +
  theme_atlas_policy()

save_plot_both(p1, "figure_1")

# Figure 2
p2 <- ggplot2::ggplot(
  fig2_data,
  ggplot2::aes(x = year, y = overburden_rate, color = age_group)
) +
  ggplot2::geom_line(linewidth = 1.1) +
  ggplot2::scale_color_manual(values = atlas_palette[c("16-29", "30-64", "65+")]) +
  ggplot2::scale_x_continuous(breaks = seq(min(fig2_data$year), max(fig2_data$year), by = 2)) +
  ggplot2::scale_y_continuous(labels = scales::label_number(suffix = "%", accuracy = 0.1)) +
  ggplot2::labs(
    title = "Housing Cost Overburden Rate by Age Group in Spain",
    subtitle = "Young adults face persistently higher overburden than older age groups (2010-2023).",
    x = NULL,
    y = "Overburden rate (%)",
    color = "Age group",
    caption = paste0(
      "Source: Eurostat (ilc_lvho07a; demo_pjan). Extracted on ",
      caption_date,
      ". Age 30-64 is derived from available Eurostat age bins using population weights."
    )
  ) +
  theme_atlas_policy()

save_plot_both(p2, "figure_2")

# Figure 3
fig3_year <- fig3_meta$latest_complete_year[[1]]

p3 <- ggplot2::ggplot(fig3_map) +
  ggplot2::geom_sf(ggplot2::aes(fill = nights_spent), color = "white", linewidth = 0.15) +
  ggplot2::scale_fill_viridis_c(
    option = "magma",
    direction = -1,
    trans = "sqrt",
    labels = scales::label_number(big.mark = ",")
  ) +
  ggplot2::labs(
    title = paste0("Tourism Pressure Across Spanish NUTS3 Regions (", fig3_year, ")"),
    subtitle = "Annual nights spent in tourist accommodation reveal strong spatial concentration.",
    fill = "Nights spent",
    caption = paste0(
      "Source: Eurostat (tour_occ_nin3) and GISCO NUTS (2021). Extracted on ",
      caption_date,
      ". Unit: number of nights (`NR`), residents `TOTAL`, NACE `I551-I553`."
    )
  ) +
  theme_atlas_policy() +
  ggplot2::theme(
    axis.text = ggplot2::element_blank(),
    axis.title = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    panel.grid = ggplot2::element_blank()
  )

save_plot_both(p3, "figure_3", width = 7.8, height = 6.1)

# Figure 4
fig4_data$building_type <- factor(
  fig4_data$building_type,
  levels = c("1-dwelling building", "2-dwelling building", "3+ dwelling building")
)

p4 <- ggplot2::ggplot(
  fig4_data,
  ggplot2::aes(x = year, y = new_dwellings_per_1000, fill = building_type)
) +
  ggplot2::geom_area(alpha = 0.95, color = "white", linewidth = 0.2) +
  ggplot2::scale_fill_manual(values = atlas_palette[c(
    "1-dwelling building",
    "2-dwelling building",
    "3+ dwelling building"
  )]) +
  ggplot2::scale_x_continuous(breaks = seq(2000, 2024, by = 2)) +
  ggplot2::scale_y_continuous(labels = scales::label_number(accuracy = 0.1)) +
  ggplot2::labs(
    title = "New Dwellings Supply per 1,000 Inhabitants in Spain",
    subtitle = "Stacked composition by building type, 2000-2024.",
    x = NULL,
    y = "New dwellings per 1,000 inhabitants",
    fill = "Building type",
    caption = paste0(
      "Source: Eurostat (sts_cobp_a; demo_pjan) and local census extract (cens_21dwbo_r2). ",
      "Extracted on ", caption_date, ". Type composition is estimated with documented proxy assumptions."
    )
  ) +
  theme_atlas_policy()

save_plot_both(p4, "figure_4")

# Figure 5
p5 <- ggplot2::ggplot(fig5_map) +
  ggplot2::geom_sf(ggplot2::aes(fill = share_multi_dwelling), color = "white", linewidth = 0.2) +
  ggplot2::scale_fill_viridis_c(
    option = "plasma",
    direction = -1,
    labels = scales::label_number(accuracy = 0.1, suffix = "%")
  ) +
  ggplot2::labs(
    title = "Share of Multi-Dwelling Residential Buildings in Total New Construction by Region (2021)",
    subtitle = "Spanish NUTS2 regions, based on the local Eurostat CENS extract.",
    fill = "Share",
    caption = paste0(
      "Source: Local file `dwelings.csv` (Eurostat cens_21dwbo_r2) + GISCO NUTS (2021). Extracted on ",
      caption_date,
      ". Numerator: `Three or more dwelling residential buildings`; denominator: `Total`."
    )
  ) +
  theme_atlas_policy() +
  ggplot2::theme(
    axis.text = ggplot2::element_blank(),
    axis.title = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    panel.grid = ggplot2::element_blank()
  )

save_plot_both(p5, "figure_5", width = 7.8, height = 6.1)

message("04_plot_figures.R completed.")
