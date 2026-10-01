# Oracle 19c integration environment

This workflow validates the installed sbyoracle package against Oracle Database
19c through DBI and ROracle. It is independent of the standard package-check job.

## Components

- GitHub-hosted Ubuntu 22.04 x86-64 runner.
- Oracle Database Enterprise Edition 19.3.0.0 in an ephemeral Docker container.
- R 4.5.1, selected within the version range documented by the ROracle installer.
- Oracle Instant Client Basic and SDK 19.32 with verified SHA-256 checksums.
- ROracle compiled from CRAN source against the configured OCI headers/libraries.

The database remains Oracle 19c even though the client uses a later 19c update.
The database tag fixes the base release, not an Oracle Release Update. Testing a
specific patched 19c release requires an appropriately prepared image.

## Repository configuration

1. Obtain access to the Oracle Container Registry database/enterprise repository
   under the applicable Oracle terms. Registry access does not establish a
   database license entitlement.
2. In GitHub Settings > Secrets and variables > Actions, add repository secrets:
   - OCR_USERNAME: Oracle Container Registry username.
   - OCR_PASSWORD: registry authentication token accepted by docker login.
3. Merge the workflow into the default branch.
4. Open Actions > Oracle 19c integration > Run workflow.
5. Optionally set the repository variable ORACLE19C_INTEGRATION_ENABLED=true to
   run integration automatically on pushes to main.

Only registry credentials must be configured. The database administrator and
test passwords are generated, masked, and discarded for each job. Do not use a
production database for this workflow. The integration workflow does not run on
pull requests; the standard R package checks continue to run on pull requests.

If registry authentication or image access is missing, the job fails with an
actionable error rather than silently substituting a newer database or simulated
connection. This repository cannot automatically accept Oracle account terms.

## Provisioning

The container starts with a 6 GiB memory limit and 1 GiB shared memory. Its PDB is
ORCLPDB1, exposed only through 127.0.0.1:1521 on the runner. Readiness is checked
through SQL*Plus against the PDB open mode for up to 20 minutes.

The bootstrap runs as SYS only inside the disposable container. It disables
CONTROL_MANAGEMENT_PACK_ACCESS and creates two local users:

- SBYORACLE_TEST has CREATE SESSION, CREATE TABLE, a 10 MiB quota, and direct
  grants for the report views and packages.
- SBYORACLE_LIMITED has CREATE SESSION only and validates insufficient diagnostic
  privileges.

The client installer uses Ubuntu 22.04's libaio1 and registers OCI libraries with
ldconfig so R startup does not lose the library path. Both Basic and SDK archives
must use the same client version; update download URLs and checksums together.

## Integration assertions

The suite in tests/integration executes in a separate R process and loads the
installed package. It does not source unit-test connection methods.

The tests verify:

- The database version begins with 19 and management-pack access is NONE.
- A tagged SELECT with GATHER_PLAN_STATISTICS and NO_MONITOR returns the expected
  aggregate from 128 physical table rows.
- The selected SQL identifier, child number, stored SQL, and execution plan.
- Every standard report section, rejecting unavailable sections and ORA errors.
- A-Rows in DBMS_XPLAN and 128 output rows verified independently in
  V$SQL_PLAN_STATISTICS_ALL.
- Both a bare marker and a complete comment locate the same SQL.
- Reporting does not increment the submitted statement's execution counter.
- An unexecuted statement returns a partial report without being executed.
- A user without V$SQL access receives the expected partial report.
- The supplied connection remains valid after reporting.

Bind capture and adaptive cursor sharing can legitimately return no rows.
The suite does not require sampled binds or an adaptive plan to exist.
monitorStatistics=TRUE is covered only by simulated unit tests; the live suite
keeps monitoring disabled and does not request licensed monitoring resources.

## Local execution with an independently provisioned Oracle 19c database

Install the Oracle client, ROracle, dependencies, and the package first. Provision
equivalent test users and diagnostic grants in an isolated database. Set the
following environment variables without writing passwords into source files:

- SBYORACLE_TEST_ORACLE19C=true
- SBYORACLE_TEST_DBNAME=//host:1521/pdb_service
- SBYORACLE_TEST_USERNAME=SBYORACLE_TEST
- SBYORACLE_LIMITED_USERNAME=SBYORACLE_LIMITED
- SBYORACLE_TEST_PASSWORD: the password shared by the disposable test users
- SBYORACLE_REPORT_DIR: an output directory

Run Rscript .github/oracle19c/run-integration.R from the repository root.
The suite creates and drops SBYORACLE_CI_ROWS in the diagnostic test schema.
The workflow requires complete setup; missing drivers or connection settings
produce failures rather than skipped integration tests.

## Results

The oracle19c-integration-results artifact contains generated reports, JUnit XML,
R session information, and container logs/state. Artifacts are uploaded after
failure as well as success, before the container is removed. The standard
R CMD check is also executed with ROracle installed.

## References

- https://github.com/oracle/docker-images/tree/main/OracleDatabase/SingleInstance
- https://container-registry.oracle.com/
- https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html
- https://cran.r-project.org/web/packages/ROracle/INSTALL
- https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_XPLAN.html
