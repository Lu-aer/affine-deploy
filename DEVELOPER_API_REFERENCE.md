# ΛFFiNE VPS Deployment - Developer API Reference

## Overview

This document provides detailed technical information for developers working with the ΛFFiNE VPS deployment project. It covers internal functions, data structures, development patterns, and extension points.

## Table of Contents

1. [Script Architecture](#script-architecture)
2. [Function Reference](#function-reference)
3. [Data Structures](#data-structures)
4. [Error Handling](#error-handling)
5. [Logging and Output](#logging-and-output)
6. [Configuration Management](#configuration-management)
7. [Docker Integration](#docker-integration)
8. [Security Implementation](#security-implementation)
9. [Testing and Validation](#testing-and-validation)
10. [Extension Points](#extension-points)

---

## Script Architecture

### Design Patterns

The project follows a modular shell script architecture with these principles:

- **Single Responsibility**: Each script handles one specific domain
- **Error Handling**: Comprehensive error checking and graceful failures
- **Idempotency**: Scripts can be run multiple times safely
- **Configuration Driven**: External configuration files for customization
- **Health Checks**: Built-in monitoring and validation

### Script Dependencies

```
deploy.sh (main orchestrator)
├── security.sh (security hardening)
├── backup.sh (backup management)
├── ssl-setup.sh (SSL configuration)
├── upgrade.sh (system upgrades)
├── docker-compose.yml (service definition)
└── config.json (application config)
```

### Execution Flow

1. **Initialization**: Check prerequisites and environment
2. **System Setup**: Update packages and install dependencies
3. **Infrastructure**: Create directories and download configs
4. **Security**: Apply hardening and firewall rules
5. **Deployment**: Launch Docker services
6. **Validation**: Health checks and status verification
7. **Automation**: Setup cron jobs and monitoring

---

## Function Reference

### Core Functions

#### **deploy.sh Functions**

##### `check_root_privileges()`
```bash
# Purpose: Verify script has root access
# Implementation: Check EUID environment variable
# Exit: 1 if not root, continues if root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi
```

##### `update_system()`
```bash
# Purpose: Update system and install Docker
# Dependencies: apt package manager
# Actions: Update packages, add Docker repository, install Docker
apt update && apt upgrade -y
# Docker installation steps...
```

##### `setup_directory_structure()`
```bash
# Purpose: Create deployment directory structure
# Path: /opt/affine/
# Structure:
# ├── config/
# ├── data/
# │   ├── postgres/
# │   ├── redis/
# │   └── affine/
# └── backups/
mkdir -p /opt/affine/{config,data/{postgres,redis,affine}}
```

##### `apply_security()`
```bash
# Purpose: Execute security hardening
# Method: Execute security.sh script
# Permissions: Requires root access
./security.sh
```

##### `start_services()`
```bash
# Purpose: Launch Docker services
# Method: docker compose up -d
# Health Check: 30 second wait + status verification
docker compose up -d
sleep 30
docker compose ps
```

##### `setup_backups()`
```bash
# Purpose: Configure automated backups
# Method: Add cron job for daily execution
# Schedule: 2:00 AM daily
# Retention: 7 days (configured in backup.sh)
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/affine/backup.sh") | crontab -
```

#### **backup.sh Functions**

##### `create_backup()`
```bash
# Purpose: Orchestrate complete backup process
# Components: Database, Storage, Configuration
# Output: Timestamped backup files
# Cleanup: Automatic old backup removal
```

##### `backup_database()`
```bash
# Purpose: Export PostgreSQL database
# Method: pg_dump via Docker exec
# Format: SQL dump file
# Command: docker exec affine-postgres pg_dump -U affine affine
```

##### `backup_storage()`
```bash
# Purpose: Archive storage files
# Method: tar with gzip compression
# Path: /opt/affine/data/affine
# Format: .tar.gz archive
```

##### `backup_config()`
```bash
# Purpose: Copy configuration files
# Method: recursive copy
# Source: /opt/affine/config
# Destination: backup directory
```

##### `cleanup_old_backups()`
```bash
# Purpose: Remove old backups
# Retention: 7 days
# Method: find command with mtime filter
# Safety: 2>/dev/null to suppress errors
```

#### **security.sh Functions**

##### `install_firewall()`
```bash
# Purpose: Install UFW firewall
# Package: ufw
# Method: apt install
# Status: Enabled by default
```

##### `configure_firewall_rules()`
```bash
# Purpose: Set firewall policies
# Default: Deny incoming, allow outgoing
# Allowed: SSH (22), HTTP (80), HTTPS (443)
# Method: ufw commands
```

##### `install_fail2ban()`
```bash
# Purpose: Install intrusion prevention
# Package: fail2ban
# Configuration: Custom jail.local
# SSH Protection: 3 retries, 1 hour ban
```

##### `harden_ssh()`
```bash
# Purpose: Secure SSH configuration
# Changes: Disable password auth, disable root login
# Method: sed replacement in sshd_config
# Restart: SSH service restart required
```

##### `setup_auto_updates()`
```bash
# Purpose: Enable automatic security updates
# Package: unattended-upgrades
# Configuration: No automatic reboots
# Method: apt configuration file
```

#### **ssl-setup.sh Functions**

##### `setup_ssl(domain)`
```bash
# Purpose: Complete SSL setup for domain
# Parameter: domain - Domain name for certificate
# Dependencies: certbot, nginx
# Output: HTTPS-enabled site
```

##### `install_certbot()`
```bash
# Purpose: Install SSL certificate tools
# Packages: certbot, python3-certbot-nginx, nginx
# Method: apt install
# Verification: nginx configuration test
```

##### `create_nginx_config(domain)`
```bash
# Purpose: Generate Nginx configuration
# Template: Embedded here-document
# Features: Proxy pass to localhost:80
# Headers: Real IP, forwarded headers
```

##### `obtain_certificate(domain)`
```bash
# Purpose: Request Let's Encrypt certificate
# Method: certbot --nginx
# Options: Non-interactive, agree to terms
# Email: admin@domain (configurable)
```

#### **upgrade.sh Functions**

##### `upgrade_services()`
```bash
# Purpose: Upgrade all services to latest versions
# Safety: Pre-upgrade backup
# Method: Docker image pull and restart
# Validation: Health checks after upgrade
```

##### `create_pre_upgrade_backup()`
```bash
# Purpose: Safety backup before upgrade
# Method: Execute backup.sh
# Timing: Before any changes
# Rollback: Available if upgrade fails
```

##### `pull_latest_images()`
```bash
# Purpose: Download latest Docker images
# Method: docker compose pull
# Images: All services (postgres, redis, affine)
# Verification: Image availability check
```

##### `restart_services()`
```bash
# Purpose: Restart with new images
# Method: docker compose down && up -d
# Health Check: 30 second wait
# Status: Final status display
```

---

## Data Structures

### Configuration Schema

#### **config.json Structure**
```json
{
  "$schema": "https://raw.githubusercontent.com/toeverything/AFFiNE/master/packages/config/src/config.schema.json",
  "server": {
    "name": "string",
    "path": "string",
    "host": "string",
    "port": "number"
  },
  "database": {
    "url": "string"
  },
  "redis": {
    "host": "string",
    "port": "number"
  },
  "storage": {
    "provider": "string",
    "local": {
      "path": "string"
    }
  },
  "copilot": {
    "enabled": "boolean"
  },
  "features": {
    "earlyAccess": "boolean"
  }
}
```

#### **Environment Variables**
```bash
# Docker Compose Environment
POSTGRES_PASSWORD=affinepass  # Default, configurable
NODE_ENV=production
AFFINE_CONFIG_PATH=/root/.affine/config
DATABASE_URL=postgres://affine:affinepass@postgres:5432/affine
REDIS_SERVER_HOST=redis
REDIS_SERVER_PORT=6379
```

### Directory Structure
```
/opt/affine/
├── config/
│   └── config.json
├── data/
│   ├── postgres/          # PostgreSQL data
│   ├── redis/             # Redis data
│   └── affine/            # AFFiNE storage
├── backups/               # Backup files
│   ├── affine_backup_YYYYMMDD_HHMMSS_database.sql
│   ├── affine_backup_YYYYMMDD_HHMMSS_storage.tar.gz
│   └── affine_backup_YYYYMMDD_HHMMSS_config/
├── docker-compose.yml
├── backup.sh
├── security.sh
├── ssl-setup.sh
└── upgrade.sh
```

### Backup Naming Convention
```
affine_backup_YYYYMMDD_HHMMSS_[type]
Examples:
- affine_backup_20241201_143022_database.sql
- affine_backup_20241201_143022_storage.tar.gz
- affine_backup_20241201_143022_config/
```

---

## Error Handling

### Error Categories

#### **Fatal Errors (Exit 1)**
- Insufficient privileges
- Missing dependencies
- Port conflicts
- Service startup failures

#### **Recoverable Errors (Continue)**
- Package installation retries
- Service health check failures
- Backup creation issues

#### **Warning Errors (Log and Continue)**
- Old backup cleanup failures
- Non-critical service warnings

### Error Handling Patterns

#### **Privilege Check**
```bash
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi
```

#### **Command Execution Check**
```bash
# Method 1: set -e (script exits on any error)
set -e

# Method 2: Explicit error checking
if ! command; then
    echo "Error: command failed"
    exit 1
fi

# Method 3: Error suppression with fallback
command 2>/dev/null || echo "Warning: command failed"
```

#### **Service Health Validation**
```bash
# Wait for service to be ready
sleep 30

# Check service status
if ! docker compose ps | grep -q "Up"; then
    echo "Error: Services not running"
    exit 1
fi
```

### Recovery Mechanisms

#### **Automatic Retry**
```bash
# Package installation with retry
for i in {1..3}; do
    if apt install -y package; then
        break
    fi
    echo "Retry $i/3..."
    sleep 5
done
```

#### **Rollback Capability**
```bash
# Pre-upgrade backup
./backup.sh

# If upgrade fails, restore from backup
if ! upgrade_successful; then
    echo "Upgrade failed, restoring from backup..."
    restore_from_backup
fi
```

---

## Logging and Output

### Output Formatting

#### **Color Codes**
```bash
RED='\033[0;31m'      # Error messages
GREEN='\033[0;32m'    # Success messages
BLUE='\033[0;34m'     # Information messages
YELLOW='\033[1;33m'   # Warning messages
NC='\033[0m'          # No color (reset)
```

#### **Message Types**
```bash
# Information
echo -e "${BLUE}📦 Installing packages...${NC}"

# Success
echo -e "${GREEN}✅ Installation completed!${NC}"

# Warning
echo -e "${YELLOW}⚠️  Note: Password auth disabled${NC}"

# Error
echo -e "${RED}❌ Installation failed${NC}"
```

#### **Progress Indicators**
```bash
# Emoji-based status
echo "🚀 Starting deployment..."
echo "📦 Installing packages..."
echo "🔒 Applying security..."
echo "✅ Deployment completed!"
```

### Log Levels

#### **Verbose Output**
```bash
# Enable verbose mode
VERBOSE=true

if [[ "$VERBOSE" == "true" ]]; then
    echo "Debug: Executing command: $COMMAND"
fi
```

#### **Quiet Mode**
```bash
# Suppress non-essential output
QUIET=true

if [[ "$QUIET" != "true" ]]; then
    echo "Processing..."
fi
```

### Log File Management

#### **Log Rotation**
```bash
# Keep last 7 days of logs
find /var/log/affine/ -name "*.log" -mtime +7 -delete

# Compress old logs
find /var/log/affine/ -name "*.log" -mtime +1 -exec gzip {} \;
```

#### **Log Aggregation**
```bash
# Combine all service logs
docker compose logs > /opt/affine/logs/combined.log

# Filter by service
docker compose logs affine > /opt/affine/logs/affine.log
```

---

## Configuration Management

### Configuration Sources

#### **Priority Order**
1. Environment variables
2. Command line arguments
3. Configuration files
4. Default values

#### **Environment Variable Override**
```bash
# Override default PostgreSQL password
export POSTGRES_PASSWORD=secure_password_123

# Override AFFiNE port
export AFFINE_PORT=8080
```

#### **Configuration Validation**
```bash
# Validate JSON configuration
if ! jq empty config.json 2>/dev/null; then
    echo "Error: Invalid JSON configuration"
    exit 1
fi

# Check required fields
required_fields=("server" "database" "redis")
for field in "${required_fields[@]}"; do
    if ! jq -e ".$field" config.json >/dev/null; then
        echo "Error: Missing required field: $field"
        exit 1
    fi
done
```

### Dynamic Configuration

#### **Template Processing**
```bash
# Generate configuration from template
cat > config.json << EOF
{
  "server": {
    "port": ${AFFINE_PORT:-3010}
  },
  "database": {
    "url": "postgres://affine:${POSTGRES_PASSWORD:-affinepass}@postgres:5432/affine"
  }
}
EOF
```

#### **Configuration Updates**
```bash
# Update configuration without restart
update_config() {
    local key=$1
    local value=$2
    
    jq ".$key = $value" config.json > config.json.tmp
    mv config.json.tmp config.json
    
    # Reload configuration
    docker compose exec affine kill -HUP 1
}
```

---

## Docker Integration

### Service Definition

#### **Service Dependencies**
```yaml
# Health check dependencies
depends_on:
  postgres:
    condition: service_healthy
  redis:
    condition: service_healthy
  affine_migration:
    condition: service_completed_successfully
```

#### **Health Check Configuration**
```yaml
# PostgreSQL health check
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U affine"]
  interval: 10s
  timeout: 5s
  retries: 5

# AFFiNE health check
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3010/"]
  interval: 30s
  timeout: 10s
  retries: 3
```

#### **Volume Management**
```yaml
# Persistent data storage
volumes:
  - ./data/postgres:/var/lib/postgresql/data
  - ./data/redis:/data
  - ./data/affine:/root/.affine/storage
  - ./config:/root/.affine/config
```

### Docker Commands Integration

#### **Service Management**
```bash
# Start specific service
docker compose up -d postgres

# Scale service
docker compose up -d --scale affine=2

# View service logs
docker compose logs -f affine
```

#### **Container Operations**
```bash
# Execute command in container
docker compose exec postgres psql -U affine -d affine

# Copy files from container
docker compose cp affine:/root/.affine/storage ./local-storage

# Inspect container
docker compose exec affine cat /proc/1/environ
```

### Resource Management

#### **Resource Limits**
```yaml
# Memory and CPU limits
deploy:
  resources:
    limits:
      memory: 1G
      cpus: '0.5'
    reservations:
      memory: 512M
      cpus: '0.25'
```

#### **Network Configuration**
```yaml
# Custom network
networks:
  affine-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

---

## Security Implementation

### Security Layers

#### **Network Security**
```bash
# Firewall configuration
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
```

#### **Application Security**
```bash
# Container isolation
# No root access to application containers
# Read-only filesystem where possible
# Minimal attack surface
```

#### **Access Control**
```bash
# SSH hardening
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
```

### Security Monitoring

#### **Intrusion Detection**
```bash
# fail2ban configuration
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
```

#### **Security Updates**
```bash
# Automatic security updates
apt install -y unattended-upgrades
echo 'Unattended-Upgrade::Automatic-Reboot "false";' > /etc/apt/apt.conf.d/50unattended-upgrades
```

### Security Validation

#### **Configuration Audit**
```bash
# Check open ports
netstat -tlnp

# Verify firewall rules
ufw status numbered

# Check service permissions
ls -la /opt/affine/
```

#### **Vulnerability Scanning**
```bash
# Check for known vulnerabilities
apt list --upgradable

# Security audit
apt audit

# Package integrity check
dpkg -V
```

---

## Testing and Validation

### Test Categories

#### **Unit Tests**
```bash
# Test individual functions
test_backup_creation() {
    ./backup.sh
    if [ -f "/opt/affine/backups/affine_backup_"*"_database.sql" ]; then
        echo "✅ Backup creation test passed"
    else
        echo "❌ Backup creation test failed"
        return 1
    fi
}
```

#### **Integration Tests**
```bash
# Test service interactions
test_service_communication() {
    # Test database connection
    if docker exec affine-postgres pg_isready -U affine; then
        echo "✅ Database connectivity test passed"
    else
        echo "❌ Database connectivity test failed"
        return 1
    fi
}
```

#### **End-to-End Tests**
```bash
# Test complete deployment
test_full_deployment() {
    # Deploy fresh instance
    ./deploy.sh
    
    # Verify all services are running
    if docker compose ps | grep -q "Up"; then
        echo "✅ Full deployment test passed"
    else
        echo "❌ Full deployment test failed"
        return 1
    fi
}
```

### Test Framework

#### **Test Runner**
```bash
#!/bin/bash
# test-runner.sh

# Test suite
tests=(
    "test_backup_creation"
    "test_service_communication"
    "test_full_deployment"
)

# Run tests
for test in "${tests[@]}"; do
    echo "Running $test..."
    if $test; then
        echo "✅ $test passed"
    else
        echo "❌ $test failed"
        exit 1
    fi
done
```

#### **Mock Testing**
```bash
# Mock Docker for testing
mock_docker() {
    case "$1" in
        "compose")
            case "$2" in
                "up")
                    echo "Mock: Starting services..."
                    ;;
                "ps")
                    echo "Mock: Service status"
                    ;;
            esac
            ;;
    esac
}

# Override docker command for testing
docker() { mock_docker "$@"; }
```

### Validation Scripts

#### **Health Check Validation**
```bash
# Comprehensive health check
validate_health() {
    local all_healthy=true
    
    # Check Docker services
    if ! docker compose ps | grep -q "Up"; then
        echo "❌ Docker services not healthy"
        all_healthy=false
    fi
    
    # Check database
    if ! docker exec affine-postgres pg_isready -U affine; then
        echo "❌ Database not healthy"
        all_healthy=false
    fi
    
    # Check application
    if ! curl -f http://localhost:3010/ >/dev/null 2>&1; then
        echo "❌ Application not healthy"
        all_healthy=false
    fi
    
    return $([ "$all_healthy" = true ] && echo 0 || echo 1)
}
```

#### **Configuration Validation**
```bash
# Validate all configuration files
validate_config() {
    local config_valid=true
    
    # Check JSON syntax
    if ! jq empty config.json 2>/dev/null; then
        echo "❌ Invalid config.json"
        config_valid=false
    fi
    
    # Check Docker Compose
    if ! docker compose config >/dev/null 2>&1; then
        echo "❌ Invalid docker-compose.yml"
        config_valid=false
    fi
    
    return $([ "$config_valid" = true ] && echo 0 || echo 1)
}
```

---

## Extension Points

### Plugin System

#### **Hook Points**
```bash
# Pre-deployment hooks
if [ -f "hooks/pre-deploy.sh" ]; then
    echo "Running pre-deployment hooks..."
    ./hooks/pre-deploy.sh
fi

# Post-deployment hooks
if [ -f "hooks/post-deploy.sh" ]; then
    echo "Running post-deployment hooks..."
    ./hooks/post-deploy.sh
fi
```

#### **Custom Scripts**
```bash
# Custom backup strategy
if [ -f "custom-backup.sh" ]; then
    echo "Using custom backup strategy..."
    ./custom-backup.sh
else
    echo "Using default backup strategy..."
    ./backup.sh
fi
```

### Configuration Extensions

#### **Environment-Specific Configs**
```bash
# Load environment-specific configuration
ENVIRONMENT=${ENVIRONMENT:-production}

if [ -f "config/config.${ENVIRONMENT}.json" ]; then
    echo "Loading ${ENVIRONMENT} configuration..."
    cp "config/config.${ENVIRONMENT}.json" config/config.json
fi
```

#### **Feature Flags**
```bash
# Enable/disable features
ENABLE_SSL=${ENABLE_SSL:-false}
ENABLE_MONITORING=${ENABLE_MONITORING:-true}
ENABLE_BACKUPS=${ENABLE_BACKUPS:-true}

if [ "$ENABLE_SSL" = "true" ]; then
    echo "SSL enabled, setting up certificates..."
    ./ssl-setup.sh "$DOMAIN"
fi
```

### Custom Services

#### **Additional Docker Services**
```yaml
# Add custom services to docker-compose.yml
  monitoring:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring:/etc/prometheus
    restart: unless-stopped
```

#### **Service Integration**
```bash
# Custom service startup
start_custom_services() {
    if [ "$ENABLE_MONITORING" = "true" ]; then
        echo "Starting monitoring services..."
        docker compose up -d monitoring
    fi
}
```

### API Extensions

#### **REST API Endpoints**
```bash
# Health check API
start_health_api() {
    cat > /opt/affine/health-api.py << 'EOF'
#!/usr/bin/env python3
from flask import Flask, jsonify
import subprocess

app = Flask(__name__)

@app.route('/health')
def health():
    result = subprocess.run(['docker', 'compose', 'ps'], 
                          capture_output=True, text=True)
    return jsonify({'status': 'healthy' if result.returncode == 0 else 'unhealthy'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF
    
    python3 /opt/affine/health-api.py &
}
```

#### **Webhook Integration**
```bash
# Webhook notifications
notify_webhook() {
    local event=$1
    local status=$2
    
    if [ -n "$WEBHOOK_URL" ]; then
        curl -X POST "$WEBHOOK_URL" \
             -H "Content-Type: application/json" \
             -d "{\"event\":\"$event\",\"status\":\"$status\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
    fi
}
```

---

## Development Workflow

### Local Development

#### **Development Environment Setup**
```bash
# Clone repository
git clone https://github.com/Lu-aer/affine-deploy.git
cd affine-deploy

# Create development branch
git checkout -b feature/new-feature

# Make changes and test
./test-runner.sh

# Commit changes
git add .
git commit -m "Add new feature"

# Push and create pull request
git push origin feature/new-feature
```

#### **Testing Locally**
```bash
# Use Docker for testing
docker run --rm -it -v $(pwd):/workspace ubuntu:20.04 bash

# Inside container
apt update && apt install -y bash curl
cd /workspace
./deploy.sh
```

### Continuous Integration

#### **CI Pipeline**
```yaml
# .github/workflows/test.yml
name: Test Suite
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Tests
        run: ./test-runner.sh
      - name: Validate Configuration
        run: ./validate-config.sh
```

#### **Automated Testing**
```bash
# Run tests on every commit
pre-commit:
  - ./test-runner.sh
  - ./validate-config.sh
  - shellcheck *.sh
```

### Code Quality

#### **Shell Script Linting**
```bash
# Install shellcheck
apt install -y shellcheck

# Lint all shell scripts
find . -name "*.sh" -exec shellcheck {} \;
```

#### **Code Formatting**
```bash
# Format shell scripts
shfmt -i 2 -ci -w *.sh

# Check formatting
shfmt -i 2 -ci -d *.sh
```

---

## Performance Optimization

### Resource Optimization

#### **Docker Resource Limits**
```yaml
# Optimize resource usage
deploy:
  resources:
    limits:
      memory: 512M
      cpus: '0.5'
    reservations:
      memory: 256M
      cpus: '0.25'
```

#### **Database Optimization**
```bash
# PostgreSQL tuning
cat > /opt/affine/postgresql.conf << EOF
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB
EOF
```

### Caching Strategies

#### **Redis Optimization**
```bash
# Redis persistence
cat > /opt/affine/redis.conf << EOF
save 900 1
save 300 10
save 60 10000
maxmemory 256mb
maxmemory-policy allkeys-lru
EOF
```

#### **Application Caching**
```bash
# Enable AFFiNE caching
cat >> config.json << EOF
  "cache": {
    "enabled": true,
    "ttl": 3600
  }
EOF
```

---

## Monitoring and Observability

### Metrics Collection

#### **System Metrics**
```bash
# Collect system metrics
collect_metrics() {
    echo "=== System Metrics ==="
    echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo "Disk: $(df -h /opt/affine | awk 'NR==2 {print $5}')"
}
```

#### **Application Metrics**
```bash
# AFFiNE application metrics
collect_app_metrics() {
    echo "=== Application Metrics ==="
    echo "Response Time: $(curl -w "%{time_total}" -o /dev/null -s http://localhost:3010/)"
    echo "Status Code: $(curl -o /dev/null -s -w "%{http_code}" http://localhost:3010/)"
}
```

### Log Aggregation

#### **Centralized Logging**
```bash
# Setup log aggregation
setup_logging() {
    # Install logrotate
    apt install -y logrotate
    
    # Configure log rotation
    cat > /etc/logrotate.d/affine << EOF
/opt/affine/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 affine affine
}
EOF
}
```

#### **Log Analysis**
```bash
# Analyze error patterns
analyze_logs() {
    echo "=== Error Analysis ==="
    docker compose logs | grep -i error | sort | uniq -c | sort -nr
}
```

---

## Security Best Practices

### Secure Defaults

#### **Principle of Least Privilege**
```bash
# Run services with minimal privileges
useradd -r -s /bin/false affine
chown -R affine:affine /opt/affine/data
```

#### **Secure Communication**
```bash
# Force HTTPS redirects
if [ "$ENABLE_SSL" = "true" ]; then
    cat >> /etc/nginx/sites-available/affine << EOF
    if (\$scheme != "https") {
        return 301 https://\$server_name\$request_uri;
    }
EOF
fi
```

### Regular Security Updates

#### **Automated Security Scanning**
```bash
# Security update automation
setup_security_updates() {
    # Install security tools
    apt install -y unattended-upgrades apt-listchanges
    
    # Configure automatic updates
    cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Mail "admin@example.com";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
EOF
}
```

---

*This developer API reference provides comprehensive technical information for extending and maintaining the ΛFFiNE VPS deployment project. For user-focused documentation, see the [API Documentation](API_DOCUMENTATION.md) and [Quick Reference](QUICK_REFERENCE.md).*