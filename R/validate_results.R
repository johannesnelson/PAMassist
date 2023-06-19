

#' Verify detection results
#'  This function expects certain columns to exist and was made to work with
#'  data.frames generated from BirdNET detections. The columns required are:
#'  'filepath': a character string defining the filepath to the original wav file
#'  'start': numeric, defining the start time of the detection window
#'  'end': numeric, defining the end time of the detection window
#'  'confidence': numeric, defining the confidence level
#'  Optionally, you can have 'common_name' defining species
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
validate_results <- function (data, species = "all", time_buffer = 0, conf = 0, temp.length = 'none', template.mode = FALSE) {

  data.table::setDT(data)
  if(!species == "all") {
    data <- data[common_name == species,]

  }
  data <- data[confidence >= conf,]

  verifs <- c()
  verif.options <- c("y", "n", "r", "q", "s")
  all.options <- c("y", "n", "r", "q", "p", "s", "w", "a", "t", "b")

  if (template.mode == TRUE) {
    template_DT <- data.table()
  }
  if(!"verification" %in% names(data)){
    data[,verification := NA]
  }

  if(!"notes" %in% names(data)){
    data[,notes := NA]
  }

  if(!"confidence" %in% names(data)){
    data[,confidence := 0]
  }


  i <- 1
  while (i <= nrow(data)) {
    if(!is.na(data$verification[i])){
      cat(paste("\n Verification for", basename(data$filepath[i]), "at", data$start[i], "seconds already exists. Moving onto next detection...\n"))
      data$verification[i] <- data$verification[i]
      i <- i + 1
      next}


    repeat{

      wave.obj <- tuneR::readWave(data$filepath[i], from = data$start[i], to = data$end[i], units = 'seconds')

      monitoR::viewSpec(data$filepath[i], start.time = data$start[i]-time_buffer, page.length = 3, units = 'seconds'  )
      cat(paste("\n Showing detection", i, "out of", nrow(data), "from", basename(data$filepath[i]), "at", data$start[i], "seconds. Confidence:", data$confidence[i], "\n"))

      cat(paste( "Enter \n 'y' for yes,\n",
                 "'n' for no,\n",
                 "'r' for review,\n",
                 "'p' to play audio segment,\n",
                 "'w' to write segment as wav file to working directory,\n",
                 "'s' to skip to next segment (and log as NA)",
                 "'t' to create a template out of segment",
                 "'a' to add a note \n",
                 "'q' for quit."))

      answer <- readline( prompt = paste0(paste("Is this a(n)", data$common_name[i]), "?"))


      if(answer %in% verif.options) break


      if(answer == "p") {
        tempwave <- tuneR::readWave(data$filepath[i], from = data$start[i] - time_buffer, to = data$end[i]+time_buffer, units = "seconds")
        play(tempwave)
      }

      if(answer == "w") {
        filename <- paste0(paste(gsub(pattern = ".WAV", "", basename(data$filepath[i])), data$start[i], sep = "_"), ".WAV")
        tempwave <- tuneR::readWave(data$filepath[i], from = data$start[i]-time_buffer, to = data$end[i] +time_buffer, units = "seconds")
        tuneR::writeWave(tempwave, filename)
        cat("\n Writing wav file to working directory...")
      }


      if(answer == "a") {

        note <- readline(prompt = "Add note here: ")
        data$notes[i] <- note
      }

      if (answer == "b") {
        if (i > 1) {
          i <- i - 1
        } else {
          cat("\n Already at the first detection, cannot go back further.\n")
        }
        next
      }



      if(answer == "t") {
        if(template.mode == FALSE) {
          template.mode <- TRUE
          template_DT <- data.table()
        }
        repeat {
          wave.obj.2 <- tuneR::readWave(data$filepath[i], from = data$start[i] - 1, to = data$end[i] + 1, units = 'seconds')
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
            t.value <- as.numeric(readline("How many seconds long would you like the templates to be?"))
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


      if(!answer %in% all.options){
        cat("\n Response not recognized, please input correct response...\n")
      }

    }


    if(answer %in% c("y", "n", "r")) {
      cat("\n Adding result to verification data...\n ")
      data$verification[i] <- answer
    }

    if(answer == "s") {
      data$verification[i] <- NA
      cat("Skipping to next detection...")
    }


    if(answer == "q") {

      data$verification[i:nrow(data)] <- data$verification[i:nrow(data)]

      break}
    i <- i+1
  }
  saveask <- readline(prompt = "Would you like to save results as a csv file? \n Input 'y' for yes:")
  if(saveask == "y") {
    fname <- readline(prompt = "What would you like to name the file?")

    write.csv(data, paste0(fname, ".csv"), row.names = FALSE)
  }
  if (template.mode == TRUE){
    saveask2 <- readline(prompt = "Would you like to save the template data to the environment? \n Input 'y' for yes:")
    if(saveask2 == 'y'){
      template_DT <<-template_DT
    }
  }
  return(data)

}


