#!/bin/bash
# One-time server setup: systemd service + skip Plesk Node.js.
# Run on the server as root.

set -e

APP_DIR=/var/www/vhosts/voiceawareness.biz/httpdocs
NODE_BIN=/opt/plesk/node/24/bin
SERVICE=voiceawareness-biz
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -x "$NODE_BIN/node" ]; then
  echo "Node not found at $NODE_BIN/node"
  echo "Available:"
  ls /opt/plesk/node/*/bin/node 2>/dev/null || true
  exit 1
fi

echo "==> Using $($NODE_BIN/node -v)"

echo "==> Installing npm dependencies"
cd "$APP_DIR"
export PATH="$NODE_BIN:$PATH"
npm install --production

echo "==> Installing systemd unit"
cp "$SCRIPT_DIR/systemd/voiceawareness-biz.service" /etc/systemd/system/$SERVICE.service
systemctl daemon-reload
systemctl enable "$SERVICE"
systemctl restart "$SERVICE"

sleep 2
systemctl status "$SERVICE" --no-pager || true
curl -sf http://127.0.0.1:3000/deploy-check && echo ""

echo ""
echo "Installed. Disable Plesk Node.js for this domain (use Apache proxy only)."
echo "Future deploys: bash $SCRIPT_DIR/deploy.sh"
