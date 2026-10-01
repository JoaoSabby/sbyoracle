# Fail explicitly when a requested integration environment is incomplete.
if (getRversion() < numeric_version("4.6.0")) {
  stop("Oracle integration requires R 4.6.0 or later.")
}
if (!identical(Sys.getenv("SBYORACLE_TEST_ORACLE19C"), "true")) {
  stop("Set SBYORACLE_TEST_ORACLE19C=true to execute the Oracle 19c suite.")
}
required_packages <- c("DBI", "ROracle", "sbyoracle", "testthat")
for (package_name in required_packages) {
  if (!requireNamespace(package_name, quietly = TRUE)) {
    stop(sprintf("Required integration package is unavailable: %s", package_name))
  }
}
report_dir <- Sys.getenv("SBYORACLE_REPORT_DIR")
if (!nzchar(report_dir)) stop("SBYORACLE_REPORT_DIR must identify the artifact directory.")
dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)
writeLines(capture.output(sessionInfo()), file.path(report_dir, "session-info.txt"))
reporters <- testthat::MultiReporter$new(list(
  testthat::SummaryReporter$new(),
  testthat::JunitReporter$new(file = file.path(report_dir, "integration-tests.xml"))
))
testthat::test_dir("tests/integration", reporter = reporters,
                   stop_on_failure = TRUE, stop_on_warning = TRUE)
