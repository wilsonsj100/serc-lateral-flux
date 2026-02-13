# TO DO: this approach currently relies on keeping consistent column order - unstable


source(here::here("R", "load_data.R"))
# requires zoo, tidyverse

#' calculate_flux
#'
#' @description
#' This function calculates the raw CH4 fluxes for all files in the dropbox_downloads folder
#'
#' @param days_to_include how many days of historical data to include in output
#'
#' @return list with three compiled files

generate_dashboard_outputs <- function(days_to_include = 100) {
  ### Load files ###
  files <- list.files(here::here("Raw_data"), full.names = T)

  if (length(files) == 0) {
    message("No files to process")
    return(read_csv(here::here("processed_data", "L0.csv"), show_col_types = F))
  }

  exclude <- c("FILL_IN_FILES_TO_EXCLUDE_HERE.csv")

  files <- files[!grepl(paste0(exclude, collapse = "|"), files)]
  message(paste0("Generating outputs for ", length(files), " files"))

  files_exo <- files[grepl("Exo", files)]
  files_rad7 <- files[grepl("Rad7", files)]
  files_sontek <- files[grepl("Sontek", files)]

  TIMEZONE <- "EST" # Used across all

  # Load data
  exo_names <- c(
    "TIMESTAMP", "RECORD", "Date", "Time", "Chlorophyll_RFU", "Chlorophyll_ugL",
    "Conductivity", "FDOM_QSU", "FDOM_RFU", "NLF_conductivity", "ODO_sat",
    "ODO_local", "ODO_MgL", "Pressure_psia", "Salinity_PPT", "Specific_Conductivity_uScm",
    "BGA_PE_RFU", "BGA_PE_ugL", "TDS_mg_L", "Turbidity_FNU", "Wiper_Position_mv",
    "pH", "pH_mv", "Temp_C", "Depth_m", "Battery_v", "Cable_v", "Wiper_Current_ma",
    "sn", "snn"
  )

  hydrology_names <- c(
    "TIMESTAMP", "RECORD", "SONTEK_ID", "Sample_number", "yyyy",
    "MM", "dd", "hh", "Minute", "ss", "Flowrate", "Stage",
    "Mean_velocity", "Total_volume", "Water_depth",
    "Index_velocity", "Cross_area", "Water_temperature",
    "System_status", "Velocity_XZxc", "Velocity_XZzc",
    "Velocity_XZxL", "Velocity_XZxR", "Batt_Vol_Sontek",
    "Pitch_angle", "Roll_angle", "Perc_submergance", "IceScore"
  )

  radon_names <- c(
    "TIMESTAMP", "RECORD", "Record_RAD7", "Year_RAD7", "Month_RAD7",
    "Day_Rad7", "Hour_Rad7", "Minute_Rad7", "Total_Counts_Rad7",
    "Live_Time_Rad7", "PER_TOT_A_Rad7", "PER_TOT_B_Rad7", "PER_TOT_C_Rad7",
    "PER_TOT_D_Rad7", "High_Voltage_Level_Rad7", "High_Voltage_Duty_Rad7",
    "Temp_sample_Rad7", "RH_sample_Rad7", "Leakage_Current_Rad7",
    "Battery_Volt_Rad7", "Pump_current_Rad7", "Flags_Byte_Rad7",
    "Radon_concentration_Rad7", "Radon_concentration_uncertainty_Rad7",
    "Units_Byt_Rad7"
  )

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
    map(read_csv, skip = 4, show_col_types = F, col_names = exo_names) %>%
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
    select(all_of(c(exo_choices, "TIMESTAMP"))) %>%
    filter(as.Date(TIMESTAMP) > Sys.Date() - days(days_to_include))

  data_hydrology <- files_sontek %>%
    map(read_csv, skip = 4, show_col_types = F, col_names = hydrology_names) %>%
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
    select(all_of(c(hydrology_choices, "TIMESTAMP"))) %>%
    filter(as.Date(TIMESTAMP) > Sys.Date() - days(days_to_include))

  data_radon <- files_rad7 %>%
    map(read_csv,
      skip = 4, show_col_types = F,
      col_names = radon_names
    ) %>%
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
    select(all_of(c(radon_choices, "TIMESTAMP"))) %>%
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

  return(list(data_exo, data_radon, data_hydrology))
}


# generate_dashboard_outputs()
