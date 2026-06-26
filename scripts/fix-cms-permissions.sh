#!/bin/bash
# Fix ownership so the Node app can write CMS files (run as root on the server).
#
# Usage:
#   bash /var/www/vhosts/voiceawareness.biz/scripts/fix-cms-permissions.sh

set -e

APP_DIR=/var/www/vhosts/voiceawareness.biz/httpdocs
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

echo "==> Using $APP_USER:$APP_GROUP"

mkdir -p "$APP_DIR/content/pages" "$APP_DIR/data" "$APP_DIR/uploads"

chown -R "$APP_USER:$APP_GROUP" "$APP_DIR/content" "$APP_DIR/data" "$APP_DIR/uploads"
find "$APP_DIR/content" "$APP_DIR/data" "$APP_DIR/uploads" -type d -exec chmod u+rwx {} +
find "$APP_DIR/content" "$APP_DIR/data" "$APP_DIR/uploads" -type f -exec chmod u+rw {} +

if [ -f "$APP_DIR/.env" ]; then
  chown "$APP_USER:$APP_GROUP" "$APP_DIR/.env"
  chmod 640 "$APP_DIR/.env"
fi

# App user must traverse into httpdocs (common Plesk layout).
if [ -d "$APP_DIR" ]; then
  chmod u+rwx "$APP_DIR" 2>/dev/null || true
  chgrp "$APP_GROUP" "$APP_DIR" 2>/dev/null || true
fi

echo "==> Permissions fixed for content/, data/, uploads/"
