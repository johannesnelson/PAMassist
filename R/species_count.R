


#' This function creates summary statistics of detection dataframes. It will show
#' species count, the maximum and minimum confidence detection per species, the mean
#' and median confidence scores per species, the standard deviation of confidence
#' scores, as well as a 'high confidence mean' value which is simply the average
#' confidence score for the n highest confidence detection, where n is defined by
#' the num.obs argument.

#'
#'  @param data a dataframe of detections with columns for common_name and confidence.
#'  @param num.obs The number of observations to consider when calculating 'high
#'  still finnicky and is only useful if labeling data for model creation.
#'  @return spec.table, which is a table with species, counts, and summary
#'  statistics for confidence values
#'  @export




species_count <- function(data, num.obs = 20){
  setDT(data)
  setorder(data, common_name, -confidence)
  specvec <- unique(data[,common_name])
  high.conf.mean <- c()
  for (i in 1:length(specvec)) {
    value <- mean(data[common_name == specvec[i]][1:num.obs,confidence])
    high.conf.mean[i]<- value
  }

  spec.conf.table <- data.table(common_name = specvec, high.conf.mean = high.conf.mean)

  spec.table <- data %>%
    group_by(common_name) %>%
    summarise(count = n(),
              max.conf = max(confidence),
              min.conf = min(confidence),
              mean.conf = mean(confidence),
              median.conf = median(confidence),
              sd.conf = sd(confidence)
    )
  setDT(spec.table)
  spec.table <- full_join(spec.table, spec.conf.table )


  # spec.table <- full_join(spec.table, specDT, by = common_name)
  return(spec.table)

}
