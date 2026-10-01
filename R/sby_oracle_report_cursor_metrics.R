#' Collect cursor metrics
#'
#' Collect cumulative execution, resource, wait, memory, and optimizer metadata from V$SQL.
#'
#' @param sql_id The Oracle SQL identifier of the selected cursor.
#' @param child_number The numeric child cursor identifier.
#' @param report_env An environment containing the accumulated sections vector.
#' @param conn An open DBI connection to Oracle Database 19c or later, typically created by ROracle.
#' @return NULL, invisibly; report sections are appended to report_env.
#' @keywords internal
sby_oracle_report_cursor_metrics <- function(sql_id, child_number, report_env, conn){
  # Collect cumulative execution, resource, wait, memory, and optimizer metadata from V$SQL.

  safe_id <- sby_oracle_report_sql_value(sql_id)

  metrics_query <- glue::glue("
    SELECT
      SQL_ID,
      CHILD_NUMBER,
      HASH_VALUE,
      PLAN_HASH_VALUE,
      FULL_PLAN_HASH_VALUE,
      OPTIMIZER_MODE,
      OPTIMIZER_COST,
      OPTIMIZER_ENV_HASH_VALUE,
      PARSING_SCHEMA_NAME,
      MODULE,
      ACTION,
      CON_ID,
      FIRST_LOAD_TIME,
      LAST_LOAD_TIME,
      LAST_ACTIVE_TIME,
      EXECUTIONS,
      END_OF_FETCH_COUNT,
      PARSE_CALLS,
      FETCHES,
      ROWS_PROCESSED,
      SORTS,
      LOADS,
      INVALIDATIONS,
      BUFFER_GETS,
      DISK_READS,
      DIRECT_READS,
      DIRECT_WRITES,
      PHYSICAL_READ_REQUESTS,
      PHYSICAL_READ_BYTES,
      PHYSICAL_WRITE_REQUESTS,
      PHYSICAL_WRITE_BYTES,
      IO_INTERCONNECT_BYTES,
      CPU_TIME,
      ELAPSED_TIME,
      APPLICATION_WAIT_TIME,
      CONCURRENCY_WAIT_TIME,
      CLUSTER_WAIT_TIME,
      USER_IO_WAIT_TIME,
      PLSQL_EXEC_TIME,
      JAVA_EXEC_TIME,
      ROUND(CPU_TIME / 1000000, 6) AS CPU_SECONDS,
      ROUND(ELAPSED_TIME / 1000000, 6) AS ELAPSED_SECONDS,
      ROUND(USER_IO_WAIT_TIME / 1000000, 6) AS USER_IO_WAIT_SECONDS,
      ROUND(PHYSICAL_READ_BYTES / 1024 / 1024, 3) AS PHYSICAL_READ_MIB,
      ROUND(PHYSICAL_WRITE_BYTES / 1024 / 1024, 3) AS PHYSICAL_WRITE_MIB,
      PX_SERVERS_EXECUTIONS,
      SHARABLE_MEM,
      PERSISTENT_MEM,
      RUNTIME_MEM,
      IS_BIND_SENSITIVE,
      IS_BIND_AWARE,
      IS_SHAREABLE,
      IS_REOPTIMIZABLE,
      IS_RESOLVED_ADAPTIVE_PLAN,
      SQL_PROFILE,
      SQL_PATCH,
      SQL_PLAN_BASELINE,
      EXACT_MATCHING_SIGNATURE,
      FORCE_MATCHING_SIGNATURE,
      IM_SCANS,
      IM_SCAN_BYTES_UNCOMPRESSED,
      IM_SCAN_BYTES_INMEMORY,
      IO_CELL_OFFLOAD_ELIGIBLE_BYTES,
      IO_CELL_UNCOMPRESSED_BYTES,
      IO_CELL_OFFLOAD_RETURNED_BYTES
    FROM V$SQL
    WHERE SQL_ID = '{safe_id}'
      AND CHILD_NUMBER = {child_number}
  ")

  cursor_result <- sby_oracle_report_execute(metrics_query, conn)

  sby_oracle_report_write_section(
    "CURSOR METRICS",
    sby_oracle_report_result_text(
      cursor_result,
      record_format = TRUE
    ),
    report_env
  )

  invisible()
}
