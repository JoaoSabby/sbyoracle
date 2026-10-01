#' Collect plan operation statistics
#'
#' Collect estimated and actual row counts, resource usage, predicates, and projection by plan operation.
#'
#' @param sql_id The Oracle SQL identifier of the selected cursor.
#' @param child_number The numeric child cursor identifier.
#' @param report_env An environment containing the accumulated sections vector.
#' @param conn An open DBI connection to Oracle Database 19c or later, typically created by ROracle.
#' @return NULL, invisibly; report sections are appended to report_env.
#' @keywords internal
sby_oracle_report_plan_statistics <- function(sql_id, child_number, report_env, conn){
  # Collect estimated and actual row counts, resource usage, predicates, and projection by plan operation.

  escaped_id <- sby_oracle_report_sql_value(sql_id)

  statistics_query <- glue::glue("
    SELECT
      ID,
      PARENT_ID,
      DEPTH,
      OPERATION,
      OPTIONS,
      OBJECT_OWNER,
      OBJECT_NAME,
      OBJECT_TYPE,
      QBLOCK_NAME,
      DISTRIBUTION,
      PARTITION_START,
      PARTITION_STOP,
      CARDINALITY AS E_ROWS,
      LAST_STARTS,
      LAST_OUTPUT_ROWS AS A_ROWS,
      CASE
        WHEN CARDINALITY > 0
         AND LAST_OUTPUT_ROWS IS NOT NULL
        THEN ROUND(LAST_OUTPUT_ROWS / CARDINALITY, 6)
      END AS A_ROWS_DIV_E_ROWS,
      LAST_CR_BUFFER_GETS,
      LAST_CU_BUFFER_GETS,
      LAST_DISK_READS,
      LAST_DISK_WRITES,
      ROUND(
        LAST_ELAPSED_TIME / 1000000,
        6
      ) AS LAST_ELAPSED_SECONDS,
      LAST_MEMORY_USED,
      LAST_EXECUTION,
      LAST_DEGREE,
      LAST_TEMPSEG_SIZE,
      TEMP_SPACE,
      CPU_COST,
      IO_COST,
      ACCESS_PREDICATES,
      FILTER_PREDICATES,
      PROJECTION
    FROM V$SQL_PLAN_STATISTICS_ALL
    WHERE SQL_ID = '{escaped_id}'
      AND CHILD_NUMBER = {child_number}
    ORDER BY ID
  ")

  statistics_result <- sby_oracle_report_execute(statistics_query, conn)

  sby_oracle_report_write_section(
    "EXECUTION STATISTICS BY PLAN OPERATION",
    sby_oracle_report_result_text(statistics_result),
    report_env
  )

  invisible()
}
