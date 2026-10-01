#' Format report tables
#'
#' Render data frames as pipe-delimited report tables.
#'
#' @param input_data A data frame containing diagnostic records.
#' @return A character scalar containing the formatted value or marker.
#' @keywords internal
sby_oracle_report_format_table <- function(input_data){
  # Render data frames as pipe-delimited report tables.

  if(is.null(input_data) || nrow(input_data) == 0L){

    return("<sem data>")
  }

  header_text <- stringr::str_c(names(input_data), collapse = " | ")

  formatted_rows <- vapply(
    seq_len(nrow(input_data)),
    function(row_index){

      row_values <- vapply(
        input_data,
        function(current_column){

          sby_oracle_report_value(current_column[[row_index]])
        },
        character(1L)
      )

      stringr::str_c(row_values, collapse = " | ")
    },
    character(1L)
  )

  stringr::str_c(
    c(header_text, formatted_rows),
    collapse = "\n"
  )
}
