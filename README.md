# ΛFFiNE One-Click VPS Deploy

Transform any VPS into your personal AFFiNE knowledge operating system in under 5 minutes.

## Overview

This repository provides a production-ready, one-command deployment for a self-hosted AFFiNE instance on a fresh Ubuntu/Debian VPS using Docker. It includes:

- Automated install and configuration of Docker and the AFFiNE stack
- Secure-by-default server hardening (UFW firewall, Fail2ban, SSH hardening)
- Automated nightly backups (database + storage + config)
- Simple upgrade workflow
- Optional SSL via Let's Encrypt + Nginx reverse proxy

## Quick Start

Run on a fresh Ubuntu/Debian VPS (as root or via sudo):

```bash
curl -s https://raw.githubusercontent.com/Lu-aer/affine-deploy/main/deploy.sh | sudo bash
```

After the script completes, open your browser to:

- http://YOUR_SERVER_IP

If setting up a domain with SSL, see SSL section below.

## Requirements

- Ubuntu 20.04/22.04/24.04 or Debian 11/12
- Root access (or sudo)
- Open ports: 22 (SSH), 80 (HTTP), 443 (HTTPS if using SSL)
- Recommended: 2 vCPU, 4 GB RAM, 20+ GB disk

## What Gets Installed

- Docker Engine + Docker Compose plugin
- AFFiNE app + PostgreSQL (pgvector) + Redis via `docker-compose.yml`
- Directory layout under `/opt/affine`:
  - `/opt/affine/data/postgres` – PostgreSQL data
  - `/opt/affine/data/redis` – Redis data
  - `/opt/affine/data/affine` – AFFiNE storage (uploads)
  - `/opt/affine/config` – AFFiNE config files (e.g., `config.json`)
  - `/opt/affine/backups` – Backup artifacts

## Public Commands (Scripts)

All scripts are designed to be run on the VPS.

### deploy.sh – One-command installation

Usage:
```bash
sudo bash deploy.sh
```
What it does:
- Updates packages and installs Docker + Compose plugin
- Creates `/opt/affine` directory structure
- Downloads `docker-compose.yml`, `config.json`, `backup.sh`, `security.sh`
- Moves `config.json` to `/opt/affine/config/`
- Makes scripts executable and sets permissive data/config permissions
- Applies security hardening via `security.sh`
- Starts all services via Docker Compose
- Sets up nightly backups at 2:00 AM via cron
- Prints access URL and useful commands

Environment:
- If you want a custom database password, set `POSTGRES_PASSWORD` before running:
  ```bash
  export POSTGRES_PASSWORD='your-strong-password'
  sudo -E bash deploy.sh
  ```

### backup.sh – Create a point-in-time backup

Usage:
```bash
/opt/affine/backup.sh
```
Creates three artifacts in `/opt/affine/backups` with a timestamp prefix:
- `<timestamp>_database.sql` – PostgreSQL dump
- `<timestamp>_storage.tar.gz` – AFFiNE storage archive
- `<timestamp>_config` – Directory copy of `/opt/affine/config`

Retention:
- Files older than 7 days are removed automatically
- Note: the config backup is a directory and is not removed by the current retention rule

Example restore (manual):
```bash
# Stop stack
cd /opt/affine && docker compose down

# Restore config (optional)
cp -r /opt/affine/backups/<timestamp>_config/* /opt/affine/config/

# Restore storage
tar -xzf /opt/affine/backups/<timestamp>_storage.tar.gz -C /opt/affine

# Restore database
cat /opt/affine/backups/<timestamp>_database.sql | docker exec -i affine-postgres psql -U affine -d affine

# Start stack
cd /opt/affine && docker compose up -d
```

### upgrade.sh – Upgrade to latest images

Usage:
```bash
/opt/affine/upgrade.sh
```
What it does:
- Runs `/opt/affine/backup.sh` first
- Pulls latest container images
- Restarts services on latest versions

### security.sh – Basic VPS hardening

Usage:
```bash
/opt/affine/security.sh
```
Applies:
- UFW firewall: deny incoming by default; allow SSH (22), HTTP (80), HTTPS (443)
- Fail2ban for SSH (3 retries, 1-hour ban)
- SSH hardening: disables password auth and root login over SSH
- Enables unattended upgrades without automatic reboot

Important:
- Ensure you have working SSH key-based access before running (deploy script will run it for you)

### ssl-setup.sh – Optional SSL via Let’s Encrypt

Usage:
```bash
/opt/affine/ssl-setup.sh your-domain.com
```
Prerequisites:
- DNS A record for `your-domain.com` pointing to your server
- Ports 80 and 443 open

What it does:
- Installs Nginx + certbot
- Creates an Nginx site and obtains a TLS certificate via Let’s Encrypt

Important note about ports and proxy target:
- The default Docker compose publishes AFFiNE on host port 80 (`80:3010`). If you use Nginx, you should avoid a port-80 conflict and proxy to AFFiNE’s internal port (3010). Recommended adjustments:
  1) Change the AFFiNE service ports mapping in `docker-compose.yml` to bind 3010 on localhost only:
     ```yaml
     services:
       affine:
         # ...
         ports:
           - "127.0.0.1:3010:3010"
     ```
  2) Update the Nginx server block to proxy to `http://127.0.0.1:3010`:
     ```nginx
     server {
       listen 80;
       server_name your-domain.com;

       location / {
         proxy_pass http://127.0.0.1:3010;
         proxy_set_header Host $host;
         proxy_set_header X-Real-IP $remote_addr;
         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
         proxy_set_header X-Forwarded-Proto $scheme;
       }
     }
     ```
- Then run certbot to obtain and configure SSL for 443.

## Services (Docker Compose)

`docker-compose.yml` defines four services:

- postgres (ankane/pgvector:latest)
  - Env: `POSTGRES_USER=affine`, `POSTGRES_PASSWORD`, `POSTGRES_DB=affine`
  - Volume: `./data/postgres:/var/lib/postgresql/data`
  - Healthcheck: `pg_isready -U affine`

- redis (redis:7)
  - Volume: `./data/redis:/data`
  - Healthcheck: `redis-cli ping`

- affine_migration (ghcr.io/toeverything/affine:stable)
  - Runs `node ./scripts/self-host-predeploy.js`
  - Env: `DATABASE_URL`, `REDIS_SERVER_HOST`
  - Volumes: `./data/affine` (storage), `./config` (config)
  - Depends on healthy postgres and redis

- affine (ghcr.io/toeverything/affine:stable)
  - Env: `NODE_ENV=production`, `AFFINE_CONFIG_PATH=/root/.affine/config`, `DATABASE_URL`, `REDIS_SERVER_HOST`, `REDIS_SERVER_PORT=6379`
  - Ports: by default `80:3010` (see SSL notes above)
  - Volumes: `./data/affine` (storage), `./config` (config)
  - Healthcheck: `curl -f http://localhost:3010/`

## Configuration Reference

Primary config file: `/opt/affine/config/config.json`

```json
{
  "$schema": "https://raw.githubusercontent.com/toeverything/AFFiNE/master/packages/config/src/config.schema.json",
  "server": {
    "name": "ΛFFiNE Personal Knowledge OS",
    "path": "/",
    "host": "0.0.0.0",
    "port": 3010
  },
  "database": {
    "url": "postgres://affine:affinepass@postgres:5432/affine"
  },
  "redis": {
    "host": "redis",
    "port": 6379
  },
  "storage": {
    "provider": "local",
    "local": { "path": "/root/.affine/storage" }
  },
  "copilot": { "enabled": false },
  "features": { "earlyAccess": false }
}
```

Notes:
- To customize the database password at deployment, set `POSTGRES_PASSWORD` in your environment before running `deploy.sh`. Ensure the `database.url` in `config.json` matches your chosen password if AFFiNE reads from config.
- Storage path should match the volume mount in Docker compose.

## Operating the Stack

Common commands (from `/opt/affine`):

```bash
# Status
docker compose ps

# Tail logs for all services
docker compose logs -f

# Restart services
docker compose restart

# Stop / Start
docker compose down
docker compose up -d
```

## Backups and Restore

- Nightly backups run at 2:00 AM via cron: `crontab -l` to verify
- Manual backup: `/opt/affine/backup.sh`
- Restore: see the example in the `backup.sh` section above

## Troubleshooting

- Service won’t start:
  - `docker compose ps` and `docker compose logs -f`
  - Ensure ports 80/443 are free if using Nginx
- Database auth errors:
  - Ensure `POSTGRES_PASSWORD` and `config.json` database URL are consistent
- SSL challenges fail:
  - Confirm DNS records point to your server and ports 80/443 are open

## Security Considerations

- The deploy script sets permissive permissions for data/config directories to simplify first-run (`chmod -R 777`). You may tighten these to least-privilege after verifying the stack runs as expected.
- `security.sh` disables password authentication for SSH. Ensure you have working SSH keys before running it.

## Uninstall / Cleanup

```bash
cd /opt/affine
# Stop and remove containers
docker compose down -v
# Remove data and config (irreversible!)
sudo rm -rf /opt/affine
```

## License

This repository is provided as-is without warranty. AFFiNE itself is licensed by the upstream project. Refer to the upstream AFFiNE license for details.


