#!/bin/bash
# Full one-time server setup for voiceawareness.biz
# Usage (as root):
#   curl -fsSL https://raw.githubusercontent.com/bhootinsk/voiceawareness.biz/main/scripts/server-bootstrap.sh | bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE=voiceawareness.biz

# shellcheck source=lib/site-env.sh
source "$SCRIPT_DIR/lib/site-env.sh"
load_site_env "$SITE"

CLONE_DIR=/tmp/vab-bootstrap

echo "==> Backing up .env"
cp "$APP_DIR/.env" "$ENV_BACKUP" 2>/dev/null || true

echo "==> Cloning repository"
rm -rf "$CLONE_DIR"
git clone "$REPO_URL" "$CLONE_DIR"

echo "==> Syncing application files"
rsync -av "$CLONE_DIR/" "$APP_DIR/" \
  --exclude .env \
  --exclude node_modules \
  --exclude uploads \
  --exclude content \
  --exclude data \
  --exclude .git

if [ ! -f "$APP_DIR/content/home.json" ]; then
  echo "==> Seeding CMS content (first install)"
  rsync -av "$CLONE_DIR/content/" "$APP_DIR/content/"
  rsync -av "$CLONE_DIR/data/" "$APP_DIR/data/"
fi

cp "$ENV_BACKUP" "$APP_DIR/.env" 2>/dev/null || true

echo "==> Copying deploy scripts to domain root"
mkdir -p "$DOMAIN_ROOT/scripts"
rsync -av "$CLONE_DIR/scripts/" "$DOMAIN_ROOT/scripts/"
chmod +x "$DOMAIN_ROOT/scripts/"*.sh "$DOMAIN_ROOT/scripts/lib/"*.sh 2>/dev/null || true

echo "==> Stopping any manual node processes"
pkill -f "node app.js" 2>/dev/null || true
sleep 1

echo "==> Installing systemd service"
bash "$DOMAIN_ROOT/scripts/install-systemd.sh" "$SITE_DOMAIN"

echo "==> Reconfiguring Apache"
plesk sbin httpdmng --reconfigure-domain "$SITE_DOMAIN" 2>/dev/null || true

echo ""
echo "SUCCESS"
echo "  systemctl status $SERVICE_NAME"
echo "  curl -s http://127.0.0.1:${APP_PORT}/deploy-check"
echo "  $PUBLIC_URL/"
echo ""
echo "Future deploys: bash $DOMAIN_ROOT/scripts/deploy.sh"
