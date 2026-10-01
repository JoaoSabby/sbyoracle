#' Escape SQL text literals
#'
#' Duplicate single quotation marks in SQL character literals.
#'
#' @param sql_value A character value to escape for use in a SQL literal.
#' @return A character scalar containing the formatted value or marker.
#' @keywords internal
sby_oracle_report_sql_value <- function(sql_value){
  # Duplicate single quotation marks in SQL character literals.

  gsub("'", "''", sql_value, fixed = TRUE)
}
