#' Generate a comprehensive report for a tagged Oracle SQL statement
#'
#' Collect diagnostic information for a SQL statement already present in the
#' shared pool of Oracle Database 19c or later. All database access uses the
#' supplied DBI connection. The submitted statement is recorded without execution.
#'
#' @param sql_query A nonempty character scalar containing the complete SQL
#'   statement, including its identifying marker.
#' @param tagID A nonempty character scalar containing the exact marker token or
#'   complete SQL comment, for example `PREDY_RFM_20261001_1451` or
#'   `/*+ PREDY_RFM_20261001_1451 */`. It must occur literally in `sql_query`.
#' @param monitorStatistics A logical scalar. Defaults to `FALSE`, which prevents
#'   access to `V$SQL_MONITOR` and `DBMS_SQLTUNE.REPORT_SQL_MONITOR`. Enable only
#'   when the deployment is entitled to use Real-Time SQL Monitoring.
#' @param conn An open DBI connection to Oracle Database 19c or later, typically
#'   created with `DBI::dbConnect()` and `ROracle::Oracle()`.
#'
#' @details
#' The report includes the R caller stack, submitted SQL, marker, located cursors,
#' stored SQL text, cumulative cursor metrics, complete and adaptive execution
#' plans with hint reports, per-operation statistics, optimizer environment,
#' sampled bind variables, child cursor nonsharing reasons, adaptive cursor
#' sharing selectivity and statistics, and final cursor identification. Optional
#' monitoring adds monitoring rows and a native text report.
#'
#' The most recently active matching child cursor is selected from `V$SQL` in
#' the connected instance and container. Use a unique marker for each statement.
#' Diagnostics are sequential snapshots rather than an atomic snapshot. Cursor
#' metrics are cumulative. Last-execution statistics depend on collection during
#' the original execution; the function does not enable collection or change
#' session settings. Bind capture is sampled and may be absent. Diagnostic errors
#' are embedded in the corresponding sections so subsequent collection continues.
#'
#' The connection remains open. The function does not execute `sql_query`, commit,
#' roll back, or create a file. Save `result$report` with `writeLines()` if needed.
#' Invalid arguments raise an error before diagnostics begin. Failure to locate a
#' cursor returns `ok = FALSE` with a partial report. Otherwise `ok = TRUE` indicates
#' cursor identification even if individual sections are unavailable.
#'
#' @return A list, returned invisibly, containing `ok`, `tag_id`, `sql_id`,
#'   `child_number`, `plan_hash_value`, `monitor_statistics`, `sections`, and
#'   `report`. The last field is a scalar containing the complete report text.
#'   Cursor identifiers are `NULL` when no cursor can be located.
#' @references
#' [Oracle Database 19c DBMS_XPLAN reference](https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_XPLAN.html)
#'
#' [Oracle Database 19c licensing information](https://docs.oracle.com/en/database/oracle/oracle-database/19/dblic/Licensing-Information.html)
#' @examples
#' \dontrun{
#' # conn is an existing DBI connection created with the ROracle driver.
#' sql_query <- "SELECT /*+ PREDY_RFM_20261001_1451 */ COUNT(*) FROM DUAL"
#' query_result <- DBI::dbGetQuery(conn, sql_query)
#' result <- sby_oracle_query_report(sql_query, "PREDY_RFM_20261001_1451",
#'                                   monitorStatistics = FALSE, conn = conn)
#' cat(result$report)
#' writeLines(result$report, "oracle_query_report.txt", useBytes = TRUE)
#' }
#' @export
sby_oracle_query_report <- function(sql_query = character(), tagID = character(),
                                    monitorStatistics = FALSE, conn) {
  # Validate the public contract before issuing any diagnostic SQL.
  if (!is.character(sql_query) || length(sql_query) != 1L ||
      is.na(sql_query) || !nzchar(trimws(sql_query))) {
    stop("sql_query must be a nonempty character scalar.", call. = FALSE)
  }
  if (!is.character(tagID) || length(tagID) != 1L ||
      is.na(tagID) || !nzchar(trimws(tagID))) {
    stop("tagID must be a nonempty character scalar.", call. = FALSE)
  }
  if (!is.logical(monitorStatistics) || length(monitorStatistics) != 1L ||
      is.na(monitorStatistics)) {
    stop("monitorStatistics must be a nonmissing logical scalar.", call. = FALSE)
  }
  if (missing(conn) || !inherits(conn, "DBIConnection") || !DBI::dbIsValid(conn)) {
    stop("conn must be an open DBI connection to Oracle.", call. = FALSE)
  }

  # Accumulate sections without modifying global logging configuration.
  report_env <- new.env(parent = emptyenv())
  report_env$sections <- character()
  call_stack <- sys.calls()
  if (length(call_stack) > 0L) call_stack <- call_stack[-length(call_stack)]
  tag_id <- sby_oracle_report_identify_tag(sql_query, tagID, report_env)
  sby_oracle_report_call_stack(call_stack, sql_query, report_env)
  cursor <- sby_oracle_report_locate_cursor(tag_id, report_env, conn)

  if (!isFALSE(cursor)) {
    # Retain the original diagnostic sequence for the selected child cursor.
    sby_oracle_report_sql_text(cursor$sql_id, cursor$child_number, report_env, conn)
    sby_oracle_report_cursor_metrics(cursor$sql_id, cursor$child_number, report_env, conn)
    sby_oracle_report_execution_plan(cursor$sql_id, cursor$child_number, report_env, conn)
    sby_oracle_report_adaptive_plan(cursor$sql_id, cursor$child_number, report_env, conn)
    sby_oracle_report_plan_statistics(cursor$sql_id, cursor$child_number, report_env, conn)
    sby_oracle_report_optimizer_env(cursor$sql_id, cursor$child_number, report_env, conn)
    sby_oracle_report_bind_variables(cursor$sql_id, cursor$child_number, report_env, conn)
    sby_oracle_report_shared_cursor(cursor$sql_id, cursor$child_number, report_env, conn)
    sby_oracle_report_adaptive_cursor_sharing(cursor$sql_id, cursor$child_number, report_env, conn)
    sby_oracle_report_sql_monitor(cursor$sql_id, report_env, monitorStatistics, conn)
    sby_oracle_report_write_section("FINAL CURSOR IDENTIFICATION", paste0(
      "TAG_ID          : ", tag_id, "\n", "SQL_ID          : ", cursor$sql_id, "\n",
      "CHILD_NUMBER    : ", cursor$child_number, "\n",
      "PLAN_HASH_VALUE : ", cursor$plan_hash_value), report_env)
  }
  if (!monitorStatistics) {
    sby_oracle_report_write_section("REAL-TIME SQL MONITORING STATUS",
      "Disabled: monitorStatistics = FALSE. No SQL Monitoring calls were issued.", report_env)
  }

  # Return both the complete report and the selected cursor identifiers.
  invisible(list(ok = !isFALSE(cursor), tag_id = tag_id,
    sql_id = if (isFALSE(cursor)) NULL else cursor$sql_id,
    child_number = if (isFALSE(cursor)) NULL else cursor$child_number,
    plan_hash_value = if (isFALSE(cursor)) NULL else cursor$plan_hash_value,
    monitor_statistics = monitorStatistics, sections = report_env$sections,
    report = paste(report_env$sections, collapse = "")))
}
