#!/bin/bash
# Copy live CMS from voiceawareness.biz to voiceawareness.ca (mirror content).
# Run as root after editing on .biz, or after publishing CMS to GitHub.
#
# Usage:
#   bash /var/www/vhosts/voiceawareness.ca/scripts/sync-cms-mirror.sh
#   bash /var/www/vhosts/voiceawareness.biz/scripts/sync-cms-mirror.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=lib/site-env.sh
source "$SCRIPT_DIR/lib/site-env.sh"
load_site_env voiceawareness.biz
SOURCE_CMS="$DOMAIN_ROOT/private/cms"

# shellcheck source=lib/site-env.sh
load_site_env voiceawareness.ca
TARGET_CMS="$DOMAIN_ROOT/private/cms"

if [ ! -d "$SOURCE_CMS/content" ]; then
  echo "Source CMS missing: $SOURCE_CMS"
  exit 1
fi

echo "==> Mirroring CMS"
echo "    From: $SOURCE_CMS"
echo "    To:   $TARGET_CMS"

mkdir -p "$TARGET_CMS"
rsync -a --delete "$SOURCE_CMS/" "$TARGET_CMS/"

SITE_JSON="$TARGET_CMS/data/site.json"
if [ -f "$SITE_JSON" ]; then
  sed -i 's/"domain": "voiceawareness.biz"/"domain": "voiceawareness.ca"/' "$SITE_JSON"
fi

chown -R "$APP_USER:$APP_GROUP" "$TARGET_CMS"

systemctl restart "$SERVICE_NAME"
sleep 2
curl -sf "http://127.0.0.1:${APP_PORT}/deploy-check" && echo ""

echo "Done. CMS mirrored to voiceawareness.ca ($PUBLIC_URL)"
