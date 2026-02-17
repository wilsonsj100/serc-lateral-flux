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

  return(data)
}
