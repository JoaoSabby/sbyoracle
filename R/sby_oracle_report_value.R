#' Format database values
#'
#' Convert database values to a scalar textual representation.
#'
#' @param input_value An R object returned by the database driver.
#' @return A character scalar containing the formatted value or marker.
#' @keywords internal
sby_oracle_report_value <- function(input_value) {
  # Collapse temporal and binary vectors to a scalar report value.
  if (is.null(input_value) || length(input_value) == 0L || all(is.na(input_value))) return("")
  if (inherits(input_value, "POSIXt")) return(paste(format(input_value, "%Y-%m-%d %H:%M:%OS6"), collapse = ", "))
  if (is.raw(input_value)) return(paste(as.character(input_value), collapse = ""))
  paste(as.character(input_value), collapse = ", ")
}
