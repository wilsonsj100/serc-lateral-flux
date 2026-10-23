library(dplyr)
library(lubridate)
library(data.table)

common_tz = "Etc/GMT+5"

##Clean Figshare-ready exo data
exo <- read.csv("C:/Users/readz/OneDrive - Smithsonian Institution/Lonneman, Michael's files - cpop-data-share-20261019/sonde_USA-MDA_SERC-GCREW/L3_figshare/data/2025_figshare_data_USA-MDA_water-quality_SERC-GCREW.csv")
exo <- exo %>%
  mutate(timestamp = force_tz(parsedate::parse_date(timestamp_utc), tzone = common_tz), 
         datetime = round_date(timestamp, "5 minutes")) %>%  
  select(datetime, odo_mg_l, fdom_qsu,  salinity_ppt , ph, #ORP_mV, (don't have)
         sonde_depth_m, water_temperature_c) %>% #, index_velocity
  rename(DO = odo_mg_l, fDOM = fdom_qsu,  #flow = index_velocity, #ORP = ORP_mV,
         S = salinity_ppt, H = sonde_depth_m, T = water_temperature_c, pH = ph) %>% 
  mutate(datasource = 'Figshare')

#To match bottle and sensor data, round to 5 mins
bottle_data <- read.csv("C:/Users/readz/OneDrive - Smithsonian Institution/serc-lateral-flux/Figshare/FATE-Monitoring DIC-DOC/FATE_Monitoring_DIC_DOC_2025.csv")

bottle_data <- bottle_data %>%
  mutate(
    datetime = ymd_hm(
      paste(date, time_local),
      tz = "America/New_York"),
    datetime = with_tz(datetime, tzone = common_tz), 
    datetime = round_date(datetime, "5 minutes"))


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

write.csv(merged_data, "Figshare_bottle_data.csv")

