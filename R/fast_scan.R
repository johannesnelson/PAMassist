


#' Fast-scan through detection results
#'  This function expects certain columns to exist and was made to work with
#'  data.frames generated from BirdNET detections. The columns required are:
#'  'filepath': a character string defining the filepath to the original wav file
#'  'start': numeric, defining the start time of the detection window
#'  'end': numeric, defining the end time of the detection window
#'  'confidence': numeric, defining the confidence level
#'  'common_name': defining species
#'
#'  The function allows you to go scan quickly through detection results, plotting
#'  multiple spectrograms at once with their common names and confidence levels.
#'  The user input can either b 'c' to continue to next page, or a number corresponding
#'  to the index value of the spectrogram you would like to hear.
#'
#' @name verify_presence
#' @param data a dataframe of detection results.
#' @param species A character string defining the species (as listed in BirdNET).
#' @param conf Numeric, defining the lower threshold for detection confidence.
#' @return a new dataframe with all species in one column and a 1 or 0 if presence
#' was either confirmed or denied
#'@import dplyr
#'@importFrom tuneR readWave writeWave play
#'@importFrom monitoR viewSpec
#'
#' @export fast_scan


fast_scan <- function(x, n_specs = 12) {
  for (i in seq(1, nrow(x), by = n_specs)) {
    original_index = i:min(i+n_specs-1, nrow(x))

    n_rows <- ceiling(length(original_index)/5)
    n_cols <- min(length(original_index), 5)

    par(mfrow = c(n_rows, n_cols))

    for (j in seq_along(original_index)){
      if (j <= nrow(x[original_index,])){
        monitoR::viewSpec(clip = x$filepath[original_index[j]],
                 start.time = x$start[original_index[j]],
                 page.length = 3,
                 units = "seconds",
                 main = paste(original_index[j],x$common_name[original_index[j]] ,x$confidence[original_index[j]], sep = " "))
      } else {
        plot.new()
      }
    }
    replay = TRUE
    while(replay) {
      answer <- readline(prompt = "Enter a number to replay sound or C to continue: ")
      if (tolower(answer) == 'c') {
        replay = FALSE
      } else {
        answer <- as.numeric(answer)
        wave <- tuneR::readWave(x$filepath[answer], from = x$start[answer], to = x$end[answer], units = 'seconds')
        tuneR::play(wave)
      }
    }
  }
}

