

#' This will name all files in a directory (usually SD card) according to the
#' arguments of locID and eqID so that "locationID_deviceID_YYYYMMDD_HHMMSS.WAV"
#' becomes the naming convention. This will help a great deal with organization
#' and later analysis, since each filename is encoded with a lot of crucial
#' information. The original files are not deleted so that you can verify successful
#' copying before wiping sd card clean.

#' @param directory Character string indicating the directory where the files are
#' @param new_directory Character string indicating the new directory where renamed
#' files should be copied. This should be created ahead of time manually.
#' @param locID Character string indicating the location or site ID where recordings
#' were collected from.
#' @param eqID Character string indicating the equipment ID
#' @return Nothing
#' @export

nameFiles <- function(directory, new_directory, locID, eqID) {

  file.vector <- list.files(directory)
  current.dir <- getwd()
  setwd(directory)
  for (oldname in file.vector) {
    file.rename(from = oldname, to = paste(locID, eqID, basename(oldname), sep = '_'))
  }
  new.file.vector <- list.files()
  file.copy(new.file.vector, new_directory)
  setwd(current.dir)
}
