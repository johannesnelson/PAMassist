#' Combine CSV files in a folder into a single CSV file
#'
#' This function reads all CSV files in a specified folder and combines them into a single CSV file.
#' The combined file is saved in the same folder as the input files.
#'
#' @param input_folder A string representing the path to the folder containing the CSV files to combine.
#' @param output_file A string representing the name of the output file (without the file extension).
#'
#' @return NULL, but a combined CSV file is written to the specified output location.
#' @export
#'
#' @examples
#' \dontrun{
#'   combine_csv_files("path/to/input/folder", "combined_file")
#' }
combine_csv_files <- function(input_folder, output_file) {
  # List all CSV files in the folder
  csv_files <- list.files(input_folder, pattern = "*.csv", full.names = TRUE)

  # Read each CSV file and store them in a list
  data_frames <- lapply(csv_files, function(file) readr::read_csv(file, show_col_types = FALSE))

  # Combine all the data frames into a single data frame using rbind
  combined_data_frame <- do.call(rbind, data_frames)

  output_filepath <- file.path(input_folder, paste0(output_file, ".csv"))

  # Write the combined data frame to a single CSV file
  write.csv(combined_data_frame, output_filepath, row.names = FALSE)
}
