#!/bin/bash
# Move CMS storage to a writable private folder (outside httpdocs).
#
# Usage (as root on the server):
#   bash /var/www/vhosts/voiceawareness.biz/scripts/setup-cms-storage.sh
#   bash /var/www/vhosts/voiceawareness.biz/scripts/setup-cms-storage.sh voiceawareness.ca

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE="${1:-$(basename "$(dirname "$SCRIPT_DIR")")}"

# shellcheck source=lib/site-env.sh
source "$SCRIPT_DIR/lib/site-env.sh"
load_site_env "$SITE"

PRIVATE_ROOT="$DOMAIN_ROOT/private/cms"
CONTENT_DIR="$PRIVATE_ROOT/content"
DATA_DIR="$PRIVATE_ROOT/data"
ENV_FILE="$APP_DIR/.env"
INSTALLED_SERVICE="/etc/systemd/system/${SERVICE_NAME}.service"

if [ -f "$INSTALLED_SERVICE" ]; then
  APP_USER=$(grep '^User=' "$INSTALLED_SERVICE" | cut -d= -f2 | tr -d ' ' || echo "$APP_USER")
  APP_GROUP=$(grep '^Group=' "$INSTALLED_SERVICE" | cut -d= -f2 | tr -d ' ' || echo "$APP_GROUP")
fi

if ! id "$APP_USER" &>/dev/null; then
  echo "App user not found: $APP_USER"
  echo "Update APP_USER in $SCRIPT_DIR/config/${SITE_DOMAIN}.env"
  echo "Or detect from: stat -c '%U' $APP_DIR"
  exit 1
fi

echo "==> CMS storage for $SITE_DOMAIN ($APP_USER:$APP_GROUP)"
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
set_env_var PORT "$APP_PORT"

chown "$APP_USER:$APP_GROUP" "$ENV_FILE"
chmod 640 "$ENV_FILE"

echo "==> Updated $ENV_FILE"
echo "    CONTENT_DIR=$CONTENT_DIR"
echo "    DATA_DIR=$DATA_DIR"
echo "    PORT=$APP_PORT"
echo ""
echo "Restart the app:"
echo "  systemctl restart $SERVICE_NAME"
