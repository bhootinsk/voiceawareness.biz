#!/bin/bash
# Full one-time server setup for voiceawareness.biz
# Usage (as root):
#   curl -fsSL https://raw.githubusercontent.com/bhootinsk/voiceawareness.biz/main/scripts/server-bootstrap.sh | bash

set -e

DOMAIN_ROOT=/var/www/vhosts/voiceawareness.biz
APP_DIR="$DOMAIN_ROOT/httpdocs"
REPO=https://github.com/bhootinsk/voiceawareness.biz.git
CLONE_DIR=/tmp/vab-bootstrap

echo "==> Backing up .env"
cp "$APP_DIR/.env" /root/vab.env.bak 2>/dev/null || true

echo "==> Cloning repository"
rm -rf "$CLONE_DIR"
git clone "$REPO" "$CLONE_DIR"

echo "==> Syncing application files"
rsync -av "$CLONE_DIR/" "$APP_DIR/" \
  --exclude .env \
  --exclude node_modules \
  --exclude uploads \
  --exclude .git

cp /root/vab.env.bak "$APP_DIR/.env" 2>/dev/null || true

echo "==> Copying deploy scripts to domain root"
mkdir -p "$DOMAIN_ROOT/scripts"
rsync -av "$CLONE_DIR/scripts/" "$DOMAIN_ROOT/scripts/"

echo "==> Stopping any manual node processes"
pkill -f "node app.js" 2>/dev/null || true
sleep 1

echo "==> Installing systemd service"
bash "$DOMAIN_ROOT/scripts/install-systemd.sh"

echo "==> Reconfiguring Apache"
plesk sbin httpdmng --reconfigure-domain voiceawareness.biz 2>/dev/null || true

echo ""
echo "SUCCESS"
echo "  systemctl status voiceawareness-biz"
echo "  curl -s http://127.0.0.1:3000/deploy-check"
echo "  https://www.voiceawareness.biz/"
echo ""
echo "Future deploys: bash $DOMAIN_ROOT/scripts/deploy.sh"
