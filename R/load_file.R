load_file <- function(path_display, output_dir) {
  url <- "https://content.dropboxapi.com/2/files/download"
  name <- sub(
    "/GCREW_LOGGERNET_DATA/archive_data/", "",
    sub(
      "/GCREW_LOGGERNET_DATA/current_data/",
      "", path_display
    )
  )

  httr::POST(
    url = url,
    httr::config(token = get_dropbox_token()),
    httr::add_headers("Dropbox-API-Arg" = jsonlite::toJSON(
      list(
        path = path_display
      ),
      auto_unbox = TRUE
    )),
    httr::write_disk(here::here(output_dir, name), overwrite = T)
  )
}
