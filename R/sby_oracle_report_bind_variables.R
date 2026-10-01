#' Collect captured bind variables
#'
#' Retrieve sampled bind metadata and values available in V$SQL_BIND_CAPTURE.
#'
#' @param sql_id The Oracle SQL identifier of the selected cursor.
#' @param child_number The numeric child cursor identifier.
#' @param report_env An environment containing the accumulated sections vector.
#' @param conn An open DBI connection to Oracle Database 19c or later, typically created by ROracle.
#' @return NULL, invisibly; report sections are appended to report_env.
#' @keywords internal
sby_oracle_report_bind_variables <- function(sql_id, child_number, report_env, conn){
  # Retrieve sampled bind metadata and values available in V$SQL_BIND_CAPTURE.

  escaped_id <- sby_oracle_report_sql_value(sql_id)

  bind_query <- glue::glue("
    SELECT
      NAME,
      POSITION,
      DATATYPE_STRING,
      PRECISION,
      SCALE,
      MAX_LENGTH,
      WAS_CAPTURED,
      LAST_CAPTURED,
      VALUE_STRING
    FROM V$SQL_BIND_CAPTURE
    WHERE SQL_ID = '{escaped_id}'
      AND CHILD_NUMBER = {child_number}
    ORDER BY POSITION
  ")

  bind_result <- sby_oracle_report_execute(bind_query, conn)

  sby_oracle_report_write_section(
    "CAPTURED BIND VARIABLES",
    sby_oracle_report_result_text(bind_result),
    report_env
  )

  invisible()
}
