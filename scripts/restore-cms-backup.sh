#!/bin/bash
# Restore CMS content from the last deploy backup (run as root on the server).
#
# Usage:
#   bash /var/www/vhosts/voiceawareness.biz/scripts/restore-cms-backup.sh
#   bash /var/www/vhosts/voiceawareness.ca/scripts/restore-cms-backup.sh voiceawareness.ca

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE="${1:-$(basename "$(dirname "$SCRIPT_DIR")")}"

# shellcheck source=lib/site-env.sh
source "$SCRIPT_DIR/lib/site-env.sh"
load_site_env "$SITE"

if [ ! -d "$BACKUP_DIR/content" ] && [ ! -d "$BACKUP_DIR/data" ] && [ ! -d "$BACKUP_DIR/private-cms" ]; then
  echo "No backup found at $BACKUP_DIR"
  exit 1
fi

echo "==> Restoring CMS backup for $SITE_DOMAIN"

if [ -d "$BACKUP_DIR/private-cms" ]; then
  rsync -av "$BACKUP_DIR/private-cms/" "$DOMAIN_ROOT/private/cms/"
  chown -R "$APP_USER:$APP_GROUP" "$DOMAIN_ROOT/private/cms"
elif [ -d "$BACKUP_DIR/content" ]; then
  [ -d "$BACKUP_DIR/content" ] && rsync -av "$BACKUP_DIR/content/" "$APP_DIR/content/"
  [ -d "$BACKUP_DIR/data" ] && rsync -av "$BACKUP_DIR/data/" "$APP_DIR/data/"
  chown -R "$APP_USER:$APP_GROUP" "$APP_DIR/content" "$APP_DIR/data"
fi

systemctl restart "$SERVICE_NAME"
echo "Restored. Check $PUBLIC_URL/"
