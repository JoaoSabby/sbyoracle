#' Execute diagnostic queries
#'
#' Execute a diagnostic query using the supplied DBI connection and capture errors.
#'
#' @param sql_query A character scalar containing the complete SQL statement.
#' @param conn An open DBI connection to Oracle Database 19c or later, typically created by ROracle.
#' @return A list with ok, data, and error fields.
#' @keywords internal
sby_oracle_report_execute <- function(sql_query, conn) {
  # Preserve section-level failures without terminating subsequent diagnostics.
  tryCatch(list(ok = TRUE, data = DBI::dbGetQuery(conn, sql_query), error = NULL),
    error = function(error_condition) list(ok = FALSE, data = NULL, error = conditionMessage(error_condition)))
}
