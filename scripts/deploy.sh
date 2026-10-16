#!/usr/bin/env bash
# Deploy a given image tag on the VM (run as ubuntu from the repo root).
# Also the rollback tool: run it again with an older tag.
set -euo pipefail
TAG="${1:?usage: deploy.sh <image-tag>}"
[[ "$TAG" =~ ^[0-9a-f]{7,40}$ ]] || { echo "invalid image tag: $TAG" >&2; exit 1; }
cd "$(dirname "$0")/.."
test -f .env || { echo ".env missing" >&2; exit 1; }
# Record the deployed tag so later manual "docker compose up" uses the same images
sed -i '/^IMAGE_TAG=/d' .env
echo "IMAGE_TAG=$TAG" >> .env
docker compose pull backend frontend
docker compose up -d --no-build --wait
docker compose ps --format 'table {{.Service}}\t{{.Image}}\t{{.Status}}'
