# 02 - Environment Variables, Ports and Persistence

Real values live only in `.env` on the VM (mode 600, git-ignored). This file lists names, never values.

## Environment variables

| Service | Variable | Purpose |
|---|---|---|
| database | `MYSQL_ROOT_PASSWORD` | MySQL root password (secret) |
| database | `MYSQL_DATABASE` | Database name: `bookstore` (the seed files require it) |
| database | `MYSQL_USER` | Application database user |
| database | `MYSQL_PASSWORD` | Application user password (secret) |
| backend | `NODE_ENV` | `production`: selects the production block in `config/config.json` |
| backend | `PORT` | Port the Node app listens on: `8080` |
| backend | `JAWSDB_URL` | MySQL connection URL, built by Compose from the `MYSQL_*` values (secret) |
| frontend, reverse-proxy | none | Static files and Nginx config only |

## Ports

| Service | Internal port | Published to host | Network(s) |
|---|---|---|---|
| reverse-proxy | 80 | `0.0.0.0:80` (the only public port) | front-tier |
| frontend | 80 | no | front-tier |
| backend | 8080 | no | front-tier, back-tier |
| database | 3306 | no | back-tier (internal) |

## Persistent data

| What | Where | Why |
|---|---|---|
| MySQL data | named volume `db_data` mounted at `/var/lib/mysql` | Survives container removal and `docker compose down` |
| Schema and seed SQL | `db/*.sql` mounted read-only into `/docker-entrypoint-initdb.d` | Runs once, only when `db_data` is empty |
| Proxy logs | host `./logs/proxy` mounted at `/var/log/nginx` | Logs survive proxy restarts |
| Backups | host `./backups` | `mysqldump` files for the restore drill |

## Health checks

| Service | Method | Healthy when |
|---|---|---|
| database | `mysqladmin ping` over TCP `127.0.0.1` as the app user | The real server accepts logins, not the temporary init server |
| backend | `wget http://127.0.0.1:8080/health` | App is up and the database query succeeds |
| frontend | `wget http://127.0.0.1/assets/css/style.css` | Nginx serves a real static file |
| reverse-proxy | `wget http://127.0.0.1/proxy-health` | Nginx answers; endpoint allows localhost only |
