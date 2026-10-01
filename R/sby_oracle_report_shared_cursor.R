#' Collect cursor nonsharing reasons
#'
#' List nonsharing reason columns whose value is Y for the selected child cursor.
#'
#' @param sql_id The Oracle SQL identifier of the selected cursor.
#' @param child_number The numeric child cursor identifier.
#' @param report_env An environment containing the accumulated sections vector.
#' @param conn An open DBI connection to Oracle Database 19c or later, typically created by ROracle.
#' @return NULL, invisibly; report sections are appended to report_env.
#' @keywords internal
sby_oracle_report_shared_cursor <- function(sql_id, child_number, report_env, conn){
  # List nonsharing reason columns whose value is Y for the selected child cursor.

  escaped_id <- sby_oracle_report_sql_value(sql_id)

  sharing_query <- glue::glue("
    SELECT *
    FROM V$SQL_SHARED_CURSOR
    WHERE SQL_ID = '{escaped_id}'
      AND CHILD_NUMBER = {child_number}
  ")

  sharing_result <- sby_oracle_report_execute(sharing_query, conn)

  if(sharing_result$ok && nrow(sharing_result$data) > 0L){

    active_flags <- names(sharing_result$data)[
      vapply(
        sharing_result$data,
        function(current_column){

          any(
            as.character(current_column) == "Y",
            na.rm = TRUE
          )
        },
        logical(1L)
      )
    ]

    if(length(active_flags) == 0L){

      flag_text <- "<no flags with value Y>"

    }else{

      flag_text <- stringr::str_c(
        active_flags,
        collapse = "\n"
      )
    }

    sby_oracle_report_write_section(
      "CHILD CURSOR NONSHARING REASONS",
      flag_text,
      report_env
    )

  }else{

    sby_oracle_report_write_section(
      "CHILD CURSOR NONSHARING REASONS",
      sby_oracle_report_result_text(sharing_result),
      report_env
    )
  }

  invisible()
}
