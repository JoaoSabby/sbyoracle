#' Locate tagged Oracle cursors
#'
#' Locate tagged cursors in the local instance and select the most recently active child cursor.
#'
#' @param tag_id A character scalar containing the supplied query marker.
#' @param report_env An environment containing the accumulated sections vector.
#' @param conn An open DBI connection to Oracle Database 19c or later, typically created by ROracle.
#' @return A list with sql_id, child_number, and plan_hash_value; FALSE if no cursor is available.
#' @keywords internal
sby_oracle_report_locate_cursor <- function(tag_id, report_env, conn) {
  # Exclude the lookup statement itself, which also contains the marker.
  escaped_tag <- sby_oracle_report_sql_value(tag_id)
  cursor_query <- glue::glue("
    SELECT SQL_ID, CHILD_NUMBER, PLAN_HASH_VALUE, FULL_PLAN_HASH_VALUE,
      EXECUTIONS, LAST_ACTIVE_TIME, IS_BIND_SENSITIVE, IS_BIND_AWARE,
      IS_REOPTIMIZABLE, IS_RESOLVED_ADAPTIVE_PLAN
    FROM V$SQL
    WHERE DBMS_LOB.INSTR(SQL_FULLTEXT, '{escaped_tag}') > 0
      AND INSTR(SQL_TEXT, 'sbyoracle_cursor_lookup') = 0
    ORDER BY LAST_ACTIVE_TIME DESC NULLS LAST, CHILD_NUMBER DESC, SQL_ID
    /* sbyoracle_cursor_lookup */
  ")
  cursor_result <- sby_oracle_report_execute(cursor_query, conn)
  sby_oracle_report_write_section("LOCATED CURSORS", sby_oracle_report_result_text(cursor_result), report_env)
  if (!cursor_result$ok || nrow(cursor_result$data) == 0L) {
    sby_oracle_report_write_section("CURSOR NOT FOUND",
      "No tagged cursor was located. Verify V$SQL access, the connected instance and container, and shared pool retention.", report_env)
    return(FALSE)
  }
  list(sql_id = cursor_result$data$SQL_ID[1L],
    child_number = cursor_result$data$CHILD_NUMBER[1L],
    plan_hash_value = cursor_result$data$PLAN_HASH_VALUE[1L])
}
