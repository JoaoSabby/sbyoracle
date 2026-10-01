#' Format diagnostic results
#'
#' Convert successful results or database errors to report text.
#'
#' @param result A list containing ok, data, and error fields.
#' @param record_format A logical scalar selecting aligned name-value output.
#' @return A character scalar containing the formatted value or marker.
#' @keywords internal
sby_oracle_report_result_text <- function(result, record_format = FALSE){
  # Convert successful results or database errors to report text.

  if(!result$ok){

    return(
      stringr::str_c(
        "<unavailable>\n",
        result$error
      )
    )
  }

  if(record_format){

    return(sby_oracle_report_format_record(result$data))
  }

  sby_oracle_report_format_table(result$data)
}
