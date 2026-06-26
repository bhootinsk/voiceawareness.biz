#!/bin/bash
# Copy live CMS content from the server into GitHub (run as root on the server).
#
# One-time setup — create a GitHub personal access token with repo scope, then:
#   echo 'GITHUB_TOKEN=ghp_xxxx' >> /root/vab-github.env
#   chmod 600 /root/vab-github.env
#
# Usage:
#   bash /var/www/vhosts/voiceawareness.biz/scripts/publish-cms-to-github.sh

set -e

DOMAIN_ROOT=/var/www/vhosts/voiceawareness.biz
APP_DIR="$DOMAIN_ROOT/httpdocs"
CMS_ROOT="$DOMAIN_ROOT/private/cms"
REPO=https://github.com/bhootinsk/voiceawareness.biz.git
WORKDIR=/tmp/vab-cms-publish
ENV_FILE=/root/vab-github.env

if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

if [ -z "$GITHUB_TOKEN" ]; then
  echo "GITHUB_TOKEN is not set."
  echo "Create /root/vab-github.env with: GITHUB_TOKEN=ghp_your_token"
  echo "Or export CMS manually: bash scripts/export-cms-content.sh"
  exit 1
fi

echo "==> Cloning repository"
rm -rf "$WORKDIR"
git clone "$REPO" "$WORKDIR"

echo "==> Copying live CMS content"
if [ -d "$CMS_ROOT/content" ]; then
  rsync -av "$CMS_ROOT/content/" "$WORKDIR/content/"
  rsync -av "$CMS_ROOT/data/" "$WORKDIR/data/"
else
  rsync -av "$APP_DIR/content/" "$WORKDIR/content/"
  rsync -av "$APP_DIR/data/" "$WORKDIR/data/"
fi

cd "$WORKDIR"
git add content data
if git diff --staged --quiet; then
  echo "No CMS changes to publish."
  exit 0
fi

git -c user.name="voiceawareness.biz CMS" -c user.email="cms@voiceawareness.biz" \
  commit -m "Sync CMS content from production."

git push "https://${GITHUB_TOKEN}@github.com/bhootinsk/voiceawareness.biz.git" main
echo "Published CMS content to GitHub."
