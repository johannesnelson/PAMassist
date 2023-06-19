#' The following functions use the file nameing convention established earlier
#' to add relevant information (date, time, and location) to the detection dataframe.
#' It can take some time to run depending on size of dataset.

#' @name add.date
#' @title Add date information to data.table
#' @param x The dataframe wiuth detection data, which should have filepath as a
#' column and the file names should have adopted convention defined in nameFiles
#' @export
add.date <- function(x) {

  newframe <- mutate(x, locationIDvector = strsplit(basename(x$filepath), split = '_'))

  datevector <- c()

  for (i in seq(newframe$locationIDvector)){

    datevector <- append(datevector, newframe$locationIDvector[[i]][c(3)])

    if(length(datevector) == length(newframe$locationIDvector)) {break}
  }

  newframe <-  mutate(x, date = lubridate::ymd(datevector))
  return(newframe)

}

#' @name add.time
#' @title Add time information to data.table
#' @param x The dataframe wiuth detection data, which should have filepath as a
#' column and the file names should have adopted convention defined in nameFiles
#' @export
add.time <- function(x) {

  newframe <- mutate(x, locationIDvector = strsplit(basename(x$filepath), split = '_'))

  timevector <- c()

  for (i in seq(newframe$locationIDvector)){
    timevector <- append(timevector, gsub(".WAV","", newframe$locationIDvector[[i]][c(4)]))
    if(length(timevector) == length(newframe$locationIDvector)) {break}
  }

  newframe <-  mutate(x, time = timevector)
  return(newframe)
}


#' @name add.locationID
#' @title Add location information to data.table
#' @param x The dataframe wiuth detection data, which should have filepath as a
#' column and the file names should have adopted convention defined in nameFiles
#' @export
add.locationID <- function(x) {

  newframe <- mutate(x, locationIDvector = strsplit(basename(x$filepath), split = '_'))

  locvector <- c()

  for (i in seq(newframe$locationIDvector)){
    locvector <- append(locvector, newframe$locationIDvector[[i]][1])
    if(length(locvector) == length(newframe$locationIDvector)) {break}


  }

  newframe <-  mutate(x, locationID = locvector)
  return(newframe)
}
