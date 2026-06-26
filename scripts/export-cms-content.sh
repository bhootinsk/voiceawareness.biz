#!/bin/bash
# Export live CMS content from the server (run as root on the server).
# Creates a tarball you can download and import into the git repo.
#
# Usage:
#   bash /var/www/vhosts/voiceawareness.biz/scripts/export-cms-content.sh

set -e

APP_DIR=/var/www/vhosts/voiceawareness.biz/httpdocs
STAMP=$(date +%Y%m%d-%H%M%S)
OUT=/root/vab-cms-export-$STAMP.tar.gz

tar czf "$OUT" -C "$APP_DIR" content data
echo "Exported: $OUT"
echo ""
echo "Download to your PC (run on your machine):"
echo "  scp root@70.35.206.242:$OUT ."
echo ""
echo "Then in the repo:"
echo "  bash scripts/import-cms-content.sh vab-cms-export-$STAMP.tar.gz"
