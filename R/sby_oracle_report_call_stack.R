#' Record the R call stack
#'
#' Append caller function names and the submitted SQL text to the report.
#'
#' @param call_stack A list of calls captured with sys.calls().
#' @param sql_query A character scalar containing the complete SQL statement.
#' @param report_env An environment containing the accumulated sections vector.
#' @return NULL, invisibly; report sections are appended to report_env.
#' @keywords internal
sby_oracle_report_call_stack <- function(call_stack, sql_query, report_env){
  # Append caller function names and the submitted SQL text to the report.

  function_names <- if(length(call_stack) == 0L){

    character(0L)

  }else{

    vapply(
      call_stack,
      function(current_call){

        if(length(current_call) == 0L){

          return("<unknown>")
        }

        stringr::str_c(
          deparse(current_call[[1L]]),
          collapse = ""
        )
      },
      character(1L)
    )
  }

  formatted_stack <- stringr::str_c(
    "GlobalEnv",
    if(length(function_names) > 0L){
      stringr::str_c(
        "\n  -> ",
        function_names,
        "()",
        collapse = ""
      )
    }else{
      ""
    }
  )

  sby_oracle_report_write_section(
    "R CALL STACK",
    formatted_stack,
    report_env
  )

  sby_oracle_report_write_section(
    "SUBMITTED SQL QUERY",
    sql_query,
    report_env
  )
}
