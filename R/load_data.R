load_data <- function(file){
  data_raw <- read_csv(file, col_types = cols(.default = "c"), skip = 1)
  
  #Account for different formatting among files
  if("GENX_CH4ppm" %in% colnames(data_raw)){
    data_small <- data_raw %>%
      rename(CH4d_ppm = GENX_CH4ppm,
             CO2d_ppm = GENX_CO2ppm,
             N2Od_ppb = GENX_N20ppb,
             MIU_VALVE = Fluxing_Chamber) %>% 
      mutate(Format = "NEW") %>%
      select(TIMESTAMP, CH4d_ppm, CO2d_ppm, N2Od_ppb, MIU_VALVE, Manifold_Timer, Format)
  } else if("GENX_CH4ppb" %in% colnames(data_raw)){
    message(file, " has CH4ppb")
    data_small <- data_raw %>%
      mutate(CH4d_ppm = as.numeric(GENX_CH4ppb),
             CH4d_ppm = as.character(ifelse(CH4d_ppm > 1000, 
                                            CH4d_ppm/1000, CH4d_ppm)),
             N2Od_ppb = as.numeric(GENX_N20ppm),
             N2Od_ppb = as.character(ifelse(as.numeric(N2Od_ppb) > 10000, 
                                            N2Od_ppb,
                                            N2Od_ppb * 1000))) %>%
      rename(CO2d_ppm = GENX_CO2ppm,
             MIU_VALVE = Fluxing_Chamber) %>% 
      mutate(Format = "NEW") %>%
      select(TIMESTAMP, CH4d_ppm, CO2d_ppm, N2Od_ppb, MIU_VALVE, Manifold_Timer, Format)
  } else if("LGR_Time" %in% colnames(data_raw)){
    data_small <- data_raw %>%
      filter(is.na(LGR_Time) | !duplicated(LGR_Time) | 
               !duplicated(CH4d_ppm)) %>% #I've spent some time looking into this and there are some duplicated LGR rows
      mutate(Manifold_Timer = NA,
             N2Od_ppb = NA) %>% 
      mutate(Format = "OLD") %>%
      select(TIMESTAMP, CH4d_ppm, CO2d_ppm, N2Od_ppb, MIU_VALVE, Manifold_Timer, Format)
  } else {
    data_small <- data_raw %>%
      mutate(Manifold_Timer = NA,
             N2Od_ppb = NA) %>% 
      mutate(Format = "OLD") %>%
      select(TIMESTAMP, CH4d_ppm, CO2d_ppm, N2Od_ppb, MIU_VALVE, Manifold_Timer, Format)
  }
  
  return(data_small)
}

load_wl <- function(file){
  data_raw <- read_csv(file, col_types = cols(.default = "c"), skip = 1)
  
  #Account for different formatting among files
  if("H21_Depth" %in% colnames(data_raw)){
    data_small <- data_raw %>%
      rename(Depth_cm = H21_Depth,
             Temperature_C = H21_Temperature,
             Salinity_PSU = Derived_Salinity,
             Actual_Conductivity_uScm = H21_Electrical_Conductivity,
             ID = `Hydros_ID(2)`) %>%
      filter(!Depth_cm %in% c("mm", "Smp")) %>% 
      mutate(Depth_cm = as.numeric(Depth_cm) /10) %>% #convert mm to cm
      select(-RECORD, -Statname) 
  } else {
    data_small <- data_raw %>%
      rename(ID = `Aquatroll_ID(2)`,
             Temperature_C = Temperature,
             Salinity_PSU = Salinity,
             Actual_Conductivity_uScm = Actual_Conductivity,
             Depth_cm = Depth) %>% 
      select(-RECORD, -Statname) %>%
      filter(!Depth_cm %in% c("cm", "Smp")) %>%
      mutate(Depth_cm = as.numeric(Depth_cm))
 }
  
  return(data_small)
}
