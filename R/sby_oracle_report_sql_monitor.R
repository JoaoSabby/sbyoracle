#' Collect optional Real-Time SQL Monitoring data
#'
#' Retrieve monitoring rows and a native text report only when explicitly enabled.
#'
#' @param sql_id The Oracle SQL identifier of the selected cursor.
#' @param report_env An environment containing the accumulated sections vector.
#' @param monitor_statistics A logical scalar enabling licensed SQL Monitoring calls.
#' @param conn An open DBI connection to Oracle Database 19c or later, typically created by ROracle.
#' @return NULL, invisibly; report sections are appended to report_env.
#' @keywords internal
sby_oracle_report_sql_monitor <- function(sql_id, report_env, monitor_statistics, conn){
  # Avoid all SQL Monitoring access unless the caller explicitly enables it.

  if(isTRUE(monitor_statistics)){

    escaped_id <- sby_oracle_report_sql_value(sql_id)

    monitor_query <- glue::glue("
      SELECT *
      FROM V$SQL_MONITOR
      WHERE SQL_ID = '{escaped_id}'
      ORDER BY
        SQL_EXEC_START DESC,
        PX_SERVER# NULLS FIRST
    ")

    monitor_result <- sby_oracle_report_execute(monitor_query, conn)

    sby_oracle_report_write_section(
      "REAL-TIME SQL MONITOR",
      sby_oracle_report_result_text(monitor_result),
      report_env
    )

    monitor_report_query <- glue::glue("
      SELECT
        DBMS_SQLTUNE.REPORT_SQL_MONITOR(
          SQL_ID       => '{escaped_id}',
          REPORT_LEVEL => 'ALL',
          TYPE         => 'TEXT'
        ) AS REPORT
      FROM DUAL
    ")

    monitor_report_result <- sby_oracle_report_execute(monitor_report_query, conn)

    if(monitor_report_result$ok && nrow(monitor_report_result$data) > 0L){

      sby_oracle_report_write_section(
        "REAL-TIME SQL MONITOR - REPORT",
        sby_oracle_report_value(monitor_report_result$data$REPORT[[1L]]),
        report_env
      )

    }else{

      sby_oracle_report_write_section(
        "REAL-TIME SQL MONITOR - REPORT",
        sby_oracle_report_result_text(monitor_report_result),
        report_env
      )
    }
  }

  invisible()
}
