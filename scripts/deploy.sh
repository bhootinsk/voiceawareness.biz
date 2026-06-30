#!/bin/bash
# Deploy a Voice Awareness site from GitHub and restart its systemd service.
# Run on the server as root.
#
# Usage:
#   bash /var/www/vhosts/voiceawareness.biz/scripts/deploy.sh
#   bash /var/www/vhosts/voiceawareness.ca/scripts/deploy.sh
#   bash scripts/deploy.sh voiceawareness.ca

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE="${1:-$(basename "$(dirname "$SCRIPT_DIR")")}"

# shellcheck source=lib/site-env.sh
source "$SCRIPT_DIR/lib/site-env.sh"
load_site_env "$SITE"

echo "==> Deploying $SITE_DOMAIN ($PUBLIC_URL)"

echo "==> Backing up .env and CMS content"
cp "$APP_DIR/.env" "$ENV_BACKUP" 2>/dev/null || true
mkdir -p "$BACKUP_DIR"
rm -rf "$BACKUP_DIR/content" "$BACKUP_DIR/data" "$BACKUP_DIR/private-cms"
[ -d "$APP_DIR/content" ] && cp -a "$APP_DIR/content" "$BACKUP_DIR/"
[ -d "$APP_DIR/data" ] && cp -a "$APP_DIR/data" "$BACKUP_DIR/"
[ -d "$DOMAIN_ROOT/private/cms" ] && cp -a "$DOMAIN_ROOT/private/cms" "$BACKUP_DIR/private-cms"

echo "==> Fetching from GitHub"
rm -rf "$CLONE_TMP"
git clone "$REPO_URL" "$CLONE_TMP"

echo "==> Syncing application code (CMS content/data on server are preserved)"
rsync -av "$CLONE_TMP/" "$APP_DIR/" \
  --exclude .env \
  --exclude node_modules \
  --exclude uploads \
  --exclude content \
  --exclude data \
  --exclude .git

cp "$ENV_BACKUP" "$APP_DIR/.env" 2>/dev/null || true

echo "==> Updating deploy scripts"
mkdir -p "$DOMAIN_ROOT/scripts"
rsync -av "$CLONE_TMP/scripts/" "$DOMAIN_ROOT/scripts/"
chmod +x "$DOMAIN_ROOT/scripts/"*.sh "$DOMAIN_ROOT/scripts/lib/"*.sh 2>/dev/null || true

echo "==> Installing dependencies"
cd "$APP_DIR"
export PATH="$NODE_BIN:$PATH"
npm install --production

echo "==> Fixing CMS storage and permissions"
bash "$DOMAIN_ROOT/scripts/setup-cms-storage.sh" "$SITE_DOMAIN"

echo "==> Restarting $SERVICE_NAME"
if systemctl is-enabled "$SERVICE_NAME" >/dev/null 2>&1; then
  systemctl restart "$SERVICE_NAME"
else
  echo "Service not installed yet. Run: bash $DOMAIN_ROOT/scripts/install-systemd.sh $SITE_DOMAIN"
  exit 1
fi

sleep 2
echo "==> Health check (port $APP_PORT)"
curl -sf "http://127.0.0.1:${APP_PORT}/deploy-check"
echo ""

CHECK=$(curl -sf "http://127.0.0.1:${APP_PORT}/deploy-check" || echo '{}')
if ! echo "$CHECK" | grep -q '"homeJson":true'; then
  echo "WARNING: CMS files are not writable. Re-running setup..."
  bash "$DOMAIN_ROOT/scripts/setup-cms-storage.sh" "$SITE_DOMAIN"
  systemctl restart "$SERVICE_NAME"
  sleep 2
  curl -sf "http://127.0.0.1:${APP_PORT}/deploy-check"
  echo ""
fi

echo "Done. $PUBLIC_URL/"
echo "CMS content/data on the server were not changed."
