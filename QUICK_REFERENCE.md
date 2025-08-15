# ΛFFiNE VPS Deployment - Quick Reference

## 🚀 One-Command Deployment

```bash
curl -s https://raw.githubusercontent.com/Lu-aer/affine-deploy/main/deploy.sh | sudo bash
```

## 📋 Essential Commands

### Service Management
```bash
# View status
docker compose ps

# Start services
docker compose up -d

# Stop services
docker compose down

# Restart services
docker compose restart

# View logs
docker compose logs -f
```

### Backup Operations
```bash
# Manual backup
./backup.sh

# Check backup directory
ls -la /opt/affine/backups/

# Verify backup size
du -sh /opt/affine/backups/*
```

### Security & SSL
```bash
# Run security hardening
./security.sh

# Setup SSL certificate
./ssl-setup.sh your-domain.com

# Check firewall status
ufw status
```

### System Maintenance
```bash
# Upgrade services
./upgrade.sh

# Update system packages
apt update && apt upgrade -y

# Check disk usage
df -h /opt/affine/
```

## 🔧 Configuration Quick Reference

### Environment Variables
```bash
# PostgreSQL password (set before deployment)
export POSTGRES_PASSWORD=your_secure_password

# Or edit docker-compose.yml directly
```

### Port Configuration
- **HTTP**: 80 → 3010 (external → internal)
- **PostgreSQL**: 5432 (internal only)
- **Redis**: 6379 (internal only)

### File Locations
- **Data**: `/opt/affine/data/`
- **Config**: `/opt/affine/config/`
- **Backups**: `/opt/affine/backups/`
- **Logs**: `docker compose logs`

## 🚨 Emergency Commands

### Service Recovery
```bash
# Force restart all services
docker compose down && docker compose up -d

# Check service health
docker inspect affine-app --format='{{.State.Health.Status}}'
```

### Database Issues
```bash
# Test database connection
docker exec affine-postgres pg_isready -U affine

# Check database logs
docker compose logs postgres
```

### Port Conflicts
```bash
# Check what's using port 80
netstat -tlnp | grep :80

# Kill process on port 80
sudo fuser -k 80/tcp
```

## 📊 Monitoring Commands

### Resource Usage
```bash
# Container stats
docker stats

# System resources
free -h && df -h

# Process monitoring
htop
```

### Health Checks
```bash
# All services
docker compose ps

# Individual service
docker inspect affine-app --format='{{.State.Health.Status}}'

# Application endpoint
curl -f http://localhost:3010/
```

## 🔐 Security Checklist

- [ ] SSH key authentication configured
- [ ] Firewall enabled (UFW)
- [ ] fail2ban running
- [ ] Automatic updates enabled
- [ ] SSL certificate installed (optional)
- [ ] Regular backups running

## 📝 Common Tasks

### Add New Domain
```bash
./ssl-setup.sh new-domain.com
```

### Change Database Password
```bash
# Edit docker-compose.yml
# Update POSTGRES_PASSWORD
# Restart services
docker compose down && docker compose up -d
```

### Manual Backup
```bash
./backup.sh
# Backup stored in /opt/affine/backups/
```

### View Recent Logs
```bash
# Last 100 lines
docker compose logs --tail=100

# Follow logs in real-time
docker compose logs -f
```

## 🆘 Troubleshooting Quick Fixes

| Issue | Quick Fix |
|-------|-----------|
| Service won't start | `docker compose down && docker compose up -d` |
| Can't access web UI | Check port 80, verify firewall rules |
| Database errors | `docker compose logs postgres` |
| High memory usage | `docker stats` to identify container |
| Backup failures | Check disk space, verify permissions |

## 📞 Support Commands

```bash
# System information
uname -a && lsb_release -a

# Docker version
docker --version && docker compose version

# Service status
systemctl status docker

# Network configuration
ip addr show && netstat -tlnp
```

---

**Need more details?** See the full [API Documentation](API_DOCUMENTATION.md)