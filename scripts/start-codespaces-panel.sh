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
if ! command -v openssl >/dev/null 2>&1; then
  echo "OpenSSL is required to generate local database passwords."
  exit 1
fi

if [[ ! -f .env ]]; then
  if [[ -n "${CODESPACE_NAME:-}" && -n "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ]]; then
    app_url="https://${CODESPACE_NAME}-8080.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
  else
    app_url="http://localhost:8080"
  fi
  umask 077
  cat >.env <<EOF
DB_PASSWORD=$(openssl rand -hex 24)
DB_ROOT_PASSWORD=$(openssl rand -hex 24)
APP_URL=$app_url
APP_SERVICE_AUTHOR=admin@example.invalid
MAIL_FROM=noreply@example.invalid
EOF
  echo "Created private local .env with random database passwords."
fi

mkdir -p .data/database .data/redis .data/panel-var .data/nginx .data/certs .data/panel-logs
docker compose up -d database cache
echo "Waiting for MariaDB and Redis..."
for _ in $(seq 1 90); do
  if docker compose exec -T database mariadb-admin ping -h 127.0.0.1 --silent >/dev/null 2>&1 &&
     docker compose exec -T cache redis-cli ping 2>/dev/null | grep -q PONG; then
    break
  fi
  sleep 2
done
docker compose up -d panel
echo "Waiting for the Panel web server to respond..."
ready=0
for _ in $(seq 1 120); do
  if curl -fsS http://127.0.0.1:8080/ >/dev/null 2>&1; then ready=1; break; fi
  sleep 2
done
if [[ "$ready" -ne 1 ]]; then
  echo "Panel did not become ready. Recent logs:"
  docker compose logs --tail=100 panel
  exit 1
fi
echo
echo "The real Pterodactyl Panel is responding."
echo "Create the first administrator account:"
docker compose exec panel php artisan p:user:make
echo
echo "Open the forwarded port 8080 in the Codespaces Ports tab (keep it private)."
echo "This temporary Codespace currently has no connected Wings node."
