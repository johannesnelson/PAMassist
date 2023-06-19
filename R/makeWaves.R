#' Download audio files corresponding to detection timestamps
#'
#' This function downloads audio files to a directory that correspond to detection
#' timestamps in a detection dataframe. This is useful for downloading subsets for
#' verification or sharing.
#'
#'
#' @param x A dataframe of detections with filepath, start, and end columns.
#' @param dir The directory to download audio files to.
#' @param time_buffer Defines how many seconds around each detection window to
#' include in downloaded files.
#' @param sampling_rate Defines the desired sampling rate for files. Defaults to 48000.
#' @export
#' @name makeWaves
makeWaves <- function(x, dir, time_buffer = 0, sampling_rate = 48000) {
  dir.create(dir, recursive = TRUE)
  dir.fp <- dir
  for (i in 1:nrow(x)){
    wave <- tuneR::readWave(x$filepath[i], from = x$start[i]-time_buffer, to = x$end[i]+time_buffer, units = 'seconds')
    if(!wave@samp.rate == sampling_rate){wave <- tuneR::downsample(wave, sampling_rate)}
    tuneR::writeWave(wave, filename = paste(dir.fp, paste(i, basename(x$filepath[i]), x$start[i], ".wav",  sep = '_'), sep = "/"))
  }
}
