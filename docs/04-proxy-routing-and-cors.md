# 04 - Proxy Routing and CORS

Nginx (`reverse-proxy`) is the only service with a published port (80). Pages, static files and the API are all served from one origin: `http://<VM public IP>`.

## Routes

| Request | Nginx location | Sent to |
|---|---|---|
| `/assets/*` (CSS, images, JS) | `location /assets/` | `frontend:80` (Nginx static files), 7-day browser cache |
| `/api/*` (cart API) | `location /api/` | `backend:8080` |
| `/health` | `location = /health` | `backend:8080` (checks the database) |
| `/`, `/cart`, `/gallery`, `/category/...` | `location /` | `backend:8080` (Express + Handlebars pages) |
| `/proxy-health` | `location = /proxy-health` | Answered by the proxy itself, localhost only (403 for everyone else) |

## How the proxy reaches the services

- `resolver 127.0.0.11` (Docker's DNS) with variables in `proxy_pass`: service names are looked up per request (cached 10s), so a restarted backend with a new IP is found again.
- `proxy_connect_timeout 3s` and `proxy_read_timeout 15s`: a stopped backend returns a fast 502 instead of a hanging page.
- Forwarded headers: `Host`, `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`.

## CORS: not required

CORS only applies when a page from one origin calls an API on a different origin (different scheme, host or port). Here every request the browser makes goes to `http://<VM public IP>:80` through the same proxy, so all requests are same-origin. The app sends no CORS headers and the proxy adds none. Adding `Access-Control-Allow-Origin` would only allow other websites to call this API from a visitor's browser, so it stays off. (In Assignment 6 the frontend on :3000 and the API on :3001 were different origins, so CORS was required there.)

## Finding

In Nginx, `return` runs before `allow`/`deny`. The first version of `/proxy-health` used `deny all` and still answered 200 to everyone. The fix checks `$remote_addr` before `return`.
