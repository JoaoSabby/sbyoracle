# Load only the installed package; unit-test connection methods are not sourced.
library(testthat)
library(sbyoracle)

oracle19c_connection <- function(limited = FALSE) {
  if (!identical(Sys.getenv("SBYORACLE_TEST_ORACLE19C"), "true")) {
    stop("Oracle integration must be explicitly enabled.", call. = FALSE)
  }
  if (!requireNamespace("ROracle", quietly = TRUE)) {
    stop("ROracle must be installed for Oracle integration.", call. = FALSE)
  }
  username_key <- if (limited) "SBYORACLE_LIMITED_USERNAME" else "SBYORACLE_TEST_USERNAME"
  keys <- c(username_key, "SBYORACLE_TEST_PASSWORD", "SBYORACLE_TEST_DBNAME")
  values <- Sys.getenv(keys)
  if (any(!nzchar(values))) stop("Oracle integration connection settings are incomplete.", call. = FALSE)
  DBI::dbConnect(ROracle::Oracle(), username = values[[1L]],
                password = values[[2L]], dbname = values[[3L]])
}

oracle19c_tag <- function(prefix) {
  paste0("SBYORACLE_CI_", prefix, "_", Sys.getpid(), "_",
         format(Sys.time(), "%Y%m%d%H%M%OS6"))
}

oracle19c_save_report <- function(result, filename) {
  report_dir <- Sys.getenv("SBYORACLE_REPORT_DIR")
  if (nzchar(report_dir)) {
    dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)
    writeLines(result$report, file.path(report_dir, filename), useBytes = TRUE)
  }
}

oracle19c_section <- function(result, title) {
  sections <- result$sections[grepl(paste0("\n", title, "\n"), result$sections, fixed = TRUE)]
  expect_length(sections, 1L, info = paste("Missing or duplicated section:", title))
  paste(sections, collapse = "\n")
}
