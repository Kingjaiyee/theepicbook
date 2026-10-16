#!/usr/bin/env bash
# Logical backup of the EpicBook database into ./backups (run from the repo root)
set -euo pipefail
umask 077
cd "$(dirname "$0")/.."
mkdir -p backups
TS=$(date -u +%Y%m%dT%H%M%SZ)
OUT="backups/bookstore-$TS.sql.gz"
docker compose exec -T database sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" mysqldump -u "$MYSQL_USER" --single-transaction --no-tablespaces "$MYSQL_DATABASE"' \
  | gzip > "$OUT"
gzip -t "$OUT"
zcat "$OUT" | tail -n 1 | grep -q 'Dump completed'
echo "backup OK: $OUT"
