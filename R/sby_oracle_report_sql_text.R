#' Retrieve stored SQL text
#'
#' Retrieve the complete SQL text stored in the shared pool for the selected cursor.
#'
#' @param sql_id The Oracle SQL identifier of the selected cursor.
#' @param child_number The numeric child cursor identifier.
#' @param report_env An environment containing the accumulated sections vector.
#' @param conn An open DBI connection to Oracle Database 19c or later, typically created by ROracle.
#' @return NULL, invisibly; report sections are appended to report_env.
#' @keywords internal
sby_oracle_report_sql_text <- function(sql_id, child_number, report_env, conn){
  # Retrieve the complete SQL text stored in the shared pool for the selected cursor.

  escaped_id <- sby_oracle_report_sql_value(sql_id)

  sql_text_query <- glue::glue("
    SELECT SQL_FULLTEXT
    FROM V$SQL
    WHERE SQL_ID = '{escaped_id}'
      AND CHILD_NUMBER = {child_number}
  ")

  sql_text_result <- sby_oracle_report_execute(sql_text_query, conn)

  if(sql_text_result$ok && nrow(sql_text_result$data) > 0L){

    sby_oracle_report_write_section(
      "SQL TEXT STORED BY ORACLE",
      sby_oracle_report_value(sql_text_result$data$SQL_FULLTEXT[[1L]]),
      report_env
    )
  } else {
    sby_oracle_report_write_section("SQL TEXT STORED BY ORACLE", sby_oracle_report_result_text(sql_text_result), report_env)
  }

  invisible()
}
