#!/usr/bin/env bash
set -euo pipefail

: "${SBYORACLE_TEST_PASSWORD:?SBYORACLE_TEST_PASSWORD is required}"
if [[ ! "$SBYORACLE_TEST_PASSWORD" =~ ^[A-Za-z][A-Za-z0-9_]{15,127}$ ]]; then
  echo "The disposable database password must contain only letters, digits, and underscores." >&2
  exit 1
fi

# Poll the actual PDB through SQL*Plus; an open listener is insufficient.
ready=false
for attempt in $(seq 1 120); do
  container_state=$(docker inspect --format '{{.State.Status}}' sbyoracle-oracle19c)
  if [[ "$container_state" != running ]]; then
    echo "Oracle stopped before database initialization completed." >&2
    exit 1
  fi
  if docker exec -i sbyoracle-oracle19c bash -c 'sqlplus -s "/ as sysdba"' <<'SQL' | grep -q 'SBYORACLE_PDB_READY'
WHENEVER SQLERROR EXIT FAILURE
WHENEVER OSERROR EXIT FAILURE
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT 'SBYORACLE_PDB_READY' FROM V$PDBS
WHERE NAME = 'ORCLPDB1' AND OPEN_MODE = 'READ WRITE';
EXIT
SQL
  then
    ready=true
    break
  fi
  echo "Waiting for ORCLPDB1 to open ($attempt/120)."
  sleep 10
done
if [[ "$ready" != true ]]; then
  echo "ORCLPDB1 did not become ready within 20 minutes." >&2
  exit 1
fi
docker cp .github/oracle19c/bootstrap.sql sbyoracle-oracle19c:/tmp/sbyoracle-bootstrap.sql
docker exec sbyoracle-oracle19c \
  bash -c 'exec sqlplus -s "/ as sysdba" @/tmp/sbyoracle-bootstrap.sql "$1"' \
  bash "$SBYORACLE_TEST_PASSWORD"
