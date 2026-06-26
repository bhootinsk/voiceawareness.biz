#!/bin/bash
# Deploy voiceawareness.biz from GitHub and restart the systemd service.
# Run on the server as root.

set -e

DOMAIN_ROOT=/var/www/vhosts/voiceawareness.biz
APP_DIR="$DOMAIN_ROOT/httpdocs"
NODE_BIN=/opt/plesk/node/24/bin
SERVICE=voiceawareness-biz
REPO=https://github.com/bhootinsk/voiceawareness.biz.git

echo "==> Backing up .env"
cp "$APP_DIR/.env" /root/vab.env.bak 2>/dev/null || true

echo "==> Fetching from GitHub"
rm -rf /tmp/vab-update
git clone "$REPO" /tmp/vab-update

echo "==> Syncing files"
rsync -av /tmp/vab-update/ "$APP_DIR/" \
  --exclude .env \
  --exclude node_modules \
  --exclude uploads \
  --exclude .git

cp /root/vab.env.bak "$APP_DIR/.env" 2>/dev/null || true

echo "==> Installing dependencies"
cd "$APP_DIR"
export PATH="$NODE_BIN:$PATH"
npm install --production

echo "==> Fixing permissions for CMS writes"
chown -R voiceawarenessbiz:psacln "$APP_DIR/content" "$APP_DIR/data" "$APP_DIR/uploads"
chmod -R u+rwX "$APP_DIR/content" "$APP_DIR/data" "$APP_DIR/uploads"

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
echo "Done. https://www.voiceawareness.biz/"
