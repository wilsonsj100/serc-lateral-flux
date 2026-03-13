# Source
source(here::here("R", "drop_dir.R"))
source(here::here("R", "get_dropbox_token.R"))
source(here::here("R", "load_file.R"))
library(tidyverse)

#' download_new_data
#'
#' @description
#' This function looks for data files on dropbox that are new or have been modified since we last loaded data
#'
#' @return NULL
#' @export
#'
#' @examples
download_new_data <- function(gcrew_folder = here::here("Raw_data"),
                              start_date = Sys.Date() - days(100),
                              current_path = "GCREW_LOGGERNET_DATA/current_data",
                              archive_path = "GCREW_LOGGERNET_DATA/archive_data",
                              search_term = "MARSH_OUTLET") {
  # Identify all files
  message("Looking for new data files on dropbox")
  relevant_files <- drop_dir(path = archive_path) %>%
    filter(grepl(search_term, name))
  current <- drop_dir(path = current_path) %>%
    filter(
      grepl(search_term, name),
      !grepl("backup", name)
    )

  possible_file_names <- format(
    seq.Date(start_date, Sys.Date(), by = "1 day"),
    "%Y%m%d"
  )
  relevant_files <- relevant_files[
    grepl(paste0(possible_file_names, collapse = "|"), relevant_files$name),
  ]
  relevant_files <- relevant_files[!grepl("NewConstTable", relevant_files$name), ]

  # Remove files that are already loaded and haven't been modified
  already_loaded <- list.files(gcrew_folder)
  loaded_file_info <- file.info(list.files(gcrew_folder, full.names = T)) %>%
    mutate(name = basename(row.names(.))) %>%
    select(name, mtime)
  modified <- relevant_files %>%
    select(name, server_modified) %>%
    left_join(loaded_file_info, by = "name") %>%
    filter(server_modified > mtime)
  relevant_files <- relevant_files %>% # Only process files that are new or have been modified on dropbox
    filter(!name %in% already_loaded | name %in% modified$name)

  # Load current data file
  new <- current$path_display %>%
    map(load_file,
      output_dir = gcrew_folder,
      current_path = current_path,
      archive_path = archive_path
    )

  if (nrow(relevant_files) == 0) {
    message("No new files to download")
  } else {
    message("Downloading ", nrow(relevant_files), " files")
    all_data <- relevant_files$path_display %>%
      map(load_file,
        output_dir = gcrew_folder,
        current_path = current_path,
        archive_path = archive_path
      )
  }
}
