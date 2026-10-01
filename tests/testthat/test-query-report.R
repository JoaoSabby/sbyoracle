test_that("the default assembles diagnostics without accessing SQL Monitoring", {
  conn <- report_test_connection()
  output <- withVisible(sby_oracle_query_report(conn@state$sql_query,
    "/*+ PREDY_RFM_20261001_1451 */", conn = conn))
  expect_false(output$visible)
  result <- output$value
  expect_true(result$ok)
  expect_identical(result$sql_id, "0123456789abc")
  expect_equal(result$child_number, 2)
  expect_match(result$report, "SUBMITTED SQL QUERY", fixed = TRUE)
  expect_match(result$report, "TABLE ACCESS FULL", fixed = TRUE)
  expect_match(result$report, "BIND_MISMATCH", fixed = TRUE)
  expect_match(result$report, "ADAPTIVE CURSOR SHARING - STATISTICS", fixed = TRUE)
  expect_match(result$report, "FINAL CURSOR IDENTIFICATION", fixed = TRUE)
  expect_match(result$report, "No SQL Monitoring calls were issued", fixed = TRUE)
  expect_length(conn@state$queries, 11L)
  expect_false(any(grepl("V$SQL_MONITOR", conn@state$queries, fixed = TRUE)))
  expect_false(any(grepl("DBMS_SQLTUNE", conn@state$queries, fixed = TRUE)))
  expect_false(any(conn@state$queries == conn@state$sql_query))
  expect_false(grepl("REGEXP_LIKE", conn@state$queries[1L], fixed = TRUE))
  expect_identical(getNamespaceExports("sbyoracle"), "sby_oracle_query_report")
})

test_that("monitoring is collected only after explicit opt-in", {
  conn <- report_test_connection()
  result <- sby_oracle_query_report(conn@state$sql_query, "PREDY_RFM_20261001_1451",
                                    monitorStatistics = TRUE, conn = conn)
  expect_true(result$monitor_statistics)
  expect_true(any(grepl("V$SQL_MONITOR", conn@state$queries, fixed = TRUE)))
  expect_true(any(grepl("DBMS_SQLTUNE.REPORT_SQL_MONITOR", conn@state$queries, fixed = TRUE)))
  expect_match(result$report, "Native monitoring report\nExecution details", fixed = TRUE)
  expect_length(conn@state$queries, 13L)
})

test_that("lookup failures return a usable partial report", {
  for (failure_type in c("empty", "lookup_error")) {
    conn <- if (failure_type == "empty") report_test_connection(empty = TRUE) else
      report_test_connection(lookup_error = TRUE)
    result <- sby_oracle_query_report(conn@state$sql_query, "PREDY_RFM_20261001_1451", conn = conn)
    expect_false(result$ok)
    expect_null(result$sql_id)
    expect_null(result$child_number)
    expect_match(result$report, "CURSOR NOT FOUND", fixed = TRUE)
    expect_length(conn@state$queries, 1L)
  }
})

test_that("section failures do not prevent subsequent diagnostics", {
  conn <- report_test_connection(section_error = TRUE)
  result <- sby_oracle_query_report(conn@state$sql_query, "PREDY_RFM_20261001_1451", conn = conn)
  expect_true(result$ok)
  expect_match(result$report, "<unavailable>\nORA-01031", fixed = TRUE)
  expect_match(result$report, "CAPTURED BIND VARIABLES", fixed = TRUE)
  expect_match(result$report, "FINAL CURSOR IDENTIFICATION", fixed = TRUE)
})

test_that("invalid arguments fail before diagnostic SQL", {
  conn <- report_test_connection()
  expect_error(sby_oracle_query_report(conn = conn), "sql_query")
  expect_error(sby_oracle_query_report(c("SELECT 1", "SELECT 2"), "tag", conn = conn), "sql_query")
  expect_error(sby_oracle_query_report(conn@state$sql_query, NA_character_, conn = conn), "tagID")
  expect_error(sby_oracle_query_report(conn@state$sql_query, "missing", conn = conn), "occur literally")
  expect_error(sby_oracle_query_report(conn@state$sql_query, "PREDY", NA, conn), "monitorStatistics")
  expect_error(sby_oracle_query_report(conn@state$sql_query, "PREDY", conn = NULL), "open DBI")
  expect_length(conn@state$queries, 0L)
})

test_that("literal marker quoting preserves SQL and value formatting is scalar", {
  conn <- report_test_connection()
  sql_query <- "SELECT /* marker_'_01 */ 1 FROM DUAL"
  result <- sby_oracle_query_report(sql_query, "marker_'_01", conn = conn)
  expect_match(conn@state$queries[1L], "marker_''_01", fixed = TRUE)
  expect_match(result$report, sql_query, fixed = TRUE)
  expect_length(sbyoracle:::sby_oracle_report_value(as.POSIXct(c("2026-10-01", "2026-10-02"))), 1L)
})
