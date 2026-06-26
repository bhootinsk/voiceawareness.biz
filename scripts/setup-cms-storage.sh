#!/bin/bash
# Move CMS storage to a writable private folder (outside httpdocs).
# Plesk often leaves httpdocs/content owned by root; this fixes admin saves permanently.
#
# Usage (as root on the server):
#   bash /var/www/vhosts/voiceawareness.biz/scripts/setup-cms-storage.sh

set -e

DOMAIN_ROOT=/var/www/vhosts/voiceawareness.biz
APP_DIR="$DOMAIN_ROOT/httpdocs"
PRIVATE_ROOT="$DOMAIN_ROOT/private/cms"
CONTENT_DIR="$PRIVATE_ROOT/content"
DATA_DIR="$PRIVATE_ROOT/data"
ENV_FILE="$APP_DIR/.env"
SERVICE_FILE=/etc/systemd/system/voiceawareness-biz.service

APP_USER=voiceawarenessbiz
APP_GROUP=psacln

if [ -f "$SERVICE_FILE" ]; then
  APP_USER=$(grep '^User=' "$SERVICE_FILE" | cut -d= -f2 | tr -d ' ' || echo "$APP_USER")
  APP_GROUP=$(grep '^Group=' "$SERVICE_FILE" | cut -d= -f2 | tr -d ' ' || echo "$APP_GROUP")
fi

if ! id "$APP_USER" &>/dev/null; then
  echo "App user not found: $APP_USER"
  exit 1
fi

echo "==> CMS storage for $APP_USER:$APP_GROUP"
mkdir -p "$CONTENT_DIR/pages" "$DATA_DIR"

if [ ! -f "$CONTENT_DIR/home.json" ]; then
  if [ -f "$APP_DIR/content/home.json" ]; then
    echo "==> Migrating content/ from httpdocs"
    rsync -a "$APP_DIR/content/" "$CONTENT_DIR/"
  fi
  if [ -f "$APP_DIR/data/site.json" ]; then
    echo "==> Migrating data/ from httpdocs"
    rsync -a "$APP_DIR/data/" "$DATA_DIR/"
  fi
fi

chattr -R -i "$PRIVATE_ROOT" "$APP_DIR/content" "$APP_DIR/data" 2>/dev/null || true

chown -R "$APP_USER:$APP_GROUP" "$PRIVATE_ROOT" "$APP_DIR/content" "$APP_DIR/data" "$APP_DIR/uploads"
find "$PRIVATE_ROOT" "$APP_DIR/content" "$APP_DIR/data" "$APP_DIR/uploads" -type d -exec chmod u+rwx {} + 2>/dev/null || true
find "$PRIVATE_ROOT" "$APP_DIR/content" "$APP_DIR/data" "$APP_DIR/uploads" -type f -exec chmod u+rw {} + 2>/dev/null || true

set_env_var() {
  local key="$1"
  local value="$2"
  if [ ! -f "$ENV_FILE" ]; then
    touch "$ENV_FILE"
  fi
  if grep -q "^${key}=" "$ENV_FILE"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
  else
    printf '\n%s=%s\n' "$key" "$value" >> "$ENV_FILE"
  fi
}

set_env_var CONTENT_DIR "$CONTENT_DIR"
set_env_var DATA_DIR "$DATA_DIR"

chown "$APP_USER:$APP_GROUP" "$ENV_FILE"
chmod 640 "$ENV_FILE"

echo "==> Updated $ENV_FILE"
echo "    CONTENT_DIR=$CONTENT_DIR"
echo "    DATA_DIR=$DATA_DIR"
echo ""
echo "Restart the app:"
echo "  systemctl restart voiceawareness-biz"
echo "Then check:"
echo "  curl -s http://127.0.0.1:3000/deploy-check"
