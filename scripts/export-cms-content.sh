#!/bin/bash
# Export live CMS content from the server (run as root on the server).
#
# Usage:
#   bash /var/www/vhosts/voiceawareness.biz/scripts/export-cms-content.sh

set -e

DOMAIN_ROOT=/var/www/vhosts/voiceawareness.biz
APP_DIR="$DOMAIN_ROOT/httpdocs"
CMS_ROOT="$DOMAIN_ROOT/private/cms"
STAMP=$(date +%Y%m%d-%H%M%S)
OUT=/root/vab-cms-export-$STAMP.tar.gz

if [ ! -d "$CMS_ROOT/content" ]; then
  CMS_ROOT="$APP_DIR"
fi

tar czf "$OUT" -C "$CMS_ROOT" content data
echo "Exported: $OUT"
echo ""
echo "Download to your PC (run on your machine):"
echo "  scp root@70.35.206.242:$OUT ."
echo ""
echo "Then in the repo:"
echo "  bash scripts/import-cms-content.sh vab-cms-export-$STAMP.tar.gz"
