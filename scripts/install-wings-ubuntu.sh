#!/usr/bin/env bash
set -Eeuo pipefail
# Installs Docker and the official Pterodactyl Wings binary on Ubuntu 22.04/24.04.
# Run as root on a supported KVM/bare-metal host. Panel-generated config is required.
if [[ $EUID -ne 0 ]]; then echo "Run as root: sudo bash $0"; exit 1; fi
. /etc/os-release
if [[ "$ID" != ubuntu || ( "$VERSION_ID" != 22.04 && "$VERSION_ID" != 24.04 ) ]]; then echo "Use Ubuntu 22.04 or 24.04."; exit 1; fi
if command -v systemd-detect-virt >/dev/null; then
  virt="$(systemd-detect-virt || true)"
  case "$virt" in lxc|openvz|virtuozzo) echo "Unsupported virtualization: $virt"; exit 1;; esac
fi
case "$(uname -m)" in x86_64) wings_arch=amd64;; aarch64|arm64) wings_arch=arm64;; *) echo "Unsupported CPU architecture"; exit 1;; esac
apt-get update
apt-get install -y ca-certificates curl
if ! command -v docker >/dev/null 2>&1; then curl -fsSL https://get.docker.com | sh; fi
systemctl enable --now docker
install -d -m 0755 /etc/pterodactyl
curl -fL "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$wings_arch" -o /usr/local/bin/wings
chmod 0755 /usr/local/bin/wings
cat >/etc/systemd/system/wings.service <<'UNIT'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service
[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
echo "Docker and Wings binary installed."
echo "Create a node in Panel Admin > Nodes and run its generated Auto-Deploy command here."
echo "Then run: systemctl enable --now wings"
echo "Do not start Wings until /etc/pterodactyl/config.yml exists."
