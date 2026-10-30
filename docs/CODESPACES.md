# GitHub Codespaces: real Pterodactyl Panel (temporary development)

This starts the **actual Pterodactyl Panel application** from the upstream
\`ghcr.io/pterodactyl/panel\` image, with MariaDB and Redis. It is not a mock UI.
The official Panel Docker image is maintained by the Pterodactyl project.

## Start the Panel

1. Open this repository in GitHub Codespaces.
2. Rebuild the Codespace container so the Docker-in-Docker feature is installed.
3. In the Codespace terminal run:

\`\`\`bash
bash scripts/start-codespaces-panel.sh
\`\`\`

4. The script creates a local ignored \`.env\` with random database passwords,
   starts MariaDB and Redis, starts the real Panel container, runs the first
   database migrations, and prompts you to create the first Panel administrator.
5. Open the **Ports** tab and open port **8080** (keep it private).

Your forwarded URL is temporary and may change when the Codespace is recreated.
The Panel database and files are stored in \`.data/\` inside the Codespace
workspace. They are not a reliable backup; export backups somewhere safe.

## Wings and Minecraft: important limitation

This Codespace setup starts the real Panel only. It does **not** install or
claim to run a connected Wings node or Minecraft server.

Wings is a separate daemon that manages game-server Docker containers on a
Linux node. The official Pterodactyl documentation requires a supported Linux
host with Docker and appropriate system/network access. Codespaces is a
managed development container: Docker-in-Docker can be useful for development,
but it does not provide the supported persistent host/network environment
needed to promise a working public Wings node or public Minecraft server.

To finish a genuine deployment, attach a separate supported Ubuntu 22.04/24.04
node with Docker, root access, persistent storage and public network ports.
Create the node in Panel Admin → Nodes, use the exact generated configuration
command on that node, then enable Wings. Do not put node tokens or credentials
in this public repository.

See [the full deployment guide](REAL-DEPLOYMENT.md) and the official guides:
- Panel Docker: https://pterodactyl.io/panel/1.0/getting_started.html
- Wings: https://pterodactyl.io/wings/1.0/installing.html

## Stop the temporary stack

\`\`\`bash
docker compose down
\`\`\`

To remove local database and Panel data as well (destructive):

\`\`\`bash
rm -rf .data
\`\`\`

Never commit \`.env\`, \`.data/\`, passwords, APP_KEY values, node tokens,
API keys or SSH private keys.
