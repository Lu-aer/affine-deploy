#!/bin/bash

# ΛFFiNE Backup Script
# Creates timestamped backups of database and storage

BACKUP_DIR="/opt/affine/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="affine_backup_${TIMESTAMP}"

# Create backup directory
mkdir -p ${BACKUP_DIR}

echo "🔄 Starting AFFiNE backup..."

# Database backup
echo "📊 Backing up PostgreSQL database..."
docker exec affine-postgres pg_dump -U affine affine > "${BACKUP_DIR}/${BACKUP_NAME}_database.sql"

# Storage backup
echo "📁 Backing up storage files..."
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}_storage.tar.gz" -C /opt/affine data/affine

# Config backup
echo "⚙️ Backing up configuration..."
cp -r /opt/affine/config "${BACKUP_DIR}/${BACKUP_NAME}_config"

# Clean old backups (keep last 7 days)
find ${BACKUP_DIR} -name "affine_backup_*" -type f -mtime +7 -delete 2>/dev/null || true

echo "✅ Backup completed: ${BACKUP_NAME}"
echo "📍 Location: ${BACKUP_DIR}"

# Display backup size
du -sh "${BACKUP_DIR}/${BACKUP_NAME}"*
