#' Extract and play a wave segment from an audio file based on detection data
#'
#' This function reads an audio file and extracts a segment of the audio based on the provided detection data.
#' The extracted segment can be played, and a spectrogram is displayed.
#'
#' @param data A data frame containing detection information with columns 'filepath', 'start', and 'end'.
#' @param det_num An integer representing the index of the detection in the data frame.
#' @param time.buffer A numeric value specifying the time buffer (in seconds) to add before and after the detected segment (default: 0).
#' @param start_buffer A numeric value specifying the additional time buffer (in seconds) to add before the detected segment (default: 0).
#' @param end_buffer A numeric value specifying the additional time buffer (in seconds) to add after the detected segment (default: 0).
#' @param listen A logical value indicating whether to play the extracted audio segment (default: TRUE).
#'
#' @return A 'Wave' object representing the extracted audio segment, including the specified time buffers.
#' @export
#'
#' @examples
#' \dontrun{
#'   # Assuming 'detection_data' is a data frame with the required columns
#'   extracted_wave <- pullWave(data = detection_data, det_num = 1)
#' }
pullWave <- function(data, det_num, time.buffer = 0, start_buffer = 0, end_buffer = 0, listen = TRUE) {

  tempwave <- tuneR::readWave(filename = data$filepath[det_num],
                       from = data$start[det_num] - (time.buffer + start_buffer),
                       to = data$end[det_num] + (time.buffer + end_buffer),
                       units = 'seconds')

  monitoR::viewSpec(clip = data$filepath[det_num],
           start.time = data$start[det_num] - (time.buffer + start_buffer),
           page.length = ((data$end[det_num] + (time.buffer + end_buffer) - (data$start[det_num] - (time.buffer + start_buffer)))),
           units = 'seconds')
  cat("Birdnet confidence is", data$confidence[det_num])
  if (listen == TRUE){
    play(tempwave)}

  return(tempwave)
}
