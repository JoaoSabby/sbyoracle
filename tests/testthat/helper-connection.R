# Simulate DBI responses without executing SQL against an Oracle deployment.
library(DBI)
methods::setClass("sbyoracle_test_connection", contains = "DBIConnection",
                  slots = c(state = "environment"))
methods::setMethod("dbIsValid", "sbyoracle_test_connection", function(dbObj, ...) TRUE)
methods::setMethod("dbGetQuery", c("sbyoracle_test_connection", "character"),
  function(conn, statement, ...) {
    conn@state$queries <- c(conn@state$queries, statement)
    if (grepl("sbyoracle_cursor_lookup", statement, fixed = TRUE)) {
      if (conn@state$lookup_error) stop("ORA-00942: table or view does not exist")
      if (conn@state$empty) return(data.frame())
      return(data.frame(SQL_ID = "0123456789abc", CHILD_NUMBER = 2,
                        PLAN_HASH_VALUE = 123456789))
    }
    if (grepl("V$SQL_OPTIMIZER_ENV", statement, fixed = TRUE) && conn@state$section_error) {
      stop("ORA-01031: insufficient privileges")
    }
    if (grepl("SELECT SQL_FULLTEXT", statement, fixed = TRUE)) {
      return(data.frame(SQL_FULLTEXT = conn@state$sql_query))
    }
    if (grepl("DBMS_XPLAN", statement, fixed = TRUE)) {
      return(data.frame(PLAN_TABLE_OUTPUT = c("Plan hash value: 123456789", "TABLE ACCESS FULL")))
    }
    if (grepl("REPORT_SQL_MONITOR", statement, fixed = TRUE)) {
      return(data.frame(REPORT = "Native monitoring report\nExecution details"))
    }
    if (grepl("V$SQL_SHARED_CURSOR", statement, fixed = TRUE)) {
      return(data.frame(BIND_MISMATCH = "Y", OPTIMIZER_MISMATCH = "N"))
    }
    data.frame(METRIC = "available", VALUE = 1)
  })

report_test_connection <- function(empty = FALSE, lookup_error = FALSE,
                                   section_error = FALSE) {
  state <- new.env(parent = emptyenv())
  state$queries <- character()
  state$empty <- empty
  state$lookup_error <- lookup_error
  state$section_error <- section_error
  state$sql_query <- "SELECT /*+ PREDY_RFM_20261001_1451 */ COUNT(*) FROM DUAL"
  methods::new("sbyoracle_test_connection", state = state)
}
