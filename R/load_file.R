load_file <- function(path_display,
                      output_dir,
                      current_path,
                      archive_path) {
  url <- "https://content.dropboxapi.com/2/files/download"
  name <- sub(
    current_path, "",
    sub(
      archive_path,
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
