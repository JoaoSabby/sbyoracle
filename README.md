# sbyoracle

`sbyoracle` is an R package for a growing library of optimized routines targeting
Oracle Database 19c and later. Additional functions will be introduced over time
with consistent naming, connection handling, and technical documentation.
The initial implementation packages the supplied tagged SQL reporting routines.
Performance optimization and a comprehensive source audit are outside this stage.

## Installation

```r
install.packages("remotes")
remotes::install_github("JoaoSabby/sbyoracle")
# Before the initial implementation is merged, install its proposed branch:
remotes::install_github("JoaoSabby/sbyoracle", ref = "codex/initial-r-package")
```

R 4.1.0 or later and `DBI`, `glue`, and `stringr` are required. Install `ROracle`
separately with a compatible Oracle client when using that driver. The package
uses an existing connection and does not configure credentials or Oracle clients.

## Public interface

Only `sby_oracle_query_report()` is exported. Every helper has its own R file,
English roxygen2 documentation, and internal namespace visibility.

```r
sby_oracle_query_report(sql_query = character(), tagID = character(),
                        monitorStatistics = FALSE, conn)
```

| Argument | Contract |
| --- | --- |
| `sql_query` | One nonempty string containing the complete SQL statement and marker. |
| `tagID` | One nonempty string containing the marker token or its complete SQL comment; it must occur literally in `sql_query`. |
| `monitorStatistics` | One nonmissing logical value; `FALSE` disables Real-Time SQL Monitoring calls. |
| `conn` | An open DBI connection to Oracle 19c or later, typically created with `ROracle`. |

The character defaults specify types; valid nonempty values must be supplied.
Reporting inspects an existing cursor without executing the supplied statement.
Execute the tagged SQL beforehand with the DBI method appropriate to the statement.

```r
library(sbyoracle)
# conn is an existing connection created with DBI::dbConnect(ROracle::Oracle(), ...).
sql_query <- "SELECT /*+ PREDY_RFM_20261001_1451 */ COUNT(*) FROM DUAL"
query_result <- DBI::dbGetQuery(conn, sql_query)
result <- sby_oracle_query_report(
  sql_query = sql_query,
  tagID = "PREDY_RFM_20261001_1451",
  monitorStatistics = FALSE,
  conn = conn
)
cat(result$report)
writeLines(result$report, "oracle_query_report.txt", useBytes = TRUE)
```

The complete comment `/*+ PREDY_RFM_20261001_1451 */` may also be supplied as
`tagID`. Matching is literal and requires no fixed prefix. Use a unique tag per
statement. The marker itself does not enable runtime statistics or monitoring.

## Report contents

| Section | Information added |
| --- | --- |
| Query tag | Marker used to correlate the SQL statement. |
| R call stack | Caller function names captured before diagnostics begin. |
| Submitted SQL | Complete statement received from the caller. |
| Located cursors | Matching `V$SQL` children, SQL identifiers, plan hashes, executions, last activity, and bind/adaptive flags. |
| Stored SQL | `SQL_FULLTEXT` for the selected child cursor. |
| Cursor metrics | SQL and plan identifiers; optimizer mode, cost, environment hash; schema, module, action, container; load/activity timestamps; executions, fetches, parses, rows, sorts, loads, invalidations; logical/physical I/O; CPU, elapsed, wait, PL/SQL and Java time; converted seconds and MiB; parallel execution and memory counters; bind/sharing/adaptive flags; profile, patch, baseline; matching signatures; In-Memory and cell offload counters. |
| Complete execution plan | `DBMS_XPLAN.DISPLAY_CURSOR` with `ALL ALLSTATS LAST +HINT_REPORT`: operations, estimates, available last-execution statistics, predicates, projection, and hint usage information. |
| Adaptive execution plan | `ADAPTIVE ALLSTATS LAST +HINT_REPORT` output, including adaptive alternatives and available runtime statistics. |
| Plan operation statistics | Hierarchy, objects, query blocks, distribution, partitions, estimated/actual rows, actual-to-estimated row ratio, starts, buffers, disk I/O, elapsed seconds, memory, degree, temporary space, costs, predicates, and projection. |
| Optimizer environment | Parameter identifiers, names, values, and default indicators from `V$SQL_OPTIMIZER_ENV`. |
| Captured binds | Names, positions, types, precision, scale, maximum length, capture status/time, and sampled values from `V$SQL_BIND_CAPTURE`. |
| Child cursor nonsharing reasons | `V$SQL_SHARED_CURSOR` columns with value `Y`, or an explicit indication that none were found. |
| Adaptive cursor sharing selectivity | Available selectivity ranges from `V$SQL_CS_SELECTIVITY`. |
| Adaptive cursor sharing statistics | Available execution statistics from `V$SQL_CS_STATISTICS`. |
| Optional Real-Time SQL Monitor | Rows from `V$SQL_MONITOR`, requested only when `monitorStatistics = TRUE`. |
| Optional native monitoring report | `DBMS_SQLTUNE.REPORT_SQL_MONITOR` text with report level `ALL`, requested only when monitoring is enabled. |
| Final identification | Marker, selected `SQL_ID`, `CHILD_NUMBER`, and `PLAN_HASH_VALUE`. |
| Default monitoring status | Confirmation that no SQL Monitoring calls were issued. |

## Output and availability

The function invisibly returns `ok`, `tag_id`, `sql_id`, `child_number`,
`plan_hash_value`, `monitor_statistics`, `sections`, and `report` in a list.
`sections` contains individual text blocks; `report` contains the complete text
as one string. The connection remains open. File persistence and transactions
remain under caller control.

`ok = TRUE` means a cursor was identified even if a subsequent section failed.
Database failures appear as `<unavailable>` with the driver message. Empty results
appear as `<no data>`. Failed or empty cursor lookup returns `ok = FALSE`, `NULL`
cursor identifiers, and a partial report. Invalid arguments raise an error before
diagnostic SQL is issued.

The most recently active matching cursor is selected, using child number and SQL
identifier as secondary ordering keys. `V$SQL` covers the connected instance and
container, not every RAC instance. Flushed cursors are unavailable. Diagnostics
are sequential snapshots. Cursor counters are cumulative; last-operation
statistics depend on prior collection. Bind capture is sampled and may be absent.

## Database access and monitoring

The account requires access to `V$SQL`, `V$SQL_PLAN_STATISTICS_ALL`,
`V$SQL_OPTIMIZER_ENV`, `V$SQL_BIND_CAPTURE`, `V$SQL_SHARED_CURSOR`,
`V$SQL_CS_SELECTIVITY`, and `V$SQL_CS_STATISTICS`, and execution access to
`DBMS_XPLAN`. `DISPLAY_CURSOR` also requires access to `V$SQL_PLAN` and
`V$SESSION`. The database administrator normally configures grants on the
corresponding `V_$` objects.

`monitorStatistics = FALSE` prevents both SQL Monitoring calls. Existing plan
statistics from `DBMS_XPLAN` and `V$SQL_PLAN_STATISTICS_ALL` remain in the standard
report; these are distinct from Real-Time SQL Monitoring. The function does not
enable collection or alter session settings.

Enable monitoring only when the deployment is entitled to use Real-Time SQL
Monitoring and can access `V$SQL_MONITOR` and `DBMS_SQLTUNE.REPORT_SQL_MONITOR`.
Availability also depends on monitoring eligibility and retention. Monitoring
is filtered by SQL identifier and may include multiple executions and workers.

- [Oracle Database 19c DBMS_XPLAN](https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_XPLAN.html)
- [Oracle Database 19c licensing information](https://docs.oracle.com/en/database/oracle/oracle-database/19/dblic/Licensing-Information.html)

## Development

```r
roxygen2::roxygenise(".")
testthat::test_local(".")
```

Tests use a simulated DBI connection to verify assembly, monitoring controls,
unavailable sections, and validation. Live Oracle integration is a separate step.
