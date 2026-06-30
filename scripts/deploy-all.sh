#!/bin/bash
# Deploy code to both voiceawareness.biz and voiceawareness.ca, then mirror CMS .biz → .ca.
# Run as root on the server.
#
# Usage:
#   bash /var/www/vhosts/voiceawareness.biz/scripts/deploy-all.sh
#   bash /var/www/vhosts/voiceawareness.biz/scripts/deploy-all.sh --no-cms-sync

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYNC_CMS=1

for arg in "$@"; do
  case "$arg" in
    --no-cms-sync) SYNC_CMS=0 ;;
  esac
done

echo "========== voiceawareness.biz =========="
bash "$SCRIPT_DIR/deploy.sh" voiceawareness.biz

if [ -d /var/www/vhosts/voiceawareness.ca/httpdocs ]; then
  echo ""
  echo "========== voiceawareness.ca =========="
  bash "$SCRIPT_DIR/deploy.sh" voiceawareness.ca

  if [ "$SYNC_CMS" -eq 1 ]; then
    echo ""
    echo "========== CMS mirror .biz → .ca =========="
    bash "$SCRIPT_DIR/sync-cms-mirror.sh"
  fi
else
  echo ""
  echo "voiceawareness.ca not installed yet — skipped."
  echo "See docs/DEPLOY-VOICEAWARENESS-CA.md"
fi

echo ""
echo "All done."
