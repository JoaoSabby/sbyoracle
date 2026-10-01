#' Collect the adaptive plan
#'
#' Retrieve adaptive plan output, including runtime statistics and hint usage information.
#'
#' @param sql_id The Oracle SQL identifier of the selected cursor.
#' @param child_number The numeric child cursor identifier.
#' @param report_env An environment containing the accumulated sections vector.
#' @param conn An open DBI connection to Oracle Database 19c or later, typically created by ROracle.
#' @return NULL, invisibly; report sections are appended to report_env.
#' @keywords internal
sby_oracle_report_adaptive_plan <- function(sql_id, child_number, report_env, conn){
  # Retrieve adaptive plan output, including runtime statistics and hint usage information.

  escaped_id <- sby_oracle_report_sql_value(sql_id)

  adaptive_query <- glue::glue("
    SELECT PLAN_TABLE_OUTPUT
    FROM TABLE(
      DBMS_XPLAN.DISPLAY_CURSOR(
        SQL_ID           => '{escaped_id}',
        CURSOR_CHILD_NO  => {child_number},
        FORMAT           => 'ADAPTIVE ALLSTATS LAST +HINT_REPORT'
      )
    )
  ")

  adaptive_result <- sby_oracle_report_execute(adaptive_query, conn)

  if(adaptive_result$ok && nrow(adaptive_result$data) > 0L){

    sby_oracle_report_write_section(
      "ADAPTIVE EXECUTION PLAN",
      stringr::str_c(
        adaptive_result$data$PLAN_TABLE_OUTPUT,
        collapse = "\n"
      ),
      report_env
    )
  } else {
    sby_oracle_report_write_section("ADAPTIVE EXECUTION PLAN", sby_oracle_report_result_text(adaptive_result), report_env)
  }

  invisible()
}
