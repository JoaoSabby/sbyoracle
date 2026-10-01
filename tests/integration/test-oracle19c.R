test_that("the installed package reports a fully fetched Oracle 19c cursor", {
  conn <- oracle19c_connection()
  on.exit(DBI::dbDisconnect(conn), add = TRUE)
  version <- DBI::dbGetQuery(conn, "SELECT VERSION FROM V$INSTANCE")$VERSION[[1L]]
  expect_match(version, "^19\\.")
  pack_access <- DBI::dbGetQuery(conn,
    "SELECT VALUE FROM V$PARAMETER WHERE NAME = 'control_management_pack_access'")$VALUE[[1L]]
  expect_identical(pack_access, "NONE")

  # Create a small physical table so the plan includes a measured row source.
  DBI::dbExecute(conn, paste(
    "CREATE TABLE SBYORACLE_CI_ROWS AS SELECT LEVEL AS ID,",
    "RPAD('x', 32, 'x') AS PAYLOAD FROM DUAL CONNECT BY LEVEL <= 128"))
  on.exit(DBI::dbExecute(conn, "DROP TABLE SBYORACLE_CI_ROWS PURGE"), add = TRUE, after = FALSE)
  DBI::dbExecute(conn,
    "BEGIN DBMS_STATS.GATHER_TABLE_STATS(USER, 'SBYORACLE_CI_ROWS'); END;")
  tag_id <- oracle19c_tag("SELECT")
  sql_query <- sprintf(
    "SELECT /*+ GATHER_PLAN_STATISTICS NO_MONITOR */ /* %s */ SUM(ID) AS TOTAL FROM SBYORACLE_CI_ROWS",
    tag_id)
  query_result <- DBI::dbGetQuery(conn, sql_query)
  expect_equal(query_result$TOTAL[[1L]], 8256)

  output <- withVisible(sby_oracle_query_report(sql_query, tag_id, conn = conn))
  result <- output$value
  oracle19c_save_report(result, "tagged-select-report.txt")
  expect_false(output$visible)
  expect_true(result$ok)
  expect_false(result$monitor_statistics)
  expect_match(result$sql_id, "^[0-9a-z]{13}$")
  expect_true(is.numeric(result$child_number))
  expect_true(result$plan_hash_value > 0)
  expect_true(DBI::dbIsValid(conn))
  expect_identical(getNamespaceExports("sbyoracle"), "sby_oracle_query_report")

  titles <- c("QUERY TAG", "R CALL STACK", "SUBMITTED SQL QUERY", "LOCATED CURSORS",
    "SQL TEXT STORED BY ORACLE", "CURSOR METRICS", "COMPLETE EXECUTION PLAN",
    "ADAPTIVE EXECUTION PLAN", "EXECUTION STATISTICS BY PLAN OPERATION",
    "OPTIMIZER ENVIRONMENT", "CAPTURED BIND VARIABLES", "CHILD CURSOR NONSHARING REASONS",
    "ADAPTIVE CURSOR SHARING - SELECTIVITY", "ADAPTIVE CURSOR SHARING - STATISTICS",
    "FINAL CURSOR IDENTIFICATION", "REAL-TIME SQL MONITORING STATUS")
  for (title in titles) {
    section <- oracle19c_section(result, title)
    expect_false(grepl("<unavailable>|ORA-[0-9]+", section), info = title)
  }
  expect_match(oracle19c_section(result, "SQL TEXT STORED BY ORACLE"), sql_query, fixed = TRUE)
  plan <- oracle19c_section(result, "COMPLETE EXECUTION PLAN")
  expect_match(plan, "Plan hash value:", fixed = TRUE)
  expect_match(plan, "A-Rows", fixed = TRUE)
  expect_match(plan, "SBYORACLE_CI_ROWS", fixed = TRUE)
  operations <- oracle19c_section(result, "EXECUTION STATISTICS BY PLAN OPERATION")
  expect_match(operations, "A_ROWS", fixed = TRUE)
  expect_match(operations, "SBYORACLE_CI_ROWS", fixed = TRUE)

  # Independently verify last-execution rows rather than trusting the ok flag.
  cursor_filter <- sprintf("SQL_ID = %s AND CHILD_NUMBER = %d",
    as.character(DBI::dbQuoteString(conn, result$sql_id)), as.integer(result$child_number))
  rows <- DBI::dbGetQuery(conn, paste(
    "SELECT LAST_OUTPUT_ROWS FROM V$SQL_PLAN_STATISTICS_ALL WHERE",
    cursor_filter, "AND OBJECT_NAME = 'SBYORACLE_CI_ROWS'"))
  expect_true(nrow(rows) > 0L)
  expect_true(any(rows$LAST_OUTPUT_ROWS == 128, na.rm = TRUE))

  # A complete SQL comment must also locate the same child without re-execution.
  executions_before <- DBI::dbGetQuery(conn,
    paste("SELECT EXECUTIONS FROM V$SQL WHERE", cursor_filter))$EXECUTIONS[[1L]]
  comment_result <- sby_oracle_query_report(sql_query, paste0("/* ", tag_id, " */"), conn = conn)
  expect_true(comment_result$ok)
  expect_identical(comment_result$sql_id, result$sql_id)
  executions_after <- DBI::dbGetQuery(conn,
    paste("SELECT EXECUTIONS FROM V$SQL WHERE", cursor_filter))$EXECUTIONS[[1L]]
  expect_equal(executions_after, executions_before)
})

test_that("an unexecuted statement produces a partial report without executing SQL", {
  conn <- oracle19c_connection()
  on.exit(DBI::dbDisconnect(conn), add = TRUE)
  tag_id <- oracle19c_tag("NOT_EXECUTED")
  sql_query <- sprintf("SELECT /* %s */ 1 AS VALUE FROM DUAL", tag_id)
  result <- sby_oracle_query_report(sql_query, tag_id, conn = conn)
  oracle19c_save_report(result, "missing-cursor-report.txt")
  expect_false(result$ok)
  expect_null(result$sql_id)
  expect_match(result$report, "CURSOR NOT FOUND", fixed = TRUE)
  expect_false(grepl("<unavailable>", result$report, fixed = TRUE))
  expect_true(DBI::dbIsValid(conn))
})

test_that("insufficient diagnostic privileges are reported without closing the connection", {
  conn <- oracle19c_connection(limited = TRUE)
  on.exit(DBI::dbDisconnect(conn), add = TRUE)
  tag_id <- oracle19c_tag("LIMITED")
  sql_query <- sprintf("SELECT /* %s */ 1 AS VALUE FROM DUAL", tag_id)
  expect_equal(DBI::dbGetQuery(conn, sql_query)$VALUE[[1L]], 1)
  result <- sby_oracle_query_report(sql_query, tag_id, conn = conn)
  oracle19c_save_report(result, "restricted-user-report.txt")
  expect_false(result$ok)
  expect_null(result$sql_id)
  expect_match(result$report, "<unavailable>", fixed = TRUE)
  expect_match(result$report, "ORA-(00942|01031)")
  expect_true(DBI::dbIsValid(conn))
})
