common_tz = "Etc/GMT+5"

##Clean Figshare-ready exo data
exo1 <- read.csv("C:/Users/readz/OneDrive - Smithsonian Institution/Lonneman, Michael's files - cpop-data-share-20261019/sonde_USA-MDA_SERC-GCREW/L3_figshare/data/2025_figshare_data_USA-MDA_water-quality_SERC-GCREW.csv")
exo1 <- exo1 %>%
  mutate(timestamp = force_tz(parsedate::parse_date(timestamp_utc), tzone = common_tz), 
         datetime = round_date(timestamp, "5 minutes")) %>%  
  select(datetime, odo_mg_l, fdom_qsu,  salinity_ppt , ph, #ORP_mV, (don't have)
         sonde_depth_m, water_temperature_c) %>% #, index_velocity
  rename(DO = odo_mg_l, fDOM = fdom_qsu,  #flow = index_velocity, #ORP = ORP_mV,
         S = salinity_ppt, H = sonde_depth_m, T = water_temperature_c, pH = ph) %>% 
  mutate(datasource = 'Figshare')

####Same thing for korexo data

##Clean exo data
exo2 <- read.csv("C:/Users/readz/OneDrive - Smithsonian Institution/serc-lateral-flux/Figshare/Sonde/korexo_2025.csv")
exo2 <- exo2 %>%
  mutate(
    datetime = mdy_hms(
      paste(date, time),
      tz = "Etc/GMT+5"),
    datetime = with_tz(datetime, tzone = common_tz), 
    datetime = round_date(datetime, "5 minutes")) %>% 
  select(datetime, ODO.mg.L, fDOM.QSU,  Sal.psu , pH, #ORP_mV, (don't have)
         Depth.m, Temp..C) %>% #, index_velocity
  rename(DO = ODO.mg.L, fDOM = fDOM.QSU,  #flow = index_velocity, #ORP = ORP_mV,
         S = Sal.psu, H = Depth.m, T = Temp..C, pH = pH) %>% 
  mutate(datasource = 'korexo')

exo <- bind_rows(exo1, exo2)

#To match bottle and sensor data, round to 5 mins
bottle_data <- read.csv("C:/Users/readz/OneDrive - Smithsonian Institution/serc-lateral-flux/Figshare/FATE-Monitoring DIC-DOC/FATE_Monitoring_DIC_DOC_2025.csv")

bottle_data <- bottle_data %>%
  mutate(
    datetime = ymd_hm(
      paste(date, time_local),
      tz = "America/New_York"),
    datetime = with_tz(datetime, tzone = common_tz), 
    datetime = round_date(datetime, "5 minutes"))


date_data <- subset(exo, as.Date(datetime) == as.Date("2025-04-24"))
##Data goes up by 5 but skips :45 minute for some reason

library(data.table)
library(lubridate)

exo_dt <- as.data.table(exo)
bottle_dt <- as.data.table(bottle_data)

# Extract dates and preserve original exo datetime
exo_dt[, Date := as.Date(datetime, tz = "America/New_York")]
bottle_dt[, Date := as.Date(datetime, tz = "America/New_York")]

exo_dt[, datetime_exo := datetime]

# Match nearest datetime within the same day
merged_data <- exo_dt[
  bottle_dt,
  on = .(Date, datetime),
  roll = "nearest"
]

# Calculate difference in minutes
merged_data[, time_diff_min := abs(as.numeric(
  difftime(datetime, datetime_exo, units = "mins")
))]

merged_data <- subset(merged_data, !is.na(datetime_exo))

merged_data <- merged_data %>%
  group_by(datetime) %>%
  slice_max(
    order_by = coalesce(datasource == "Figshare", FALSE),
    n = 1,
    with_ties = FALSE
  ) %>%
  ungroup()

write.csv(merged_data, "Figshare_and_korexo_bottle_data.csv")

