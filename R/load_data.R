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
      mutate(CH4d_ppb = CH4d_ppm_LGR1 * 1000) %>%
      rename(CO2d_ppm = CO2d_ppm_LGR1,
             H2O_ppm = H2O_ppm_LGR1,
             Cavity_pressure = GasP_torr_LGR1,
             Cavity_temperature = GasT_C_LGR1
             )
  }
  
  if("CH4" %in% names) {
    data <- data %>%
      rename(H2O_ppm = H2O,
             CO2d_ppm = CO2,
             CH4d_ppb = CH4,
             Cavity_pressure = cavity_p,
             Cavity_temperature = cavity_t)
  }

  return(data)
}
