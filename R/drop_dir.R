# From: https://rdrr.io/cran/rdrop2/src/R/drop_download.R
# (removed from CRAN)

#' List folder contents and associated metadata.
#'
#' Can be used to either see all items in a folder, or only items that have changed since a previous request was made.
#'
#' @param path path to folder in Dropbox to list contents of. Defaults to the root directory.
#' @param recursive If TRUE, the list folder operation will be applied recursively to all subfolders and the response will contain contents of all subfolders. Defaults to FALSE.
#' @param include_media_info If TRUE, FileMetadata.media_info is set for photo and video. Defaults to FALSE.
#' @param include_deleted If TRUE, the results will include entries for files and folders that used to exist but were deleted. Defaults to FALSE.
#' @param include_has_explicit_shared_members If TRUE, the results will include a flag for each file indicating whether or not that file has any explicit members. Defaults to FALSE.
#' @param include_mounted_folders If TRUE, the results will include entries under mounted folders which includes app folder, shared folder and team folder. Defaults to TRUE.
#' @param limit The maximum number of results to return per request. Note: This is an approximate number and there can be slightly more entries returned in some cases. Defaults to NULL, no limit.
#' @param cursor string or boolean: \itemize{
#'   \item{If FALSE, return metadata of items in \code{path}}
#'   \item{If TRUE, return a cursor to be used for detecting changed later}
#'   \item{If a string, return metadata of changed items since the cursor was fetched}
#' }
#' @template token
#'
#' @return Either a \code{tbl_df} of items in folder, one row per file or folder, with metadata values as columns, or a character string giving a cursor to be used later for change detection (see \code{cursor}).
#'
#' @examples \dontrun{
#'
#'   # list files in root directory
#'   drop_dir()
#'
#'   # get a cursor from root directory,
#'   # upload a new file,
#'   # return only information about new file
#'   cursor <- drop_dir(cursor = TRUE)
#'   drop_upload("some_new_file")
#'   drop_dir(cursor = cursor)
#' }
#'
#' @export
drop_dir <- function(
    path = "",
    recursive = FALSE,
    include_media_info = FALSE,
    include_deleted = FALSE,
    include_has_explicit_shared_members = FALSE,
    include_mounted_folders = TRUE,
    limit = NULL,
    cursor = FALSE,
    dtoken = get_dropbox_token()
) {
  
  # this API doesn't accept "/", so don't add slashes to empty path, remove if given
  if (path != "") path <- add_slashes(path)
  if (path == "/") path <- ""
  
  # force limit to integer
  if (!is.null(limit)) limit <- as.integer(limit)
  
  # behavior depends on cursor
  if (is.character(cursor)) {
    
    # list changes since cursor
    content <- drop_list_folder_continue(cursor, dtoken)
    
  } else if (cursor) {
    
    # get a cursor to track changes against
    content <- drop_list_folder_get_latest_cursor(
      path,
      recursive,
      include_media_info,
      include_deleted,
      include_has_explicit_shared_members,
      include_mounted_folders,
      limit,
      dtoken
    )
    return(content$cursor)
    
  } else {
    
    # list files normally
    content <- drop_list_folder(
      path,
      recursive,
      include_media_info,
      include_deleted,
      include_has_explicit_shared_members,
      include_mounted_folders,
      limit,
      dtoken
    )
    
  }
  
  # extract list of content metadata
  results <- content$entries
  
  # if no limit was given, make additional requests until all content retrieved
  if (is.null(limit)) {
    while (content$has_more) {
      
      # update content, append results
      content <- drop_list_folder_continue(content$cursor)
      results  <- append(results, content$entries)
    }
  }
  
  # coerce to tibble, one row per item found
  dplyr::bind_rows(purrr::map(results, LinearizeNestedList))
}


#' List contents of a Dropbox folder.
#'
#' For internal use; drop_dir should generally be used to list files in a folder.
#'
#' @return a list with three elements: \code{entries}, \code{cursor}, and \code{has_more}.
#'
#' @references \href{https://www.dropbox.com/developers/documentation/http/documentation#files-list_folder}{API reference}
#'
#' @noRd
#'
#' @keywords internal
drop_list_folder <- function(
    path,
    recursive = FALSE,
    include_media_info = FALSE,
    include_deleted = FALSE,
    include_has_explicit_shared_members = FALSE,
    include_mounted_folders = TRUE,
    limit = NULL,
    dtoken = get_dropbox_token()
) {
  
  url <- "https://api.dropboxapi.com/2/files/list_folder"
  
  req <- httr::POST(
    url = url,
    httr::config(token = dtoken),
    body = drop_compact(list(
      path = path,
      recursive = recursive,
      include_media_info = include_media_info,
      include_deleted = include_deleted,
      include_has_explicit_shared_members = include_has_explicit_shared_members,
      include_mounted_folders = include_mounted_folders,
      limit = limit
    )),
    encode = "json"
  )
  
  httr::stop_for_status(req)
  
  httr::content(req)
}


#' Fetch additional results from a cursor
#'
#' @return see \code{drop_list_folder}
#'
#' @references \href{https://www.dropbox.com/developers/documentation/http/documentation#files-list_folder-continue}{Dropbox API}
#'
#' @noRd
#'
#' @keywords internal
drop_list_folder_continue <- function(cursor, dtoken = get_dropbox_token()) {
  
  url <- "https://api.dropboxapi.com/2/files/list_folder/continue"
  
  req <- httr::POST(
    url = url,
    httr::config(token = dtoken),
    body = list(cursor = cursor),
    encode = "json"
  )
  
  httr::stop_for_status(req)
  
  httr::content(req)
}


#' Get the current cursor for a set of path + options
#'
#' @return a cursor, a string uniquely identifying a folder and how much of it has been listed
#'
#' @references \href{https://www.dropbox.com/developers/documentation/http/documentation#files-list_folder-get_latest_cursor}{Dropbox API}
#'
#' @noRd
#'
#' @keywords internal
drop_list_folder_get_latest_cursor <- function(
    path,
    recursive = FALSE,
    include_media_info = FALSE,
    include_deleted = FALSE,
    include_has_explicit_shared_members = FALSE,
    include_mounted_folders = TRUE,
    limit = NULL,
    dtoken = get_dropbox_token()
) {
  
  url <- "https://api.dropboxapi.com/2/files/list_folder/get_latest_cursor"
  
  req <- httr::POST(
    url = url,
    httr::config(token = dtoken),
    body = drop_compact(list(
      path = path,
      recursive = recursive,
      include_media_info = include_media_info,
      include_deleted = include_deleted,
      include_has_explicit_shared_members = include_has_explicit_shared_members,
      include_mounted_folders = include_mounted_folders,
      limit = limit
    )),
    encode = "json"
  )
  
  httr::stop_for_status(req)
  
  httr::content(req)
}

add_slashes <- function(path) {
  if (length(path) && !grepl("^/", path)) {
    path <- paste0("/", path)
  }
  path
}

#' A local version of list compact from plyr.
#' @noRd
drop_compact <- function(l) Filter(Negate(is.null), l)

# This is an internal function to linearize lists
# Source: https://gist.github.com/mrdwab/4205477
# Author page (currently unreachable):  https://sites.google.com/site/akhilsbehl/geekspace/articles/r/linearize_nested_lists_in
# Original Author: Akhil S Bhel
# Notes: Current author could not be reached and original site () appears defunct. Copyright remains with original author
LinearizeNestedList <- function(NList, LinearizeDataFrames=FALSE,
                                NameSep="/", ForceNames=FALSE) {
  # LinearizeNestedList:
  #
  # https://sites.google.com/site/akhilsbehl/geekspace/
  #         articles/r/linearize_nested_lists_in_r
  #
  # Akhil S Bhel
  #
  # Implements a recursive algorithm to linearize nested lists upto any
  # arbitrary level of nesting (limited by R's allowance for recursion-depth).
  # By linearization, it is meant to bring all list branches emanating from
  # any nth-nested trunk upto the top-level trunk s.t. the return value is a
  # simple non-nested list having all branches emanating from this top-level
  # branch.
  #
  # Since dataframes are essentially lists a boolean option is provided to
  # switch on/off the linearization of dataframes. This has been found
  # desirable in the author's experience.
  #
  # Also, one'd typically want to preserve names in the lists in a way as to
  # clearly denote the association of any list element to it's nth-level
  # history. As such we provide a clean and simple method of preserving names
  # information of list elements. The names at any level of nesting are
  # appended to the names of all preceding trunks using the `NameSep` option
  # string as the seperator. The default `/` has been chosen to mimic the unix
  # tradition of filesystem hierarchies. The default behavior works with
  # existing names at any n-th level trunk, if found; otherwise, coerces simple
  # numeric names corresponding to the position of a list element on the
  # nth-trunk. Note, however, that this naming pattern does not ensure unique
  # names for all elements in the resulting list. If the nested lists had
  # non-unique names in a trunk the same would be reflected in the final list.
  # Also, note that the function does not at all handle cases where `some`
  # names are missing and some are not.
  #
  # Clearly, preserving the n-level hierarchy of branches in the element names
  # may lead to names that are too long. Often, only the depth of a list
  # element may only be important. To deal with this possibility a boolean
  # option called `ForceNames` has been provided. ForceNames shall drop all
  # original names in the lists and coerce simple numeric names which simply
  # indicate the position of an element at the nth-level trunk as well as all
  # preceding trunk numbers.
  #
  # Returns:
  # LinearList: Named list.
  #
  # Sanity checks:
  #
  stopifnot(is.character(NameSep), length(NameSep) == 1)
  stopifnot(is.logical(LinearizeDataFrames), length(LinearizeDataFrames) == 1)
  stopifnot(is.logical(ForceNames), length(ForceNames) == 1)
  if (! is.list(NList)) return(NList)
  #
  # If no names on the top-level list coerce names. Recursion shall handle
  # naming at all levels.
  #
  if (is.null(names(NList)) | ForceNames == TRUE)
    names(NList) <- as.character(1:length(NList))
  #
  # If simply a dataframe deal promptly.
  #
  if (is.data.frame(NList) & LinearizeDataFrames == FALSE)
    return(NList)
  if (is.data.frame(NList) & LinearizeDataFrames == TRUE)
    return(as.list(NList))
  #
  # Book-keeping code to employ a while loop.
  #
  A <- 1
  B <- length(NList)
  #
  # We use a while loop to deal with the fact that the length of the nested
  # list grows dynamically in the process of linearization.
  #
  while (A <= B) {
    Element <- NList[[A]]
    EName <- names(NList)[A]
    if (is.list(Element)) {
      #
      # Before and After to keep track of the status of the top-level trunk
      # below and above the current element.
      #
      if (A == 1) {
        Before <- NULL
      } else {
        Before <- NList[1:(A - 1)]
      }
      if (A == B) {
        After <- NULL
      } else {
        After <- NList[(A + 1):B]
      }
      #
      # Treat dataframes specially.
      #
      if (is.data.frame(Element)) {
        if (LinearizeDataFrames == TRUE) {
          #
          # `Jump` takes care of how much the list shall grow in this step.
          #
          Jump <- length(Element)
          NList[[A]] <- NULL
          #
          # Generate or coerce names as need be.
          #
          if (is.null(names(Element)) | ForceNames == TRUE)
            names(Element) <- as.character(1:length(Element))
          #
          # Just throw back as list since dataframes have no nesting.
          #
          Element <- as.list(Element)
          #
          # Update names
          #
          names(Element) <- paste(EName, names(Element), sep=NameSep)
          #
          # Plug the branch back into the top-level trunk.
          #
          NList <- c(Before, Element, After)
        }
        Jump <- 1
      } else {
        NList[[A]] <- NULL
        #
        # Go recursive! :)
        #
        if (is.null(names(Element)) | ForceNames == TRUE)
          names(Element) <- as.character(1:length(Element))
        Element <- LinearizeNestedList(Element, LinearizeDataFrames,
                                       NameSep, ForceNames)
        names(Element) <- paste(EName, names(Element), sep=NameSep)
        Jump <- length(Element)
        NList <- c(Before, Element, After)
      }
    } else {
      Jump <- 1
    }
    #
    # Update book-keeping variables.
    #
    A <- A + Jump
    B <- length(NList)
  }
  return(NList)
}