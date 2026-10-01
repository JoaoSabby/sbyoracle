#' Collect the optimizer environment
#'
#' Retrieve optimizer parameter values associated with the selected child cursor.
#'
#' @param sql_id The Oracle SQL identifier of the selected cursor.
#' @param child_number The numeric child cursor identifier.
#' @param report_env An environment containing the accumulated sections vector.
#' @param conn An open DBI connection to Oracle Database 19c or later, typically created by ROracle.
#' @return NULL, invisibly; report sections are appended to report_env.
#' @keywords internal
sby_oracle_report_optimizer_env <- function(sql_id, child_number, report_env, conn){
  # Retrieve optimizer parameter values associated with the selected child cursor.

  escaped_id <- sby_oracle_report_sql_value(sql_id)

  optimizer_query <- glue::glue("
    SELECT
      ID,
      NAME,
      VALUE,
      ISDEFAULT
    FROM V$SQL_OPTIMIZER_ENV
    WHERE SQL_ID = '{escaped_id}'
      AND CHILD_NUMBER = {child_number}
    ORDER BY
      ISDEFAULT,
      NAME
  ")

  optimizer_result <- sby_oracle_report_execute(optimizer_query, conn)

  sby_oracle_report_write_section(
    "OPTIMIZER ENVIRONMENT",
    sby_oracle_report_result_text(optimizer_result),
    report_env
  )

  invisible()
}
