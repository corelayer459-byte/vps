#!/usr/bin/env bash
# Pterodactyl Panel + Wings (Docker) installer. Ubuntu 22.04/24.04, run as root.
# Usage: sudo bash install.sh [PUBLIC_IP_OR_DOMAIN]
set -Eeuo pipefail
cd "$(dirname "$0")"
[ "$(id -u)" = 0 ] || { echo "Run as root: sudo bash install.sh [IP_OR_DOMAIN]"; exit 1; }
HOST="${1:-$(curl -fsS https://api.ipify.org || hostname -I | awk '{print $1}')}"
F="-f compose.yaml -f compose.wings.yaml"
command -v docker >/dev/null || curl -fsSL https://get.docker.com | sh
docker compose version >/dev/null

if [ ! -f .env ]; then
  umask 077
  cat > .env <<EOF
DB_PASSWORD=$(openssl rand -hex 24)
DB_ROOT_PASSWORD=$(openssl rand -hex 24)
APP_URL=http://${HOST}:8080
APP_SERVICE_AUTHOR=admin@example.com
MAIL_FROM=noreply@example.com
EOF
fi
mkdir -p .data/{database,redis,panel-var,nginx,certs,panel-logs,wings/etc} /var/lib/pterodactyl /var/log/pterodactyl /tmp/pterodactyl /run/wings/machine-id

docker compose $F up -d database cache
echo "waiting for database..."
for i in $(seq 1 60); do
  [ "$(docker inspect -f '{{.State.Health.Status}}' "$(docker compose $F ps -q database)" 2>/dev/null)" = healthy ] && break; sleep 3
done
docker compose $F up -d panel
echo "waiting for panel..."
for i in $(seq 1 60); do curl -fsS -o /dev/null http://127.0.0.1:8080/auth/login && break; sleep 3; done
sleep 25

if [ ! -f .data/.installed ]; then
  PW=$(openssl rand -base64 18 | tr -d '/+=')
  MEM=$(( $(free -m | awk '/Mem:/{print $2}') - 512 ))
  DISK=$(( $(df -m --output=avail /var/lib | tail -1) * 8 / 10 ))
  docker compose $F exec -T panel php artisan p:user:make --email=admin@example.com --username=admin --name-first=Admin --name-last=User --password="$PW" --admin=1
  docker compose $F exec -T panel php artisan p:location:make --short=main --long="Main"
  docker compose $F exec -T panel php artisan p:node:make --name=node1 --description="Wings node" --locationId=1 --fqdn="$HOST" --public=1 --scheme=http --proxy=0 --maintenance=0 --maxMemory=$MEM --overallocateMemory=0 --maxDisk=$DISK --overallocateDisk=0 --uploadSize=100 --daemonListeningPort=8081 --daemonSFTPPort=2022 --daemonBase=/var/lib/pterodactyl/volumes
  C=.data/wings/etc/config.yml
  docker compose $F exec -T panel php artisan p:node:configuration 1 --format=yaml > $C.new
  grep -q '^token:' $C.new || { echo "node config generation failed"; rm -f $C.new; exit 1; }
  mv $C.new $C; chmod 600 $C
  sed -i 's|^remote:.*|remote: "http://panel"|; s/172\.18\.0\./172.30.0./g' $C
  sed -i "s|^allowed_origins:.*|allowed_origins:\n- http://${HOST}:8080|" $C
  docker compose $F --profile wings up -d wings
  touch .data/.installed
  echo "=============================="
  echo "Panel:    http://${HOST}:8080"
  echo "Username: admin   Email: admin@example.com"
  echo "Password: $PW   (shown once - save it)"
  echo "=============================="
else
  docker compose $F --profile wings up -d wings
  echo "already installed - stack restarted"
fi
command -v ufw >/dev/null && ufw status | grep -q active && ufw allow 8080,8081,2022,25565/tcp || true
echo "Open these TCP ports in your provider firewall too: 8080 8081 2022 25565"
