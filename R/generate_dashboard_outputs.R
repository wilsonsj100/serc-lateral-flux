source(here::here("R", "download_new_data.R"))
source(here::here("R", "load_data.R"))
# requires zoo, tidyverse

#' calculate_flux
#'
#' @description
#' This function loads data from dropbox and compiles four summarized outputs with recent, formatted data
#'
#' @param days_to_include how many days of historical data to include in output
#'
#' @return list with four compiled files

generate_dashboard_outputs <- function(days_to_include = 100) {
  ### First, get local copies of all files ###
  download_new_data(
    gcrew_folder = here::here("Raw_data"),
    start_date = Sys.Date() - days(100),
    current_path = "GCREW_LOGGERNET_DATA/current_data",
    archive_path = "GCREW_LOGGERNET_DATA/archive_data",
    search_term = "MARSH_OUTLET"
  )

  download_new_data(
    gcrew_folder = here::here("Raw_data"),
    start_date = Sys.Date() - days(100),
    current_path = "MarineGEO Water Monitoring SERC/SERC_DOCK_Rawdata_Loggernet/SERC_DOCK_current_data",
    archive_path = "MarineGEO Water Monitoring SERC/SERC_DOCK_Rawdata_Loggernet/SERC_DOCK_archive_data",
    search_term = "MGEO_SERC_Rad7|MGEO_SERC_Exo|MGEO_SERC_Level|MGEO_SERC_FLUX"
  )

  ### Load files ###
  files <- list.files(here::here("Raw_data"), full.names = T)

  # Are there any files we have loaded that we want to manually exclude?
  exclude <- c("FILL_IN_FILES_TO_EXCLUDE_HERE.csv")
  files <- files[!grepl(paste0(exclude, collapse = "|"), files)]

  message(paste0("Generating outputs for ", length(files), " files"))

  files_exo <- files[grepl("Exo", files)]
  files_rad7 <- files[grepl("Rad7", files)]
  files_sontek <- files[grepl("Sontek|Level", files)]
  files_flux <- files[grepl("FLUX", files)]

  TIMEZONE <- "EST" # Used across all

  # Load data
  exo_choices <- c(
    "DO_mgL", "FDOM_RFU", "Chlorophyll_ugL", "Conductivity",
    "DO_saturation", "Salinity_PPT", "TDS_mgL", "pH", "Temp_C",
    "Depth_m"
  )

  hydrology_choices <- c(
    "Water_depth_m", "Flowrate_ms", "Index_velocity_ms",
    "Mean_velocity_ms"
  )

  ghg_choices <- c(
    "H2O_ppm", "CO2d_ppm", "CH4d_ppb", "Cavity_pressure",
    "Cavity_temperature"
  )

  radon_choices <- c("Relative_humidity_pct", "Radon_Bqm3", "Radon_error_Bqm3")

  # Load data
  data_exo <- files_exo %>%
    map(load_data) %>%
    bind_rows() %>%
    mutate(
      TIMESTAMP = paste(format(TIMESTAMP, "%Y-%m-%d %H:%M:%S")),
      TIMESTAMP = ymd_hms(TIMESTAMP, tz = TIMEZONE)
    ) %>%
    select(-sn, -snn) %>%
    rename(
      DO_mgL = ODO_MgL,
      DO_saturation = ODO_sat,
      TDS_mgL = TDS_mg_L
    ) %>%
    select(all_of(c("Site", "TIMESTAMP", exo_choices))) %>%
    filter(as.Date(TIMESTAMP) > Sys.Date() - days(days_to_include))

  data_hydrology <- files_sontek %>%
    map(load_data) %>%
    bind_rows() %>%
    mutate(
      TIMESTAMP = paste(format(TIMESTAMP, "%Y-%m-%d %H:%M:%S")),
      TIMESTAMP = ymd_hms(TIMESTAMP, tz = TIMEZONE)
    ) %>%
    rename(
      Water_depth_m = Water_depth,
      Index_velocity_ms = Index_velocity,
      Mean_velocity_ms = Mean_velocity,
      Flowrate_ms = Flowrate
    ) %>%
    select(all_of(c("Site", "TIMESTAMP", hydrology_choices))) %>%
    filter(as.Date(TIMESTAMP) > Sys.Date() - days(days_to_include))

  data_radon <- files_rad7 %>%
    map(load_data) %>%
    bind_rows() %>%
    mutate(
      TIMESTAMP = paste(format(TIMESTAMP, "%Y-%m-%d %H:%M:%S")),
      TIMESTAMP = ymd_hms(TIMESTAMP, tz = TIMEZONE)
    ) %>%
    rename(
      Relative_humidity_pct = RH_sample_Rad7,
      Radon_Bqm3 = Radon_concentration_Rad7,
      Radon_error_Bqm3 = Radon_concentration_uncertainty_Rad7
    ) %>%
    select(all_of(c("Site", "TIMESTAMP", radon_choices))) %>%
    filter(as.Date(TIMESTAMP) > Sys.Date() - days(days_to_include))
  
  data_flux <- files_flux %>%
    map(load_data) %>%
    bind_rows() %>%
    mutate(
      TIMESTAMP = paste(format(TIMESTAMP, "%Y-%m-%d %H:%M:%S")),
      TIMESTAMP = ymd_hms(TIMESTAMP, tz = TIMEZONE)
    ) %>%
    select(all_of(c("Site", "TIMESTAMP", ghg_choices))) %>%
    filter(as.Date(TIMESTAMP) > Sys.Date() - days(days_to_include))

  # Output
  write.csv(data_exo,
    here::here("Processed_data", "GCREW_MARSH_OUTLET_EXO.csv"),
    row.names = FALSE
  )

  write.csv(data_radon,
    here::here("Processed_data", "GCREW_MARSH_OUTLET_RADON.csv"),
    row.names = FALSE
  )

  write.csv(data_hydrology,
    here::here("Processed_data", "GCREW_MARSH_OUTLET_HYDROLOGY.csv"),
    row.names = FALSE
  )
  
  write.csv(data_flux,
            here::here("Processed_data", "GCREW_MARSH_OUTLET_GHG.csv"),
            row.names = FALSE
  )

  return(list(data_exo, data_radon, data_hydrology, data_flux))
}


generate_dashboard_outputs()
