# ========================== Read in korexo data ================================

dat1 <- read.csv("C:/Users/readz/Smithsonian Dropbox/Zoe Read/GCREW Water Monitoring Marsh Outlet/Korexo CSV files/GCREW_KorEXO Measurement File Export - 040825 114625.csv", skip = 9,   fileEncoding = "UTF-16LE", colClasses = "character") %>% mutate(filename = "C:/Users/readz/Smithsonian Dropbox/Zoe Read/GCREW Water Monitoring Marsh Outlet/Korexo CSV files/GCREW_KorEXO Measurement File Export - 040825 114625.csv")

dat2 <- read.csv("C:/Users/readz/Smithsonian Dropbox/Zoe Read/GCREW Water Monitoring Marsh Outlet/Korexo CSV files/GCREW_KorEXO Measurement File Export - 081925 115608.csv", skip = 9,   fileEncoding = "UTF-16LE", colClasses = "character") %>% mutate(filename = "C:/Users/readz/Smithsonian Dropbox/Zoe Read/GCREW Water Monitoring Marsh Outlet/Korexo CSV files/GCREW_KorEXO Measurement File Export - 081925 115608.csv") %>% rename(Pressure.psi.a = Pressure.psi.g)

dat3 <- read.csv("C:/Users/readz/Smithsonian Dropbox/Zoe Read/GCREW Water Monitoring Marsh Outlet/Korexo CSV files/GCREW_KorEXO Measurement File Export - 040825 114813.csv", skip = 9,   fileEncoding = "UTF-16LE", colClasses = "character") %>% mutate(filename = "C:/Users/readz/Smithsonian Dropbox/Zoe Read/GCREW Water Monitoring Marsh Outlet/Korexo CSV files/GCREW_KorEXO Measurement File Export - 040825 114813.csv")

dat4 <- read.csv("C:/Users/readz/Smithsonian Dropbox/Zoe Read/GCREW Water Monitoring Marsh Outlet/Korexo CSV files/GCREW_KorEXO Measurement File Export - 030425 140426.csv", skip = 9,   fileEncoding = "UTF-16LE", colClasses = "character") %>% mutate(filename = "C:/Users/readz/Smithsonian Dropbox/Zoe Read/GCREW Water Monitoring Marsh Outlet/Korexo CSV files/GCREW_KorEXO Measurement File Export - 030425 140426.csv")

dat5 <- read.csv("C:/Users/readz/Smithsonian Dropbox/Zoe Read/GCREW Water Monitoring Marsh Outlet/Korexo CSV files/GCREW_KorEXO Measurement File Export - 090525 134112.csv", skip = 9,   fileEncoding = "UTF-16LE", colClasses = "character") %>% mutate(filename = "C:/Users/readz/Smithsonian Dropbox/Zoe Read/GCREW Water Monitoring Marsh Outlet/Korexo CSV files/GCREW_KorEXO Measurement File Export - 090525 134112.csv") %>% rename(Pressure.psi.a = Pressure.psi.g)

dat6 <- read.csv("C:/Users/readz/Smithsonian Dropbox/Zoe Read/GCREW Water Monitoring Marsh Outlet/Korexo CSV files/GCREW_KorEXO Measurement File Export - 010726 155857.csv", skip = 9,   fileEncoding = "UTF-16LE", colClasses = "character") %>% mutate(filename = "C:/Users/readz/Smithsonian Dropbox/Zoe Read/GCREW Water Monitoring Marsh Outlet/Korexo CSV files/GCREW_KorEXO Measurement File Export - 010726 155857.csv")

dat7 <- read.csv("C:/Users/readz/Smithsonian Dropbox/Zoe Read/GCREW Water Monitoring Marsh Outlet/Korexo CSV files/GCREW_KorEXO Measurement File Export - 050825 100742.csv", skip = 9,   fileEncoding = "UTF-16LE", colClasses = "character") %>% mutate(filename = "C:/Users/readz/Smithsonian Dropbox/Zoe Read/GCREW Water Monitoring Marsh Outlet/Korexo CSV files/GCREW_KorEXO Measurement File Export - 050825 100742.csv")


df_data <- bind_rows(dat1, dat2, dat3, dat4, dat5, dat6, dat7)
df_data <- df_data %>% 
  filter(Site.Name == "GCREW Marsh Outlet") %>% 
  rename(date = Date..MM.DD.YYYY., 
         time = Time..HH.mm.ss.)

# write.csv(df_data, "korexo_2025.csv")

# ========================== Create timestamps ================================

site_timezone <- "America/Jamaica"

df_data <- df_data %>% 
  # Create timestamp local column by pasting date and time
  mutate(timestamp_local = paste(date, time, sep = " ")) %>%
  # Now set as date class and replicate to keep original ts before rounding
  mutate(timestamp_local = mdy_hms(timestamp_local, tz = site_timezone),
         timestamp_original = timestamp_local) %>%
  mutate(timestamp_local = floor_date(timestamp_local, "minutes"),
         timestamp_utc = with_tz(timestamp_local, tzone = "UTC")) %>%
  mutate(timestamp_utc = format(timestamp_utc, "%Y-%m-%d %H:%M:%S+00:00", tz = "UTC"))

# Round seconds to nearest minute
df_data <- df_data %>% 
  mutate(timestamp_local = round_date(timestamp_local, "minutes"))

# Check time increment
# Make sure it's in minutes using difftime() function
diffs <- unique(difftime(df_data$timestamp_local, lag(df_data$timestamp_local), units = "mins"))

# If increment is 6, 15, or NA (because only 1 row of data), round to the last 6 min increment. 
# Otherwise flag
if((nrow(df_data) == 1) | (6 %in% round(diffs, digits = 0)) | (0 %in% (diffs %% 6))){
  # Round minutes to every 6 minutes
  minute_time <- floor(minute(df_data$timestamp_local)/6)*6
  df_data$timestamp_local <- update(df_data$timestamp_local, min = minute_time)
} else if ((15 %in% round(diffs, digits = 0)) | (0 %in% (diffs %% 15))){
  warning("15 min time interval", immediate. = T)
  # Round minutes to every 6 minutes
  minute_time <- floor(minute(df_data$timestamp_local)/6)*6
  df_data$timestamp_local <- update(df_data$timestamp_local, min = minute_time)
} else if ((5 %in% round(diffs, digits = 0)) | (0 %in% (diffs %% 5))){
  # First round minutes to every five minutes
  minute_time <- floor(minute(df_data$timestamp_local)/5)*5
  df_data$timestamp_local <- update(df_data$timestamp_local, min = minute_time)
  # Then, drop where minutes = 5 or 35
  df_data <- df_data %>%
    filter(minute(timestamp_local) %in% c(5, 35) == F)
  
  # Now floor to every 6 minutes
  minute_time <- floor(minute(df_data$timestamp_local)/6)*6
  df_data$timestamp_local <- update(df_data$timestamp_local, min = minute_time)
  
  warning("5 minute time interval", immediate. = T)
} else{
  warning("Unfamiliar time interval", immediate. = T)
}

# Test for NA timestamps and print NA timestamps
anyNA(df_data$timestamp_local)

# ========================== Fix column names ================================

all_data <- read_csv(list.files("C:/Users/readz/OneDrive - Smithsonian Institution/Lonneman, Michael's files - cpop-data-share-20261019/sonde_USA-MDA_SERC-GCREW/L1_korexo/data", full.names = T))

##Fix column names
colnames(all_data)
colnames(df_data)

df_data <- df_data %>% 
  mutate(instrument_id = "USA-MDA_water-quality_SERC-GCREW", 
         deployment_id = paste0(min(timestamp_original), "_", max(timestamp_original)), 
         deployment_id = gsub(":", "", deployment_id), 
         conductivity_ms_cm = as.numeric(Cond.µS.cm)/1000,
         nlf_conductivity_ms_cm = as.numeric(nLF.Cond.µS.cm)/1000,
         specific_conductivity_ms_cm = as.numeric(SpCond.µS.cm)/1000) %>% 
  rename(input_filename = filename, 
         sonde_battery_v = Battery.V, 
         bga_pe_ug_l = TAL.PE.ug.L, 
         bga_pe_rfu = TAL.PE.RFU, 
         sonde_cable_v = Cable.Pwr.V, 
         chlorophyll_rfu = Chlorophyll.RFU, 
         chlorophyll_ug_l = Chlorophyll.ug.L, 
         sonde_depth_m = Depth.m, 
         fdom_qsu = fDOM.QSU, 
         fdom_rfu = fDOM.RFU, 
         odo_local_percent = ODO...local, 
         odo_mg_l = ODO.mg.L, 
         odo_sat_percent = ODO...sat, 
         ph = pH, 
         ph_mv = pH.mV, 
         water_pressure_psia = Pressure.psi.a, 
         salinity_ppt = Sal.psu, 
         tds_mg_l = TDS.mg.L, 
         water_temperature_c = Temp..C, 
         tss_mg_l = TSS.mg.L, 
         turbidity_fnu = Turbidity.FNU, 
         vertical_position_m = Vertical.Position.m, 
         wiper_position_v = Wiper.Position.volt)



# ========================== Only save new observations and create IDs ================================
# Keep only new observations based on timestamps that are not in destination
  
    # Get max ID from data
    # last_id <- all_data$id[nrow(all_data)]
    max_id <- max(all_data$id)
    
    # Subset korexo data
    subset_data <- df_data %>%
      # Keep distinct values only (for measurements, so exclude input filename and deployment id for distinct)
      distinct(across(-c(input_filename, deployment_id)), .keep_all = T) %>%
      # Filter to keep timestamps that are NOT in all_data timestamp
      filter(!(timestamp_local %in% all_data$timestamp_local)) %>%
      # Create new ids to be k(row number) + max number from all_data
      mutate(id = (row_number() + as.numeric(max_id))) %>% 
      mutate(timestamp_local = format(timestamp_local,"%Y-%m-%d %H:%M:%S")) %>% 
      select(instrument_id, deployment_id, input_filename, id, timestamp_original, timestamp_local, timestamp_utc, sonde_battery_v, bga_pe_ug_l, bga_pe_rfu, sonde_cable_v, chlorophyll_rfu, chlorophyll_ug_l, conductivity_ms_cm, sonde_depth_m, fdom_qsu, fdom_rfu, nlf_conductivity_ms_cm, odo_local_percent, odo_mg_l, odo_sat_percent, ph, ph_mv, water_pressure_psia, salinity_ppt, specific_conductivity_ms_cm, tds_mg_l, water_temperature_c, tss_mg_l, turbidity_fnu, vertical_position_m, wiper_position_v)

setwd("C:/Users/readz/OneDrive - Smithsonian Institution/Lonneman, Michael's files - cpop-data-share-20261019/sonde_USA-MDA_SERC-GCREW/L1_korexo/data/")

output_filename <- paste0("USA-MDA_water-quality_SERC-GCREW_", min(subset_data$timestamp_original), "_", max(subset_data$timestamp_original), ".csv")
output_filename <- gsub(":", "", output_filename)
output_filename

write.csv(subset_data, output_filename, row.names = FALSE)

