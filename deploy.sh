#!/bin/bash
set -e

# ΛFFiNE VPS Deployment Script
# One-command deployment for complete AFFiNE self-hosted instance

echo "🚀 Starting ΛFFiNE VPS Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Update system
echo -e "${BLUE}📦 Updating system packages...${NC}"
apt update && apt upgrade -y

# Install Docker
echo -e "${BLUE}🐳 Installing Docker and Docker Compose...${NC}"
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Create AFFiNE directory structure
echo -e "${BLUE}📁 Creating directory structure...${NC}"
mkdir -p /opt/affine/{config,data/{postgres,redis,affine}}
cd /opt/affine

# Download configuration files
echo -e "${BLUE}📥 Downloading AFFiNE configuration...${NC}"
curl -sO https://raw.githubusercontent.com/Lu-aer/affine-deploy/main/docker-compose.yml
curl -sO https://raw.githubusercontent.com/Lu-aer/affine-deploy/main/config.json
curl -sO https://raw.githubusercontent.com/Lu-aer/affine-deploy/main/backup.sh
curl -sO https://raw.githubusercontent.com/Lu-aer/affine-deploy/main/security.sh

# Move config file to correct location
mv config.json config/

# Make scripts executable
chmod +x backup.sh security.sh

# Set proper permissions
chmod -R 777 /opt/affine/data /opt/affine/config

# Run security hardening
echo -e "${BLUE}🔒 Applying security configuration...${NC}"
./security.sh

# Start AFFiNE services
echo -e "${BLUE}🚀 Starting AFFiNE services...${NC}"
docker compose up -d

# Wait for services to be healthy
echo -e "${BLUE}⏳ Waiting for services to initialize...${NC}"
sleep 30

# Check service status
echo -e "${BLUE}🔍 Checking service status...${NC}"
docker compose ps

# Setup automated backups
echo -e "${BLUE}💾 Setting up automated backups...${NC}"
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/affine/backup.sh") | crontab -

# Get server IP
SERVER_IP=$(curl -s ifconfig.me)

# Success message
echo -e "${GREEN}✅ ΛFFiNE deployment completed successfully!${NC}"
echo ""
echo -e "${GREEN}🌐 Access your AFFiNE instance at:${NC}"
echo -e "${YELLOW}   http://${SERVER_IP}${NC}"
echo ""
echo -e "${GREEN}📋 Important Information:${NC}"
echo "   • Data location: /opt/affine/data/"
echo "   • Config location: /opt/affine/config/"
echo "   • Backups: Daily at 2 AM (stored in /opt/affine/)"
echo "   • View logs: docker compose logs -f"
echo "   • Restart services: docker compose restart"
echo ""
echo -e "${BLUE}🔐 Next steps:${NC}"
echo "   1. Visit the URL above to create your admin account"
echo "   2. Consider setting up a domain name and SSL certificate"
echo "   3. Test backup/restore process"
echo ""
echo -e "${GREEN}🎉 Your ΛFFiNE PKOS is ready for use!${NC}"
