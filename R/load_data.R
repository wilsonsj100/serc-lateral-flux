load_data <- function(file) {
  site <- ifelse(grepl("MGEO", file),
    "DOCK",
    "FLUME"
  )

  names <- colnames(read_delim(file,
    delim = ",", skip = 1,
    show_col_types = F, n_max = 1
  ))

  data <- read_csv(file, skip = 4, show_col_types = F, col_names = names) %>%
    mutate(Site = site)

  # Standardize formatting
  if ("Specific_Conductivity_mScm" %in% names) {
    data <- data %>%
      mutate(Specific_Conductivity_uScm = Specific_Conductivity_mScm * 1000) %>%
      select(-Specific_Conductivity_mScm)
  }

  if ("Level_m_CBS" %in% names) {
    data <- data %>%
      rename(Water_depth = Level_m_CBS)
  }
  
  if ("CH4d_ppm_LGR1" %in% names) {
    data <- data %>%
      mutate(Cavity_pressure_kPa = GasP_torr_LGR1 / 7.500616827) %>%
      rename(CO2d_ppm = CO2d_ppm_LGR1,
             CH4d_ppm = CH4d_ppm_LGR1,
             H2O_ppm = H2O_ppm_LGR1,
             Cavity_temperature_C = GasT_C_LGR1
             ) %>%
      select(-LGR_Time)
  }
  
  if("CH4" %in% names) {
    data <- data %>%
      mutate(CH4d_ppm = CH4 / 1000) %>%
      rename(H2O_ppm = H2O,
             CO2d_ppm = CO2,
             Cavity_pressure_kPa = cavity_p,
             Cavity_temperature_C = cavity_t)
  }

  return(data)
}
