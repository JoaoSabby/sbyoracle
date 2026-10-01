#' Validate the query tag
#'
#' Validate the supplied marker and confirm its literal presence in the query.
#'
#' @param sql_query A character scalar containing the complete SQL statement.
#' @param tag_id A character scalar containing the supplied query marker.
#' @param report_env An environment containing the accumulated sections vector.
#' @return A character scalar containing the formatted value or marker.
#' @keywords internal
sby_oracle_report_identify_tag <- function(sql_query, tag_id, report_env) {
  # Accept either the marker token or its complete SQL comment.
  if (!grepl(tag_id, sql_query, fixed = TRUE)) stop("tagID must occur literally in sql_query.", call. = FALSE)
  sby_oracle_report_write_section("QUERY TAG", tag_id, report_env)
  tag_id
}
