#!/bin/bash
# Deploy voiceawareness.biz from GitHub and restart the systemd service.
# Run on the server as root.

set -e

DOMAIN_ROOT=/var/www/vhosts/voiceawareness.biz
APP_DIR="$DOMAIN_ROOT/httpdocs"
NODE_BIN=/opt/plesk/node/24/bin
SERVICE=voiceawareness-biz
REPO=https://github.com/bhootinsk/voiceawareness.biz.git
BACKUP_DIR=/root/vab-cms-backup

echo "==> Backing up .env and CMS content"
cp "$APP_DIR/.env" /root/vab.env.bak 2>/dev/null || true
mkdir -p "$BACKUP_DIR"
rm -rf "$BACKUP_DIR/content" "$BACKUP_DIR/data"
[ -d "$APP_DIR/content" ] && cp -a "$APP_DIR/content" "$BACKUP_DIR/"
[ -d "$APP_DIR/data" ] && cp -a "$APP_DIR/data" "$BACKUP_DIR/"

echo "==> Fetching from GitHub"
rm -rf /tmp/vab-update
git clone "$REPO" /tmp/vab-update

echo "==> Syncing application code (CMS content/data on server are preserved)"
rsync -av /tmp/vab-update/ "$APP_DIR/" \
  --exclude .env \
  --exclude node_modules \
  --exclude uploads \
  --exclude content \
  --exclude data \
  --exclude .git

cp /root/vab.env.bak "$APP_DIR/.env" 2>/dev/null || true

echo "==> Updating deploy scripts"
rsync -av /tmp/vab-update/scripts/ "$DOMAIN_ROOT/scripts/"
chmod +x "$DOMAIN_ROOT/scripts/"*.sh

echo "==> Installing dependencies"
cd "$APP_DIR"
export PATH="$NODE_BIN:$PATH"
npm install --production

echo "==> Fixing permissions for CMS writes"
bash "$DOMAIN_ROOT/scripts/fix-cms-permissions.sh"

echo "==> Restarting service"
if systemctl is-enabled "$SERVICE" >/dev/null 2>&1; then
  systemctl restart "$SERVICE"
else
  echo "Service not installed yet. Run scripts/install-systemd.sh first."
  exit 1
fi

sleep 2
echo "==> Health check"
curl -sf http://127.0.0.1:3000/deploy-check
echo ""

CHECK=$(curl -sf http://127.0.0.1:3000/deploy-check || echo '{}')
if ! echo "$CHECK" | grep -q '"homeJson":true'; then
  echo "WARNING: content/ is not writable by the app. Re-running permission fix..."
  bash "$DOMAIN_ROOT/scripts/fix-cms-permissions.sh"
  systemctl restart "$SERVICE"
  sleep 2
  curl -sf http://127.0.0.1:3000/deploy-check
  echo ""
fi

echo "Done. https://www.voiceawareness.biz/"
echo "CMS content/data on the server were not changed."
