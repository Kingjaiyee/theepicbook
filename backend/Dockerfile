# ---------- Stage 1: install production dependencies only ----------
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --no-audit --no-fund && npm cache clean --force

# ---------- Stage 2: minimal runtime ----------
FROM node:22-alpine AS runtime
ENV NODE_ENV=production \
    PORT=8080
WORKDIR /app
# Code and dependencies stay root-owned and read-only to the app user
COPY --from=deps /app/node_modules ./node_modules
COPY package.json server.js ./
COPY config ./config
COPY models ./models
COPY routes ./routes
COPY views ./views
# Run as the image's built-in non-root user
USER node
EXPOSE 8080
CMD ["node", "server.js"]
