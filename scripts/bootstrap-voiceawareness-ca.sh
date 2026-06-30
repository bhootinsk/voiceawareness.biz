#!/bin/bash
# One-time bootstrap for voiceawareness.ca — clone .biz app + CMS onto a fresh Plesk domain.
# Run as root AFTER:
#   - voiceawareness.ca exists in Plesk with empty httpdocs
#   - Apache proxy directives point to port 3001 (see docs/DEPLOY-VOICEAWARENESS-CA.md)
#   - Plesk Node.js is DISABLED for voiceawareness.ca
#
# Usage:
#   bash /var/www/vhosts/voiceawareness.ca/scripts/bootstrap-voiceawareness-ca.sh
#
# Or before scripts exist on the server (paste after domain is created):
#   curl -fsSL https://raw.githubusercontent.com/bhootinsk/voiceawareness.biz/main/scripts/bootstrap-voiceawareness-ca.sh | bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE=voiceawareness.ca

# shellcheck source=lib/site-env.sh
source "$SCRIPT_DIR/lib/site-env.sh"
load_site_env "$SITE"

BIZ_CMS="${CMS_MIRROR_SOURCE:-/var/www/vhosts/voiceawareness.biz/private/cms}"
CLONE_DIR=/tmp/vac-bootstrap

echo "==> Bootstrap voiceawareness.ca (mirror of .biz)"
echo "    App dir:    $APP_DIR"
echo "    Port:       $APP_PORT"
echo "    CMS source: $BIZ_CMS"

if [ ! -d "$BIZ_CMS/content" ]; then
  echo "ERROR: .biz CMS not found at $BIZ_CMS"
  echo "Ensure voiceawareness.biz is running first."
  exit 1
fi

if [ -d "$APP_DIR" ]; then
  DETECTED_USER=$(stat -c '%U' "$APP_DIR" 2>/dev/null || true)
  if [ -n "$DETECTED_USER" ] && [ "$DETECTED_USER" != "$APP_USER" ]; then
    echo "==> Detected Plesk subscription user: $DETECTED_USER (was $APP_USER in config)"
    APP_USER="$DETECTED_USER"
  fi
fi

if ! id "$APP_USER" &>/dev/null; then
  echo "ERROR: Linux user $APP_USER does not exist."
  echo "Create the domain in Plesk first, then run:"
  echo "  stat -c '%U' $APP_DIR"
  exit 1
fi

echo "==> Cloning application from GitHub"
rm -rf "$CLONE_DIR"
git clone "$REPO_URL" "$CLONE_DIR"

echo "==> Syncing code to httpdocs"
mkdir -p "$APP_DIR"
rsync -av "$CLONE_DIR/" "$APP_DIR/" \
  --exclude .env \
  --exclude node_modules \
  --exclude uploads \
  --exclude content \
  --exclude data \
  --exclude .git

echo "==> Copying scripts to domain root"
mkdir -p "$DOMAIN_ROOT/scripts"
rsync -av "$CLONE_DIR/scripts/" "$DOMAIN_ROOT/scripts/"
chmod +x "$DOMAIN_ROOT/scripts/"*.sh "$DOMAIN_ROOT/scripts/lib/"*.sh 2>/dev/null || true

echo "==> Creating .env"
if [ ! -f "$APP_DIR/.env" ]; then
  SECRET=$(openssl rand -hex 24 2>/dev/null || head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')
  cat > "$APP_DIR/.env" <<EOF
NODE_ENV=production
PORT=$APP_PORT
SESSION_SECRET=$SECRET
ADMIN_USERNAME=admin
ADMIN_PASSWORD=VoiceAwareness2025!
EOF
  echo "    Created .env with default admin password — change ADMIN_PASSWORD after first login."
else
  echo "    Keeping existing .env"
fi

echo "==> Cloning CMS from voiceawareness.biz"
mkdir -p "$DOMAIN_ROOT/private/cms"
rsync -a --delete "$BIZ_CMS/" "$DOMAIN_ROOT/private/cms/"

echo "==> Setting domain in site.json for .ca"
SITE_JSON="$DOMAIN_ROOT/private/cms/data/site.json"
if [ -f "$SITE_JSON" ]; then
  sed -i 's/"domain": "voiceawareness.biz"/"domain": "voiceawareness.ca"/' "$SITE_JSON"
fi

echo "==> Stopping any stray node on port $APP_PORT"
pkill -f "node app.js" 2>/dev/null || true
sleep 1

echo "==> Installing systemd service"
bash "$DOMAIN_ROOT/scripts/install-systemd.sh" "$SITE_DOMAIN"

echo "==> Reconfiguring Apache"
plesk sbin httpdmng --reconfigure-domain voiceawareness.ca 2>/dev/null || true

sleep 2
echo ""
echo "SUCCESS"
echo "  systemctl status $SERVICE_NAME"
echo "  curl -s http://127.0.0.1:${APP_PORT}/deploy-check"
echo "  $PUBLIC_URL/"
echo ""
echo "Change admin password: $APP_DIR/.env"
echo "Future deploys: bash $DOMAIN_ROOT/scripts/deploy.sh"
echo "Mirror CMS from .biz: bash $DOMAIN_ROOT/scripts/sync-cms-mirror.sh"
