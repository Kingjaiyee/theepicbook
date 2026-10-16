# 05 - Persistence, Backup and Restore

## What is persistent

| Data | Where | Survives |
|---|---|---|
| MySQL data (books, authors, cart) | named volume `db_data` at `/var/lib/mysql` | container removal, `docker compose down`, image upgrades |
| Backups | host `./backups` (dir mode 700, files mode 600, git-ignored) | anything except loss of the VM disk |

`docker compose down -v` deletes `db_data`. It is never used on this stack except for a deliberate full reset after a verified backup.

## Backup plan

- Method: logical dump with `mysqldump --single-transaction --no-tablespaces`, run inside the database container as the app user (password from the container environment, never on the command line). `--single-transaction` gives a consistent InnoDB snapshot without locking the app.
- Output: `./backups/bookstore-<UTC timestamp>.sql.gz`, then checked with `gzip -t` and for the `-- Dump completed` line.
- Schedule (production): daily cron on the VM, keep 7 daily copies, and copy each dump off the VM (for example S3 with encryption and versioning). A backup that only lives on the same disk does not survive losing the VM.
- Restore test: at least monthly, restore the newest dump and check row counts.

~~~bash
# Example cron entry (daily 02:15 UTC) and 7-day retention
15 2 * * * cd /home/ubuntu/theepicbook && ./scripts/backup.sh && find backups -name '*.sql.gz' -mtime +7 -delete
~~~

## Restore procedure

1. Pick the dump: `BACKUP=$(ls -t backups/*.sql.gz | head -n 1)` and check it with `gzip -t "$BACKUP"`.
2. Stop the app so nothing reads half-restored tables: `docker compose stop backend`.
3. Load the dump into the database (it drops and recreates each table):
   `zcat "$BACKUP" | docker compose exec -T database sh -c 'MYSQL_PWD="$MYSQL_PASSWORD" mysql -u "$MYSQL_USER" "$MYSQL_DATABASE"'`
4. Start the app and wait for health: `docker compose start backend` then `docker compose up -d --wait backend`.
5. Verify: row counts match, the known record is back, and `http://<VM public IP>/health` returns 200.

## Drill result (capstone)

Inserted a labelled test book, took a backup, deleted the book (0 rows left, 54 books), restored from the dump: the book came back with the same id and the count returned to 55. A `docker compose down` / `up` afterwards kept the same `db_data` volume (same creation time) and the same data.
