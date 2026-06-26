#!/bin/bash
# Fix ownership so the Node app can write CMS files (run as root on the server).
#
# Usage:
#   bash /var/www/vhosts/voiceawareness.biz/scripts/fix-cms-permissions.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/setup-cms-storage.sh"
systemctl restart voiceawareness-biz 2>/dev/null || true
