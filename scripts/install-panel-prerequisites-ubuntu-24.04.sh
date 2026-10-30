#!/usr/bin/env bash
set -Eeuo pipefail
# Dependencies only; complete Panel setup using docs/REAL-DEPLOYMENT.md.
if [[ $EUID -ne 0 ]]; then echo "Run as root: sudo bash $0"; exit 1; fi
. /etc/os-release
if [[ "$ID" != ubuntu || "$VERSION_ID" != 24.04 ]]; then echo "This script targets Ubuntu 24.04 only."; exit 1; fi
apt-get update
apt-get install -y nginx mariadb-server redis-server tar unzip curl git \
  php8.3 php8.3-common php8.3-cli php8.3-gd php8.3-mysql php8.3-mbstring \
  php8.3-bcmath php8.3-xml php8.3-fpm php8.3-curl php8.3-zip php8.3-intl
systemctl enable --now nginx mariadb redis-server php8.3-fpm
if ! command -v composer >/dev/null 2>&1; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsS https://getcomposer.org/installer -o "$tmp/composer-setup.php"
  php "$tmp/composer-setup.php" --install-dir=/usr/local/bin --filename=composer
fi
echo "Panel prerequisites installed. Continue with docs/REAL-DEPLOYMENT.md."
