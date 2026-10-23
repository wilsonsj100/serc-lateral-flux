##Sonde data gaps

files <- list.files("C:/Users/readz/OneDrive - Smithsonian Institution/Lonneman, Michael's files - cpop-data-share-20261019/sonde_USA-MDA_SERC-GCREW/L3_figshare/data", full.names = TRUE)

exo <- lapply(files, read.csv) %>%
  bind_rows() %>% 
  mutate(timestamp_utc = ymd_hms(timestamp_utc, tz = "UTC"))

exo <- exo %>% 
  mutate(just_id = gsub("loggernet-", "", id)) %>% 
  mutate(just_id = gsub("korexo-", "", id))

unique(exo$id)

all_years <- ggplot2::ggplot(exo, ggplot2::aes(x = timestamp_utc, y = water_temperature_c)) +
  ggplot2::geom_point() +
  ggplot2::scale_x_datetime(date_breaks = "1 year", date_labels = "%Y")

# all_years

# Save as a PNG - missing most of 2021? 
png("Sonde_water_temperature.png", width = 2000, height = 500, res = 100) 
print(all_years)  # For ggplot objects, use print()
dev.off() 


# ##Calculate how many days we should have per year
# total_timepoints = 24*365
# 
# exo_summarized <- exo %>% 
#   group_by(day(timestamp_utc), year(timestamp_utc)) %>% 
#   distinct(timestamp_utc) %>% 
#   summarise(n = n(), 
#             percent = n/total_timepoints * 100)

##From ChatGPT: 
library(dplyr)
library(lubridate)
library(tidyr)

# Define the full expected time range
all_days <- tibble(
  day = seq(
    from = as.POSIXct("2018-01-01 00:00:00", tz = "UTC"),
    to   = as.POSIXct("2025-12-31 23:00:00", tz = "UTC"),
    by = "day"
  )
)

# Identify days with at least one observation
observed_days <- exo %>%
  mutate(
    timestamp_utc = ymd_hms(timestamp_utc, tz = "UTC"),
    day = floor_date(timestamp_utc, "day")
  ) %>%
  distinct(day)

# Identify missing days
missing_days <- all_days %>%
  anti_join(observed_days, by = "day")

# Count missing days
nrow(missing_days)


missing_by_year <- all_days %>%
  mutate(year = year(day)) %>%
  left_join(
    observed_days %>% mutate(present = TRUE),
    by = "day"
  ) %>%
  group_by(year) %>%
  summarise(
    total_days = n(),
    days_with_data = sum(!is.na(present)),
    missing_days = sum(is.na(present)),
    percent_missing = round(100 * missing_days / total_days, 2),
    .groups = "drop"
  )

print(missing_by_year)


library(ggplot2)

missing_data <- ggplot(missing_by_year, aes(x = factor(year), y = percent_missing)) +
  geom_col() +
  labs(
    x = "Year",
    y = "Missing days (%)",
    title = "Percentage of Missing Sonde Data by Year"
  ) +
  theme_bw()

missing_data

# Save as a PNG - missing most of 2021? 
png("Sonde_missing_data.png", width = 500, height = 500, res = 100) 
print(missing_data)  # For ggplot objects, use print()
dev.off() 
