#' Format report records
#'
#' Render the first data frame row as aligned name-value pairs.
#'
#' @param input_data A data frame containing diagnostic records.
#' @return A character scalar containing the formatted value or marker.
#' @keywords internal
sby_oracle_report_format_record <- function(input_data){
  # Render the first data frame row as aligned name-value pairs.

  if(is.null(input_data) || nrow(input_data) == 0L){

    return("<sem data>")
  }

  max_width <- max(nchar(names(input_data)))

  extracted_values <- vapply(
    input_data,
    function(target_column){

      sby_oracle_report_value(target_column[[1L]])
    },
    character(1L)
  )

  stringr::str_c(
    sprintf(
      stringr::str_c("%-", max_width, "s : %s"),
      names(input_data),
      extracted_values
    ),
    collapse = "\n"
  )
}
