#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
C=.data/wings/etc/config.yml
mkdir -p .data/wings/etc
[ -s "$C" ] || { echo "Missing $C - create the node in the Panel and paste its config there"; exit 1; }
chmod 600 "$C"
sed -i '0,/^  port: .*/s//  port: 8081/' "$C"
sed -i '0,/enabled: true/s//enabled: false/' "$C"
sudo mkdir -p /var/lib/pterodactyl /var/log/pterodactyl /tmp/pterodactyl
F="-f compose.yaml -f compose.wings.yaml"
docker compose $F --profile wings up -d wings
sleep 8
docker compose $F ps wings
docker compose $F logs --tail 25 wings
