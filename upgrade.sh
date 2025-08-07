#!/bin/bash

# ΛFFiNE Upgrade Script

echo "🔄 Upgrading AFFiNE to latest version..."

cd /opt/affine

# Create backup before upgrade
./backup.sh

# Pull latest images
docker compose pull

# Stop services
docker compose down

# Start with latest images
docker compose up -d

# Wait for services
sleep 30

# Check status
docker compose ps

echo "✅ Upgrade completed!"
echo "🔍 Check logs with: docker compose logs -f"
