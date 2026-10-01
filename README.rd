\name{sbyoracle-readme}
\alias{sbyoracle-readme}
\title{sbyoracle: Oracle Database Routines and Tagged SQL Reports}
\description{
The sbyoracle package establishes a growing library of optimized R routines for
Oracle Database 19c and later. Additional functions will be introduced over time
under consistent naming, connection handling, and documentation conventions.
The initial release adapts the supplied diagnostic reporting implementation to
an installable package. Comprehensive source review and performance optimization
are outside this implementation stage.
}
\section{Installation}{
Install with \code{remotes::install_github("JoaoSabby/sbyoracle")}.
R 4.1.0 or later and DBI, glue, and stringr are required. Install ROracle and a
compatible Oracle client separately when using that driver.
}
\section{Public interface}{
Only \code{sby_oracle_query_report} is exported. Each internal helper has its own
R source file and English roxygen2 documentation.
\preformatted{
sby_oracle_query_report(sql_query = character(), tagID = character(),
                        monitorStatistics = FALSE, conn)
}
\describe{
\item{sql_query}{One nonempty character string containing the complete SQL
statement and its identifying marker.}
\item{tagID}{One nonempty string containing the exact marker token or the full
SQL comment. For example, PREDY_RFM_20261001_1451 or
\code{/*+ PREDY_RFM_20261001_1451 */}. It must occur literally in sql_query.}
\item{monitorStatistics}{One nonmissing logical value. FALSE prevents access to
Real-Time SQL Monitoring resources.}
\item{conn}{An open DBI connection to Oracle Database 19c or later, typically
created with the ROracle driver.}
}
The empty character defaults indicate argument types; valid nonempty values must
be supplied. The function inspects a previously executed statement without
executing the supplied SQL. Use a unique marker per statement. The marker itself
does not enable statistics collection or monitoring.
}
\section{Report contents}{
\describe{
\item{Query tag}{The marker used to correlate the SQL statement.}
\item{R call stack}{Caller function names captured before diagnostics begin.}
\item{Submitted SQL}{The complete statement received from the caller.}
\item{Located cursors}{Matching V$SQL children, identifiers, plan hashes,
execution counts, last activity, and bind/adaptive flags.}
\item{Stored SQL}{SQL_FULLTEXT for the selected child cursor.}
\item{Cursor metrics}{SQL and plan identifiers; optimizer mode, cost and
environment hash; schema, module, action and container; load/activity timestamps;
executions, fetches, parses, rows, sorts, loads and invalidations; logical and
physical I/O; CPU, elapsed, wait, PL/SQL and Java time; converted seconds and MiB;
parallel and memory counters; bind/sharing/adaptive flags; profiles, patches and
baselines; matching signatures; In-Memory and cell offload counters.}
\item{Complete execution plan}{DBMS_XPLAN.DISPLAY_CURSOR output using
ALL ALLSTATS LAST +HINT_REPORT, including operations, estimates, available runtime
statistics, predicates, projection, and hint usage information.}
\item{Adaptive execution plan}{ADAPTIVE ALLSTATS LAST +HINT_REPORT output,
including adaptive alternatives and available runtime statistics.}
\item{Plan operation statistics}{Hierarchy, objects, query blocks, distribution,
partitions, estimated/actual rows and their ratio, starts, buffers, disk I/O,
elapsed seconds, memory, degree, temporary space, costs, predicates and projection
from V$SQL_PLAN_STATISTICS_ALL.}
\item{Optimizer environment}{Parameter identifiers, names, values and default
indicators from V$SQL_OPTIMIZER_ENV.}
\item{Captured binds}{Names, positions, types, precision, scale, maximum length,
capture status/time and sampled values from V$SQL_BIND_CAPTURE.}
\item{Child cursor nonsharing reasons}{V$SQL_SHARED_CURSOR columns whose value
is Y, or an explicit indication that none were found.}
\item{Adaptive cursor sharing selectivity}{Available ranges from
V$SQL_CS_SELECTIVITY.}
\item{Adaptive cursor sharing statistics}{Available execution statistics from
V$SQL_CS_STATISTICS.}
\item{Optional Real-Time SQL Monitor}{V$SQL_MONITOR rows, requested only when
monitorStatistics is TRUE.}
\item{Optional native monitoring report}{DBMS_SQLTUNE.REPORT_SQL_MONITOR text
with report level ALL, requested only when monitoring is enabled.}
\item{Final identification}{Tag, selected SQL_ID, CHILD_NUMBER and PLAN_HASH_VALUE.}
\item{Default monitoring status}{Confirmation that no SQL Monitoring calls
were issued.}
}
}
\section{Output and availability}{
An invisible list contains ok, tag_id, sql_id, child_number, plan_hash_value,
monitor_statistics, sections and report. The sections vector contains individual
text blocks; report contains the complete text as one string. Persist it with
\code{writeLines(result$report, "oracle_query_report.txt", useBytes = TRUE)}.
The connection remains open, and transactions remain under caller control.

The ok flag indicates successful cursor identification, not successful retrieval
of every section. Database failures appear as \code{<unavailable>} followed by
the driver message; empty results appear as \code{<no data>}. Failed or empty
lookup returns ok = FALSE, NULL cursor identifiers and a partial report. Invalid
arguments raise an error before diagnostic SQL is issued.

The most recently active matching child cursor is selected, with child number
and SQL identifier used as secondary ordering keys. V$SQL covers the connected
instance and container, not every RAC instance. Flushed cursors are unavailable.
Diagnostics are sequential snapshots. Cursor counters are cumulative, operation
statistics depend on prior collection, and sampled binds may be absent.
}
\section{Database access and monitoring}{
Access is required to V$SQL, V$SQL_PLAN_STATISTICS_ALL, V$SQL_OPTIMIZER_ENV,
V$SQL_BIND_CAPTURE, V$SQL_SHARED_CURSOR, V$SQL_CS_SELECTIVITY and
V$SQL_CS_STATISTICS, plus execution access to DBMS_XPLAN. DISPLAY_CURSOR also
requires V$SQL_PLAN and V$SESSION. Database administrators normally configure
grants on the corresponding V_$ objects.

The default prevents calls to V$SQL_MONITOR and DBMS_SQLTUNE.REPORT_SQL_MONITOR.
Existing plan statistics remain in the standard report and are distinct from
Real-Time SQL Monitoring. The function does not enable collection or modify
session settings. Enable monitoring only for a deployment entitled to use that
feature and with access to both monitoring resources. Monitoring eligibility and
retention determine data availability. Monitoring is filtered by SQL identifier
and may include several executions and workers.
}
\examples{
\dontrun{
# conn is an existing DBI connection created with the ROracle driver.
sql_query <- "SELECT /*+ PREDY_RFM_20261001_1451 */ COUNT(*) FROM DUAL"
query_result <- DBI::dbGetQuery(conn, sql_query)
result <- sby_oracle_query_report(sql_query, "PREDY_RFM_20261001_1451",
                                  monitorStatistics = FALSE, conn = conn)
cat(result$report)
writeLines(result$report, "oracle_query_report.txt", useBytes = TRUE)
}
}
\references{
\url{https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_XPLAN.html}

\url{https://docs.oracle.com/en/database/oracle/oracle-database/19/dblic/Licensing-Information.html}
}

\section{Oracle 19c integration tests}{
A dedicated workflow provisions Oracle Database 19.3, R 4.5.1, Oracle Instant
Client 19c and ROracle. Configure repository secrets OCR_USERNAME and OCR_PASSWORD
for Oracle Container Registry access. After merging the workflow, select Actions,
Oracle 19c integration, Run workflow. Set ORACLE19C_INTEGRATION_ENABLED=true
as a repository variable to enable execution on pushes to main.

The live suite verifies all standard diagnostic sections, stored SQL, plan
statistics, both marker forms, missing cursors, insufficient diagnostic
privileges and connection preservation. SQL Monitoring remains disabled.
Artifacts include reports, JUnit XML, R session information and container logs.
Detailed prerequisites and local execution instructions are maintained in
.github/oracle19c/README.md.
}
