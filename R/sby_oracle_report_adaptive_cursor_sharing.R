#' Collect adaptive cursor sharing data
#'
#' Retrieve selectivity ranges and execution statistics from adaptive cursor sharing views.
#'
#' @param sql_id The Oracle SQL identifier of the selected cursor.
#' @param child_number The numeric child cursor identifier.
#' @param report_env An environment containing the accumulated sections vector.
#' @param conn An open DBI connection to Oracle Database 19c or later, typically created by ROracle.
#' @return NULL, invisibly; report sections are appended to report_env.
#' @keywords internal
sby_oracle_report_adaptive_cursor_sharing <- function(sql_id, child_number, report_env, conn){
  # Retrieve selectivity ranges and execution statistics from adaptive cursor sharing views.

  escaped_id <- sby_oracle_report_sql_value(sql_id)

  selectivity_query <- glue::glue("
    SELECT *
    FROM V$SQL_CS_SELECTIVITY
    WHERE SQL_ID = '{escaped_id}'
      AND CHILD_NUMBER = {child_number}
  ")

  selectivity_result <- sby_oracle_report_execute(selectivity_query, conn)

  sby_oracle_report_write_section(
    "ADAPTIVE CURSOR SHARING - SELECTIVITY",
    sby_oracle_report_result_text(selectivity_result),
    report_env
  )

  statistics_query <- glue::glue("
    SELECT *
    FROM V$SQL_CS_STATISTICS
    WHERE SQL_ID = '{escaped_id}'
      AND CHILD_NUMBER = {child_number}
  ")

  statistics_result <- sby_oracle_report_execute(statistics_query, conn)

  sby_oracle_report_write_section(
    "ADAPTIVE CURSOR SHARING - STATISTICS",
    sby_oracle_report_result_text(statistics_result),
    report_env
  )

  invisible()
}
