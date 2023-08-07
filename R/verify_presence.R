
#' Verify presence
#'  This function expects certain columns to exist and was made to work with
#'  data.frames generated from BirdNET detections. The columns required are:
#'  'filepath': a character string defining the filepath to the original wav file
#'  'start': numeric, defining the start time of the detection window
#'  'end': numeric, defining the end time of the detection window
#'  'confidence': numeric, defining the confidence level
#'  common_name': defining species
#'
#'  The function allows you to go through your data and verify the presence of
#'  each species. Once a 'y' is marked for one species, it moves onto the next
#'  species. This can be very helpful if wanting a simple species richness
#'  estimate with a certain dataset.
#'
#' @name verify_presence
#' @param data a dataframe of detection results.
#' @param species A character string defining the species (as listed in BirdNET).
#' @param conf Numeric, defining the lower threshold for detection confidence.
#' @return a new dataframe with all species in one column and a 1 or 0 if presence
#' was either confirmed or denied
#'@import data.table
#'@import dplyr
#'@importFrom tuneR readWave writeWave play
#'@importFrom seewave spectro
#'@importFrom monitoR viewSpec
#'

#' @export verify_presence


verify_presence <- function (data, species = 'all', conf = 0) {

  data.table::setDT(data)

  if(!species == 'all'){
    data <- data[common_name %in% species,]
  }


  data <- data[confidence >= conf,]

  verifs <- c()
  verif.options <- c("y", "n", "r", "q", "s")
  all.options <- c("y", "n", "r", "q", "p", "s", "w", "a", "t")


  if(!"verification" %in% names(data)){   #Adds verification column
    data[,verification := NA]
  }

  if(!"notes" %in% names(data)){         #Adds notes column
    data[,notes := NA]
  }

  if(!"confidence" %in% names(data)){         #Adds confidence column with 0s. Only really relevant if using non-birdNET detections (e.g. monitoR, or a specific ML model)
    data[,confidence := 0]
  }

  species_list <- unique(data[,common_name])
  species_presence <- data.table::data.table(common_name = species_list, presence = NA)
  # Skip over observations where verification is already defined
  for (x in 1:length(species_list)){
    species_name <- species_list[x]
    species_x <- data[common_name == species_name][order(-confidence)]

    for (i in 1:nrow(species_x)) {

      repeat{

        wave.obj <- tuneR::readWave(species_x$filepath[i], from = species_x$start[i] -1, to = species_x$end[i] + 1, units = 'seconds')
        #spectro( wave = wave.obj )
        monitoR::viewSpec(wave.obj)
        cat(paste("\n Showing detection", i, "out of", nrow(species_x), "from", basename(species_x[i, filepath]), "at", species_x[i, start], "seconds. Confidence:", species_x$confidence[i], "\n"))

        cat(paste( "Enter \n 'y' for yes,\n",
                   "'n' for no,\n",
                   "'p' to play audio segment,\n",
                   "'w' to write segment as wav file to working directory,\n",
                   "'s' to skip to next species (and log as 0 for not present)",
                   "'a' to add a note \n",
                   "'q' for quit."))

        answer <- readline( prompt = paste0(paste("Is this a(n)", species_x$common_name[i]), "?"))


        if(answer %in% verif.options) break

        # Option to play sound
        if(answer == "p") {
          tempwave <- tuneR::readWave(species_x$filepath[i], from = species_x$start[i] - 1, to = species_x$end[i] + 1, units = "seconds")
          play(tempwave)
        }
        # Option to write sound to wav file in working directory
        if(answer == "w") {
          filename <- paste0(paste(gsub(pattern = ".WAV", "", basename(species_x$filepath[i])), species_x$start[i], sep = "_"), ".WAV")
          tempwave <- tuneR::readWave(species_x$filepath[i], from = species_x$start[i] - 1, to = species_x$end[i] + 1, units = "seconds")
          tuneR::writeWave(tempwave, filename)
          cat("\n Writing wav file to working directory...")
        }

        # Option to add a note in the notes column
        if(answer == "a") {

          note <- readline(prompt = "Add note here: ")
          species_x$notes[i] <- note
        }



        if(!answer %in% all.options){
          cat("\n Response not recognized, please input correct response...\n")
        }

      }

      # add verification character to verification column
      if(answer %in% c("n", "r")) {
        cat("\n Adding result to verification data...\n ")
        data$verification[i] <- answer
      }
      if (answer == 'y') {
        cat("\n Adding result to verification data...\n ")
        data$verification[i] <- answer
        species_presence$presence[x] <- 1
        break
      }
      # skip observation (leave as NA)
      if(answer == "s") {
        species_presence$presence[x] <- 0
        break
      }

      # quitting will lead to csv saving options
      if(answer == "q") {

        return(species_presence)

      }



    }
  }
  saveask <- readline(prompt = "Would you like to save results as a csv file? \n Input 'y' for yes:")
  if(saveask == "y") {
    fname <- readline(prompt = "What would you like to name the file?")

    write.csv(data, paste0(fname, ".csv"), row.names = FALSE)
  }

  saveask2 <- readline(prompt = "Would you like to save the template data to the environment? \n Input 'y' for yes:")
  if(saveask2 == 'y'){
    template_DT <<-template_DT
  }
  return(species_presence)

}


