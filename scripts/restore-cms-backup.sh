#!/bin/bash
# Restore CMS content from the last deploy backup (run as root on the server).
#
# Usage:
#   bash /var/www/vhosts/voiceawareness.biz/scripts/restore-cms-backup.sh

set -e

APP_DIR=/var/www/vhosts/voiceawareness.biz/httpdocs
BACKUP_DIR=/root/vab-cms-backup

if [ ! -d "$BACKUP_DIR/content" ] && [ ! -d "$BACKUP_DIR/data" ]; then
  echo "No backup found at $BACKUP_DIR"
  exit 1
fi

echo "==> Restoring CMS backup"
[ -d "$BACKUP_DIR/content" ] && rsync -av "$BACKUP_DIR/content/" "$APP_DIR/content/"
[ -d "$BACKUP_DIR/data" ] && rsync -av "$BACKUP_DIR/data/" "$APP_DIR/data/"

chown -R voiceawarenessbiz:psacln "$APP_DIR/content" "$APP_DIR/data"
chmod -R u+rwX "$APP_DIR/content" "$APP_DIR/data"

systemctl restart voiceawareness-biz
echo "Restored. Check https://www.voiceawareness.biz/"
