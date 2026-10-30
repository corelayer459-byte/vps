# Real Pterodactyl deployment

This repository contains genuine installation helpers, not a simulated server UI.
They do not claim that a Panel, Wings daemon, or Minecraft server is already running.

## Hosting requirement
Pterodactyl needs a supported Linux host with administrator/root access, persistent storage, Docker support, and reachable network ports. GitHub Pages is static hosting; GitHub Codespaces is temporary and is not a supported production Wings host.

Recommended layout:
- Panel: Ubuntu 24.04 host, public HTTPS hostname, PHP 8.3, MariaDB, Redis, NGINX.
- Node: Ubuntu 22.04/24.04 host with KVM or bare-metal virtualization and Docker.
- Configure required web, Wings API, SFTP and game-allocation ports in host and provider firewalls.

## 1. Panel prerequisites (Ubuntu 24.04)
On a fresh Ubuntu 24.04 Panel host, run as root:
\`\`\`bash
sudo bash scripts/install-panel-prerequisites-ubuntu-24.04.sh
\`\`\`
Then follow the official stable Panel 1.x installation guide:
https://pterodactyl.io/panel/1.0/getting_started.html
That guide covers the official release, Composer dependencies, database, environment, application key, migrations, administrator account, NGINX, HTTPS, queue worker and scheduler. Back up APP_KEY securely. Never commit .env or credentials.

## 2. Install Wings on the node
On a fresh Ubuntu 22.04/24.04 node with Docker-compatible virtualization:
\`\`\`bash
sudo bash scripts/install-wings-ubuntu.sh
\`\`\`
The script installs Docker, the official Wings binary and a systemd unit. It does not invent a node token or configuration.
In the Panel, open **Admin → Nodes → Create New**, save the node, then open **Configuration** and use **Generate Token / Auto-Deploy**. Run the exact command shown by your Panel on the node. It writes /etc/pterodactyl/config.yml. Then:
\`\`\`bash
sudo systemctl enable --now wings
sudo systemctl status wings --no-pager
\`\`\`
Official Wings guide: https://pterodactyl.io/wings/1.0/installing.html

## 3. Create the Minecraft Java server
1. Add an allocation for the node's real reachable IP and chosen game port.
2. Import/install a Minecraft Java egg from a trusted source in the Panel.
3. Create a server and assign its allocation and appropriate resource limits.
4. Start it and check the live console/logs.
5. Test from a separate Minecraft Java client using the node's public address and allocated port.
A TCP port check alone does not prove that Minecraft login works.

## 4. Verification
\`\`\`bash
docker info
/usr/local/bin/wings --version
sudo systemctl is-active wings
\`\`\`
In the Panel, the node must show as connected and the Minecraft server must show as running before calling the deployment complete.

## Safety and secrets
- Never commit passwords, Panel application keys, API tokens, node tokens, SSH keys or .env contents.
- Use unique strong passwords and HTTPS.
- Restrict SSH and admin access; keep Ubuntu and Docker updated.
- Back up the database, Panel files, APP_KEY and server data.
