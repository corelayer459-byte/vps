# Install on a real VPS (Ubuntu 22.04/24.04)

    git clone https://github.com/corelayer459-byte/vps && cd vps
    sudo bash install.sh YOUR_SERVER_IP_OR_DOMAIN

It installs Docker, then starts the Panel, MariaDB, Redis and Wings, creates an admin account, and prints the password once. Open TCP 8080, 8081, 2022 and 25565 in your provider firewall. Panel and Wings use plain HTTP; put a domain and TLS in front before real use. Re-running the script is safe: it never deletes `.data/`.
