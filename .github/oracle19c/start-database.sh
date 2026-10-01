#!/usr/bin/env bash
set -euo pipefail

# Require explicit credentials; do not rely on a password emitted into logs.
: "${ORACLE19C_IMAGE:?ORACLE19C_IMAGE is required}"
: "${ORACLE_PWD:?ORACLE_PWD is required}"
docker pull "$ORACLE19C_IMAGE"
docker run --detach --name sbyoracle-oracle19c \
  --publish 127.0.0.1:1521:1521 \
  --shm-size 1g --memory 6g \
  --env ORACLE_SID=ORCLCDB \
  --env ORACLE_PDB=ORCLPDB1 \
  --env ORACLE_PWD \
  --env ORACLE_CHARACTERSET=AL32UTF8 \
  --env INIT_SGA_SIZE=1536 \
  --env INIT_PGA_SIZE=512 \
  "$ORACLE19C_IMAGE"
