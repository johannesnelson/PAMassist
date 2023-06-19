
#' This function will plot spectrorams in a grid for quick review.
#'
#'
#'  @param x a dataframe of detections with columns for common_name and confidence.
#'  @param n_specs Number of spectrograms you'd like to plot. Defaults to 5.
#'  @return No return
#'  @importFrom monitoR viewSpec
#'  @export


plot_specs <- function(x, n_specs = 6){
  if (n_specs > nrow(x)) {n_specs <- nrow(x)}
  n_rows <- ceiling(n_specs/5)
  n_cols <- min(n_specs, 5)
  par(mfrow = c(n_rows, n_cols))
  for (i in 1:n_specs){
    if(i <= nrow(x)){
      monitoR::viewSpec(clip = x$filepath[i],
               start.time = x$start[i],
               page.length = 3,
               units = "seconds",
               main = paste(x$common_name[i], basename(x$filepath[i]), sep = "_"))
    } else {
      plot.new()
    }
  }
}

