#' Append a report section
#'
#' Append a delimited text section to the report accumulator.
#'
#' @param section_title A character scalar identifying the report section.
#' @param section_content Character content to append to the report.
#' @param report_env An environment containing the accumulated sections vector.
#' @return NULL, invisibly; report sections are appended to report_env.
#' @keywords internal
sby_oracle_report_write_section <- function(section_title, section_content, report_env) {
  # Keep report state local to the current invocation.
  section_text <- paste0("\n", strrep("=", 100L), "\n", section_title, "\n",
    strrep("=", 100L), "\n", paste(section_content, collapse = "\n"), "\n")
  report_env$sections <- c(report_env$sections, section_text)
  invisible(NULL)
}
