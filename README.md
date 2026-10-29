# Pterodactyl + Minecraft setup toolkit

This repository is a starter kit for checking endpoints and planning a Pterodactyl Panel + Wings Minecraft Java server deployment.

## Run the tests
```bash
python -m unittest discover -s tests -v
python tools/check_endpoints.py --help
```

## Endpoint checks
```bash
python tools/check_endpoints.py --panel https://panel.example.com --wings https://node.example.com --mc-host play.example.com --mc-port 25565
```
Replace example hostnames with your actual public endpoints. A successful TCP check proves the port is reachable, not that a Minecraft login works.

## Deployment
Use the official documentation and supported OS instructions:
- Panel: https://pterodactyl.io/panel/1.0/getting_started.html
- Wings: https://pterodactyl.io/wings/1.0/installing.html

The Panel and Wings must be installed on a real Linux VPS/node with administrator access. A Codespace is a development environment and is not itself a persistent public Minecraft server. Never commit passwords, API tokens, database credentials, or SSH private keys.
