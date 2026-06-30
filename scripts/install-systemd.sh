#!/bin/bash
# One-time server setup: systemd service (do not use Plesk Node.js UI).
# Run on the server as root.
#
# Usage:
#   bash /var/www/vhosts/voiceawareness.biz/scripts/install-systemd.sh
#   bash /var/www/vhosts/voiceawareness.ca/scripts/install-systemd.sh voiceawareness.ca

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE="${1:-$(basename "$(dirname "$SCRIPT_DIR")")}"

# shellcheck source=lib/site-env.sh
source "$SCRIPT_DIR/lib/site-env.sh"
load_site_env "$SITE"

if [ ! -f "$SERVICE_FILE" ]; then
  echo "Service file not found at $SERVICE_FILE"
  exit 1
fi

if [ ! -x "$NODE_BIN/node" ]; then
  echo "Node not found at $NODE_BIN/node"
  ls /opt/plesk/node/*/bin/node 2>/dev/null || true
  exit 1
fi

if ! id "$APP_USER" &>/dev/null; then
  echo "App user not found: $APP_USER"
  echo "After creating the domain in Plesk, run:"
  echo "  stat -c '%U' $APP_DIR"
  echo "Then set APP_USER in $SCRIPT_DIR/config/${SITE_DOMAIN}.env"
  exit 1
fi

echo "==> Installing $SERVICE_NAME for $SITE_DOMAIN (port $APP_PORT)"
echo "==> Using $($NODE_BIN/node -v)"

echo "==> Installing npm dependencies"
cd "$APP_DIR"
export PATH="$NODE_BIN:$PATH"
npm install --production

echo "==> Fixing .env permissions for app user"
if [ -f "$APP_DIR/.env" ]; then
  chown "$APP_USER:$APP_GROUP" "$APP_DIR/.env"
  chmod 640 "$APP_DIR/.env"
fi

echo "==> Setting up CMS storage"
bash "$SCRIPT_DIR/setup-cms-storage.sh" "$SITE_DOMAIN"

TMP_SERVICE="/tmp/${SERVICE_NAME}.service"
sed \
  -e "s|^User=.*|User=$APP_USER|" \
  -e "s|^Group=.*|Group=$APP_GROUP|" \
  -e "s|^WorkingDirectory=.*|WorkingDirectory=$APP_DIR|" \
  -e "s|^Environment=PORT=.*|Environment=PORT=$APP_PORT|" \
  -e "s|^EnvironmentFile=.*|EnvironmentFile=-$APP_DIR/.env|" \
  "$SERVICE_FILE" > "$TMP_SERVICE"

cp "$TMP_SERVICE" "/etc/systemd/system/${SERVICE_NAME}.service"
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

sleep 2
systemctl status "$SERVICE_NAME" --no-pager || true
curl -sf "http://127.0.0.1:${APP_PORT}/deploy-check" && echo ""

echo ""
echo "Installed $SERVICE_NAME on port $APP_PORT"
echo "Disable Plesk Node.js for $SITE_DOMAIN (Apache proxy only)."
echo "Future deploys: bash $DOMAIN_ROOT/scripts/deploy.sh"
