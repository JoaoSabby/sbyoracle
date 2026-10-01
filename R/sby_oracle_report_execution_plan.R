#' Collect the execution plan
#'
#' Retrieve DBMS_XPLAN output with last-execution statistics and the hint usage report.
#'
#' @param sql_id The Oracle SQL identifier of the selected cursor.
#' @param child_number The numeric child cursor identifier.
#' @param report_env An environment containing the accumulated sections vector.
#' @param conn An open DBI connection to Oracle Database 19c or later, typically created by ROracle.
#' @return NULL, invisibly; report sections are appended to report_env.
#' @keywords internal
sby_oracle_report_execution_plan <- function(sql_id, child_number, report_env, conn){
  # Retrieve DBMS_XPLAN output with last-execution statistics and the hint usage report.

  escaped_id <- sby_oracle_report_sql_value(sql_id)

  plan_query <- glue::glue("
    SELECT PLAN_TABLE_OUTPUT
    FROM TABLE(
      DBMS_XPLAN.DISPLAY_CURSOR(
        SQL_ID           => '{escaped_id}',
        CURSOR_CHILD_NO  => {child_number},
        FORMAT           => 'ALL ALLSTATS LAST +HINT_REPORT'
      )
    )
  ")

  plan_result <- sby_oracle_report_execute(plan_query, conn)

  if(plan_result$ok && nrow(plan_result$data) > 0L){

    plan_text <- stringr::str_c(
      plan_result$data$PLAN_TABLE_OUTPUT,
      collapse = "\n"
    )

  }else{

    plan_text <- sby_oracle_report_result_text(plan_result)
  }

  sby_oracle_report_write_section(
    "COMPLETE EXECUTION PLAN",
    plan_text,
    report_env
  )

  invisible()
}
