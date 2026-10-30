#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker CLI is missing. Rebuild the Codespace using the repository devcontainer."
  exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose plugin is missing in this environment."
  exit 1
fi

if [[ ! -f .env ]]; then
  if [[ -z "\${CODESPACE_NAME:-}" || -z "\${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ]]; then
    app_url="http://localhost:8080"
  else
    app_url="https://\${CODESPACE_NAME}-8080.\${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
  fi
  db_password="$(openssl rand -hex 24)"
  root_password="$(openssl rand -hex 24)"
  umask 077
  cat >.env <<EOF
DB_PASSWORD=$db_password
DB_ROOT_PASSWORD=$root_password
APP_URL=$app_url
APP_SERVICE_AUTHOR=admin@example.invalid
MAIL_FROM=noreply@example.invalid
EOF
  echo "Created private local .env with random database passwords."
fi

mkdir -p .data/database .data/redis .data/panel-var .data/nginx .data/certs .data/panel-logs
docker compose up -d database cache
echo "Waiting for MariaDB and Redis health checks..."
for _ in $(seq 1 60); do
  db="$(docker compose ps --format json database 2>/dev/null | grep -c '"Health":"healthy"' || true)"
  redis="$(docker compose ps --format json cache 2>/dev/null | grep -c '"Health":"healthy"' || true)"
  if [[ "$db" -gt 0 && "$redis" -gt 0 ]]; then break; fi
  sleep 2
done
docker compose up -d panel
echo "Waiting for the Panel container..."
for _ in $(seq 1 60); do
  if docker compose exec -T panel php artisan --version >/dev/null 2>&1; then break; fi
  sleep 2
done
echo "Running first-install database migrations..."
docker compose exec -T panel php artisan migrate --seed --force
echo
echo "Panel container is running. Create the first admin account now:"
docker compose exec panel php artisan p:user:make
echo
echo "Open the forwarded port 8080 in the Codespaces Ports tab."
echo "This is a temporary development Panel. It has no connected Wings node yet."
