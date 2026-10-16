# 03 - Health Checks and Startup Order

## Health checks (run inside each container)

| Service | Check | Interval / timeout / retries / start period | Healthy means |
|---|---|---|---|
| database | `mysqladmin ping -h 127.0.0.1` as the app user, password via `MYSQL_PWD` | 10s / 5s / 10 / 60s | The real MySQL server accepts TCP logins |
| backend | `wget http://127.0.0.1:8080/health` | 10s / 5s / 6 / 20s | App answers and its database check passes (503 if the database is down) |
| frontend | `wget --spider http://127.0.0.1/assets/css/style.css` | 10s / 5s / 3 / 5s | Nginx serves a real static file |
| reverse-proxy | `wget --spider http://127.0.0.1/proxy-health` | 10s / 5s / 3 / 5s | Nginx answers (endpoint returns 403 to anyone but localhost) |

## Startup order (`depends_on` with `condition: service_healthy`)

1. `database` starts first.
2. `backend` waits until `database` is healthy.
3. `frontend` has no dependencies and starts in parallel.
4. `reverse-proxy` waits until both `frontend` and `backend` are healthy.

## Why these choices

- TCP, not the socket: on first boot the MySQL image runs a temporary server on the socket only (port 0) while it creates the database and user and runs the seed SQL. A socket ping can pass during that phase and let the backend start before the seed data exists. TCP on 127.0.0.1 only answers once the real server is listening on 3306.
- The database password reaches `mysqladmin` through `MYSQL_PWD` inside the container (`$$` in Compose), so it is not on a command line or in `docker inspect`.
- The backend check includes the database, so the proxy only goes live when the whole request path works.
- `restart: unless-stopped` brings services back after a crash or reboot, but not after a deliberate `docker compose stop`.
