# ΛFFiNE VPS Deployment - API Documentation

## Overview

This project provides a complete one-click deployment solution for ΛFFiNE (Personal Knowledge OS) on VPS servers. It includes automated deployment scripts, security hardening, backup management, and upgrade procedures.

## Table of Contents

1. [Core Deployment Script](#core-deployment-script)
2. [Backup Management](#backup-management)
3. [Security Hardening](#security-hardening)
4. [SSL Configuration](#ssl-configuration)
5. [System Upgrades](#system-upgrades)
6. [Configuration Files](#configuration-files)
7. [Docker Services](#docker-services)
8. [Usage Examples](#usage-examples)
9. [Troubleshooting](#troubleshooting)

---

## Core Deployment Script

### `deploy.sh`

The main deployment script that automates the entire ΛFFiNE VPS setup process.

#### **Function**: `main()`
**Description**: Orchestrates the complete deployment process  
**Parameters**: None (requires root privileges)  
**Returns**: Exit code 0 on success, 1 on failure  

#### **Function**: `check_root_privileges()`
**Description**: Verifies script is running with root permissions  
**Parameters**: None  
**Returns**: Exits with error if not root  

#### **Function**: `update_system()`
**Description**: Updates system packages and installs Docker  
**Parameters**: None  
**Returns**: None  

#### **Function**: `setup_directory_structure()`
**Description**: Creates necessary directories and downloads configuration files  
**Parameters**: None  
**Returns**: None  

#### **Function**: `apply_security()`
**Description**: Runs security hardening script  
**Parameters**: None  
**Returns**: None  

#### **Function**: `start_services()`
**Description**: Launches Docker containers and waits for health checks  
**Parameters**: None  
**Returns**: None  

#### **Function**: `setup_backups()`
**Description**: Configures automated daily backups via cron  
**Parameters**: None  
**Returns**: None  

#### **Usage**:
```bash
sudo ./deploy.sh
```

#### **Prerequisites**:
- Ubuntu/Debian-based VPS
- Root access (sudo)
- Internet connectivity
- Minimum 2GB RAM, 20GB storage

#### **Output**:
- System updates and Docker installation
- Directory structure creation
- Security hardening
- Service deployment
- Backup automation setup
- Access URL and credentials

---

## Backup Management

### `backup.sh`

Automated backup script for ΛFFiNE data, database, and configuration.

#### **Function**: `create_backup()`
**Description**: Creates timestamped backup of all critical data  
**Parameters**: None  
**Returns**: None  

#### **Function**: `backup_database()`
**Description**: Exports PostgreSQL database to SQL file  
**Parameters**: None  
**Returns**: SQL backup file  

#### **Function**: `backup_storage()`
**Description**: Archives storage files to compressed tar  
**Parameters**: None  
**Returns**: Compressed storage backup  

#### **Function**: `backup_config()`
**Description**: Copies configuration files to backup directory  
**Parameters**: None  
**Returns**: Configuration backup  

#### **Function**: `cleanup_old_backups()`
**Description**: Removes backups older than 7 days  
**Parameters**: None  
**Returns**: None  

#### **Backup Locations**:
- Database: `/opt/affine/backups/affine_backup_YYYYMMDD_HHMMSS_database.sql`
- Storage: `/opt/affine/backups/affine_backup_YYYYMMDD_HHMMSS_storage.tar.gz`
- Config: `/opt/affine/backups/affine_backup_YYYYMMDD_HHMMSS_config/`

#### **Usage**:
```bash
# Manual backup
./backup.sh

# Automated (configured by deploy.sh)
# Runs daily at 2:00 AM via cron
```

#### **Retention Policy**:
- Keeps last 7 days of backups
- Automatically removes older backups
- Backup size displayed after completion

---

## Security Hardening

### `security.sh`

Comprehensive security configuration script for production deployments.

#### **Function**: `install_firewall()`
**Description**: Installs and configures UFW firewall  
**Parameters**: None  
**Returns**: None  

#### **Function**: `configure_firewall_rules()`
**Description**: Sets up firewall rules for web services  
**Parameters**: None  
**Returns**: None  

#### **Function**: `install_fail2ban()`
**Description**: Installs and configures fail2ban for SSH protection  
**Parameters**: None  
**Returns**: None  

#### **Function**: `harden_ssh()`
**Description**: Secures SSH configuration  
**Parameters**: None  
**Returns**: None  

#### **Function**: `setup_auto_updates()`
**Description**: Configures automatic security updates  
**Parameters**: None  
**Returns**: None  

#### **Security Features**:
- **Firewall**: UFW with default deny incoming
- **SSH Protection**: fail2ban with 3 retry limit
- **Port Access**: SSH (22), HTTP (80), HTTPS (443)
- **SSH Hardening**: Password auth disabled, root login disabled
- **Auto Updates**: Unattended security updates

#### **Usage**:
```bash
# Run manually
./security.sh

# Automatically run by deploy.sh
```

#### **Important Notes**:
- Password authentication is disabled
- SSH key access must be configured beforehand
- Firewall blocks all incoming connections except specified ports

---

## SSL Configuration

### `ssl-setup.sh`

Optional SSL certificate setup using Let's Encrypt and Nginx.

#### **Function**: `setup_ssl(domain)`
**Description**: Configures SSL for specified domain  
**Parameters**: `domain` - Domain name for SSL certificate  
**Returns**: None  

#### **Function**: `install_certbot()`
**Description**: Installs Let's Encrypt certbot and Nginx  
**Parameters**: None  
**Returns**: None  

#### **Function**: `create_nginx_config(domain)`
**Description**: Generates Nginx configuration for domain  
**Parameters**: `domain` - Domain name  
**Returns**: None  

#### **Function**: `obtain_certificate(domain)`
**Description**: Requests SSL certificate from Let's Encrypt  
**Parameters**: `domain` - Domain name  
**Returns**: None  

#### **Prerequisites**:
- Domain name pointing to server IP
- Port 80 and 443 accessible
- Valid email address for Let's Encrypt

#### **Usage**:
```bash
./ssl-setup.sh your-domain.com
```

#### **What it does**:
1. Installs Nginx and Certbot
2. Creates Nginx configuration
3. Obtains SSL certificate
4. Configures automatic redirects
5. Enables HTTPS access

---

## System Upgrades

### `upgrade.sh`

Automated upgrade script for ΛFFiNE services.

#### **Function**: `upgrade_services()`
**Description**: Upgrades all services to latest versions  
**Parameters**: None  
**Returns**: None  

#### **Function**: `create_pre_upgrade_backup()`
**Description**: Creates backup before upgrade process  
**Parameters**: None  
**Returns**: None  

#### **Function**: `pull_latest_images()`
**Description**: Downloads latest Docker images  
**Parameters**: None  
**Returns**: None  

#### **Function**: `restart_services()`
**Description**: Restarts services with new images  
**Parameters**: None  
**Returns**: None  

#### **Upgrade Process**:
1. Creates backup of current installation
2. Pulls latest Docker images
3. Stops running services
4. Starts services with new images
5. Waits for health checks
6. Displays service status

#### **Usage**:
```bash
./upgrade.sh
```

#### **Safety Features**:
- Automatic backup before upgrade
- Health check verification
- Rollback capability via backup

---

## Configuration Files

### `config.json`

ΛFFiNE application configuration file.

#### **Schema**: AFFiNE Config Schema
**Source**: https://raw.githubusercontent.com/toeverything/AFFiNE/master/packages/config/src/config.schema.json

#### **Configuration Options**:

##### Server Configuration
```json
{
  "server": {
    "name": "ΛFFiNE Personal Knowledge OS",
    "path": "/",
    "host": "0.0.0.0",
    "port": 3010
  }
}
```

- **name**: Server display name
- **path**: Application base path
- **host**: Bind address (0.0.0.0 for all interfaces)
- **port**: Application port (3010)

##### Database Configuration
```json
{
  "database": {
    "url": "postgres://affine:affinepass@postgres:5432/affine"
  }
}
```

- **url**: PostgreSQL connection string
- Format: `postgres://username:password@host:port/database`

##### Redis Configuration
```json
{
  "redis": {
    "host": "redis",
    "port": 6379
  }
}
```

- **host**: Redis server hostname
- **port**: Redis server port

##### Storage Configuration
```json
{
  "storage": {
    "provider": "local",
    "local": {
      "path": "/root/.affine/storage"
    }
  }
}
```

- **provider**: Storage backend (local)
- **path**: Local storage directory

##### Feature Flags
```json
{
  "copilot": {
    "enabled": false
  },
  "features": {
    "earlyAccess": false
  }
}
```

- **copilot.enabled**: AI copilot feature
- **features.earlyAccess**: Early access features

---

## Docker Services

### `docker-compose.yml`

Multi-service Docker configuration for ΛFFiNE deployment.

#### **Service: postgres**
**Image**: `ankane/pgvector:latest`  
**Purpose**: PostgreSQL database with vector extension  
**Ports**: Internal only (5432)  
**Volumes**: `./data/postgres:/var/lib/postgresql/data`  
**Health Check**: `pg_isready -U affine`  

**Environment Variables**:
- `POSTGRES_USER`: affine
- `POSTGRES_PASSWORD`: affinepass (configurable)
- `POSTGRES_DB`: affine

#### **Service: redis**
**Image**: `redis:7`  
**Purpose**: Redis cache and session storage  
**Ports**: Internal only (6379)  
**Volumes**: `./data/redis:/data`  
**Health Check**: `redis-cli ping`  

#### **Service: affine_migration**
**Image**: `ghcr.io/toeverything/affine:stable`  
**Purpose**: Database migration and initialization  
**Command**: `node ./scripts/self-host-predeploy.js`  
**Dependencies**: postgres (healthy), redis (healthy)  
**Volumes**: 
- `./data/affine:/root/.affine/storage`
- `./config:/root/.affine/config`

**Environment Variables**:
- `REDIS_SERVER_HOST`: redis
- `DATABASE_URL`: PostgreSQL connection string

#### **Service: affine**
**Image**: `ghcr.io/toeverything/affine:stable`  
**Purpose**: Main ΛFFiNE application  
**Ports**: `80:3010` (HTTP access)  
**Dependencies**: affine_migration (completed)  
**Volumes**: 
- `./data/affine:/root/.affine/storage`
- `./config:/root/.affine/config`

**Environment Variables**:
- `NODE_ENV`: production
- `AFFINE_CONFIG_PATH`: /root/.affine/config
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_SERVER_HOST`: redis
- `REDIS_SERVER_PORT`: 6379

**Health Check**: `curl -f http://localhost:3010/`

---

## Usage Examples

### Complete Deployment
```bash
# Download and run deployment
curl -s https://raw.githubusercontent.com/Lu-aer/affine-deploy/main/deploy.sh | sudo bash
```

### Manual Deployment Steps
```bash
# 1. Clone repository
git clone https://github.com/Lu-aer/affine-deploy.git
cd affine-deploy

# 2. Run deployment
sudo ./deploy.sh

# 3. Setup SSL (optional)
./ssl-setup.sh your-domain.com

# 4. Manual backup
./backup.sh

# 5. Upgrade services
./upgrade.sh
```

### Docker Management
```bash
# View service status
docker compose ps

# View logs
docker compose logs -f

# Restart services
docker compose restart

# Stop services
docker compose down

# Start services
docker compose up -d
```

### Backup and Restore
```bash
# Create backup
./backup.sh

# Restore database (example)
docker exec -i affine-postgres psql -U affine affine < backup_file.sql

# Restore storage
tar -xzf backup_file_storage.tar.gz -C /opt/affine/
```

---

## Troubleshooting

### Common Issues

#### **Service Won't Start**
```bash
# Check logs
docker compose logs affine

# Verify dependencies
docker compose ps

# Check disk space
df -h /opt/affine/
```

#### **Database Connection Issues**
```bash
# Test database connectivity
docker exec affine-postgres pg_isready -U affine

# Check database logs
docker compose logs postgres
```

#### **Port Already in Use**
```bash
# Check port usage
netstat -tlnp | grep :80

# Kill process using port
sudo fuser -k 80/tcp
```

#### **SSL Certificate Issues**
```bash
# Check Nginx configuration
nginx -t

# View certbot logs
journalctl -u certbot

# Manual certificate renewal
certbot renew --dry-run
```

### Health Checks

#### **Service Health**
```bash
# Check all services
docker compose ps

# Individual service health
docker inspect affine-app --format='{{.State.Health.Status}}'
```

#### **Database Health**
```bash
# PostgreSQL
docker exec affine-postgres pg_isready -U affine

# Redis
docker exec affine-redis redis-cli ping
```

#### **Application Health**
```bash
# HTTP response
curl -f http://localhost:3010/

# Check logs
docker compose logs -f affine
```

### Performance Monitoring

#### **Resource Usage**
```bash
# Container resource usage
docker stats

# Disk usage
du -sh /opt/affine/data/*

# Memory usage
free -h
```

#### **Log Analysis**
```bash
# Real-time logs
docker compose logs -f

# Search logs
docker compose logs | grep ERROR

# Export logs
docker compose logs > affine-logs.txt
```

---

## Security Considerations

### **Network Security**
- Firewall blocks all incoming connections by default
- Only SSH, HTTP, and HTTPS ports are open
- fail2ban protects against brute force attacks

### **Application Security**
- Services run in isolated containers
- No root access to application containers
- Secure file permissions (777 for data directories)

### **Data Security**
- Regular automated backups
- Encrypted data in transit (with SSL)
- Local storage (no external cloud dependencies)

### **Access Control**
- SSH key authentication required
- Root login disabled
- Automatic security updates enabled

---

## Maintenance

### **Regular Tasks**
- Monitor backup success (daily)
- Check service health (weekly)
- Review security logs (weekly)
- Update system packages (monthly)

### **Backup Verification**
```bash
# Test backup restoration
./backup.sh
# Verify backup files exist and are readable
ls -la /opt/affine/backups/
```

### **Performance Optimization**
- Monitor resource usage
- Adjust Docker resource limits if needed
- Optimize PostgreSQL settings for your workload
- Consider Redis persistence settings

---

## Support and Resources

### **Official Documentation**
- [ΛFFiNE Documentation](https://affine.pro/docs)
- [Docker Documentation](https://docs.docker.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

### **Community Support**
- [ΛFFiNE GitHub](https://github.com/toeverything/AFFiNE)
- [Docker Community](https://forums.docker.com/)

### **Monitoring Tools**
- Built-in health checks
- Docker Compose status
- System resource monitoring
- Log analysis tools

---

*This documentation covers all public APIs, functions, and components of the ΛFFiNE VPS deployment project. For additional support or feature requests, please refer to the project repository.*