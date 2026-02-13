

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





load_data <- function(file) {
  site <- ifelse(grepl("MGEO", file),
                 "DOCK",
                 "FLUME")
  
  names <- colnames(read_delim(file, delim = ",", skip = 1, 
                               show_col_types = F, n_max = 1))
  
  data <- read_csv(file, skip = 4, show_col_types = F, col_names = names) %>%
    mutate(Site = site)
  
  #Standardize formatting
  if("Specific_Conductivity_mScm" %in% names){
    data <- data %>%
      mutate(Specific_Conductivity_uScm = Specific_Conductivity_mScm * 1000) %>%
      select(-Specific_Conductivity_mScm)
  }
  
  if("Level_m_CBS" %in% names){
    data <- data %>%
      rename(Water_depth = Level_m_CBS)
  }

  return(data)
}
