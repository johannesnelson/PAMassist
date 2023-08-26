

#' Verify detection results
#'
#'
#' This function expects certain columns to exist and was made to work with
#' data.frames generated from BirdNET detections. The columns required are:
#' 'filepath': a character string defining the filepath to the original wav file
#' 'start': numeric, defining the start time of the detection window
#' 'end': numeric, defining the end time of the detection window
#' 'confidence': numeric, defining the confidence level
#' Optionally, you can have 'common_name' defining species
#' @name validate_results
#' @param filepath A character string defining the filepath to the orginial audio file.
#' @param species A character string defining the species (as listed in BirdNET).
#' @param time_buffer Numeric, defines how much time around each detection window
#'        you would like to visualize spectrograms.
#' @param conf Numeric, defining the lower threshold for detection confidence.
#' @param temp.length Numeric, defining the number of seconds each template should be
#'        if using template mode.
#' @param template.mode Boolean, if set to TRUE, template mode is on. This is
#'        still finnicky and is only useful if labeling data for model creation.
#' @return Originial data.table with added columns 'verification' and 'notes'
#'         with annotations from executing the function.
#'@import data.table
#'@import dplyr
#'@importFrom tuneR readWave writeWave play
#'@importFrom seewave spectro
#'@importFrom monitoR viewSpec
#'

#' @export validate_results
validate_results <- function (data, species = "all",
                              time_buffer = 0,
                              conf = 0,
                              temp.length = 'none',
                              template.mode = FALSE) {
  # Convert the data to a data table format
  data.table::setDT(data)

  # Filter by species if not set to 'all'
  if(!species == "all") {
    data <- data[common_name == species,]
  }

  # Define the possible options for user input
  verifs <- c()
  verif.options <- c("y", "n", "r", "q", "s")
  all.options <- c("y", "n", "r", "q", "p", "s", "w", "a", "t", "b")

  # Initialize template data table if template mode is enabled
  if (template.mode == TRUE) {
    template_DT <- data.table()
  }

  # Ensure columns 'verification', 'notes', and 'confidence' exist in data; if not, create them
  if(!"verification" %in% names(data)){
    data[,verification := NA]
  }
  if(!"notes" %in% names(data)){
    data[,notes := NA]
  }
  if(!"confidence" %in% names(data)){
    data[,confidence := 0]
  }

  # Filter data by confidence threshold
  data <- data[confidence >= conf,]

  i <- 1

  # Begin looping through each detection in the data
  while (i <= nrow(data)) {
    # Skip already verified entries
    if(!is.na(data$verification[i])){
      cat(paste("\n Verification for", basename(data$filepath[i]), "at", data$start[i],
                "seconds already exists. Moving onto next detection...\n"))

      data$verification[i] <- data$verification[i]
      i <- i + 1
      next}


    repeat{

      # Read in a wave object corresponding to the current detection
      wave.obj <- tuneR::readWave(data$filepath[i],
                                  from = data$start[i],
                                  to = data$end[i],
                                  units = 'seconds')

      # Display a spectrogram of the current detection
      monitoR::viewSpec(data$filepath[i],
                        start.time = data$start[i]-time_buffer,
                        page.length = 3,
                        units = 'seconds',
                        main = paste(data$common_name[i],
                                     "\n Confidence:",
                                     data$confidence[i],
                                     "\n Filename:",
                                     basename(data$filepath[i]),
                                     sep = " ") )

      # Display instructions and options for user
      cat(paste("\n Showing detection", i, "out of", nrow(data), "from",
                basename(data$filepath[i]), "at", data$start[i],
                "seconds. Confidence:", data$confidence[i], "\n"))

      cat(paste( "Enter \n 'y' for yes,\n",
                 "'n' for no,\n",
                 "'r' for review,\n",
                 "'p' to play audio segment,\n",
                 "'w' to write segment as wav file to working directory,\n",
                 "'s' to skip to next segment (and log as NA)",
                 "'t' to create a template out of segment",
                 "'a' to add a note \n",
                 "'q' for quit."))

      # Collect user input
      answer <- readline( prompt = paste0(paste("Is this a(n)", data$common_name[i]), "?"))

      # If the answer is one of the basic verification options, exit the loop
      if(answer %in% verif.options) break

      # Play the audio if user input is 'p'
      if(answer == "p") {
        tempwave <- tuneR::readWave(data$filepath[i],
                                    from = data$start[i] - time_buffer,
                                    to = data$end[i]+time_buffer,
                                    units = "seconds")
        play(tempwave)
      }

      # Save the audio segment as a .wav file if input is 'w'
      if(answer == "w") {
        filename <- paste0(paste(gsub(pattern = ".WAV", "", basename(data$filepath[i])),
                                 data$start[i], sep = "_"), ".WAV")

        tempwave <- tuneR::readWave(data$filepath[i],
                                    from = data$start[i]-time_buffer,
                                    to = data$end[i] + time_buffer,
                                    units = "seconds")

        tuneR::writeWave(tempwave, filename)
        cat("\n Writing wav file to working directory...")
      }

      # Add a note to the detection if input is 'a'
      if(answer == "a") {

        note <- readline(prompt = "Add note here: ")
        data$notes[i] <- note
      }

      # Go back to the previous detection if input is 'b'
      if (answer == "b") {
        if (i > 1) {
          i <- i - 1
        } else {
          cat("\n Already at the first detection, cannot go back further.\n")
        }
        next
      }

      # If the input is 't', enter template creation mode.
      if(answer == "t") {
        # The rest of this block deals with making templates/annotations.
        # These annotations can be used to create training data.

        if(template.mode == FALSE) {
          template.mode <- TRUE
          template_DT <- data.table()
        }
        repeat {
          wave.obj.2 <- tuneR::readWave(data$filepath[i],
                                        from = data$start[i] - 1,
                                        to = data$end[i] + 1,
                                        units = 'seconds')

          tempSpec <- seewave::spectro(wave.obj.2, fastdisp = TRUE)
          t.bins <- tempSpec$time
          n.t.bins <- length(t.bins)
          which.t.bins <- 1:n.t.bins
          which.frq.bins <- which(tempSpec$freq >= 0)
          frq.bins <- tempSpec$freq
          amp <- round(tempSpec$amp[which.frq.bins, ], 2)
          n.frq.bins <- length(frq.bins)
          ref.matrix <- matrix(0, nrow = n.frq.bins, ncol = n.t.bins)


          if (temp.length == 'none') {
            t.value <- as.numeric(readline("How long would you like the templates to be (seconds)?"))
          }else {
            t.value <- temp.length
          }

          cat("Click the plot where you would like to center this template")
          ctr.pt <- locator(n = 1)

          temp.DT <-data.table::data.table(filepath = data[i, filepath],
                                common_name = data[i, common_name],
                                start = (data[i, start] -1) + ctr.pt$x - (t.value/2),
                                end = (data[i, start] -1) + ctr.pt$x +(t.value/2),
                                center.freq = ctr.pt$y

          )
          template_DT <-  rbind(template_DT, temp.DT)


          {break}
        }
        dev.off()
      }

      # Notify the user if their input is unrecognized
      if(!answer %in% all.options){
        cat("\n Response not recognized, please input correct response...\n")
      }

    }

    # Log verification result based on user input
    if(answer %in% c("y", "n", "r")) {
      cat("\n Adding result to verification data...\n ")
      data$verification[i] <- answer
    }

    # Skip to next detection without logging verification if input is 's'
    if(answer == "s") {
      data$verification[i] <- NA
      cat("Skipping to next detection...")
    }

    # Exit the loop if user input is 'q'
    if(answer == "q") {

      data$verification[i:nrow(data)] <- data$verification[i:nrow(data)]

      break}
    i <- i+1
  }
  # Offer to save the results as a .csv file
  saveask <- readline(prompt = "Would you like to save results as a csv file? \n Input 'y' for yes:")
  if(saveask == "y") {
    fname <- readline(prompt = "What would you like to name the file?")

    write.csv(data, paste0(fname, ".csv"), row.names = FALSE)
  }
  # If template mode was enabled, offer to save template annotations as a separate .csv file
  if (template.mode == TRUE){
    saveask2 <- readline(prompt = "Would you like to save the template data to the environment? \n Input 'y' for yes:")
    if(saveask2 == 'y'){
      template_DT <<-template_DT
    }
  }
  return(data)

}

