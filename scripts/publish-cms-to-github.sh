#!/bin/bash
# Copy live CMS content from the server into GitHub (run as root on the server).
#
# One-time setup — create a GitHub personal access token (classic) with repo scope:
#   printf 'GITHUB_TOKEN=ghp_your_real_token\n' > /root/vab-github.env
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

trim_token() {
  local v="$1"
  v="${v//$'\r'/}"
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  case "$v" in
    \"*\") v="${v#\"}"; v="${v%\"}" ;;
    \'*\') v="${v#\'}"; v="${v%\'}" ;;
  esac
  printf '%s' "$v"
}

load_github_token() {
  local file="$1"
  if [ ! -f "$file" ]; then
    return 1
  fi
  trim_token "$(sed 's/.*GITHUB_TOKEN=//' "$file" | tr -d '\r\n')"
}

GITHUB_TOKEN=$(load_github_token "$ENV_FILE")

if [ -z "$GITHUB_TOKEN" ]; then
  echo "GITHUB_TOKEN is not set."
  echo "Create /root/vab-github.env with one line:"
  echo "  GITHUB_TOKEN=ghp_your_real_token"
  echo "No quotes. Or use: bash scripts/export-cms-content.sh"
  exit 1
fi

if [ "$GITHUB_TOKEN" = "ghp_your_token_here" ] || [ "$GITHUB_TOKEN" = "ghp_your_token" ]; then
  echo "GITHUB_TOKEN is still the placeholder. Paste your real token into /root/vab-github.env"
  exit 1
fi

echo "==> Checking GitHub token"
TOKEN_CHECK=$(curl -s -o /tmp/vab-github-user.json -w "%{http_code}" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/user)

if [ "$TOKEN_CHECK" != "200" ]; then
  echo "GitHub rejected the token (HTTP $TOKEN_CHECK)."
  echo "Create a new classic token at https://github.com/settings/tokens with 'repo' scope."
  echo "Then update /root/vab-github.env (no quotes, no spaces around =):"
  echo "  GITHUB_TOKEN=ghp_xxxxxxxx"
  cat /tmp/vab-github-user.json 2>/dev/null || true
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

echo "==> Pushing to GitHub"
git -c credential.helper= push \
  "https://x-access-token:${GITHUB_TOKEN}@github.com/bhootinsk/voiceawareness.biz.git" \
  main

echo "Published CMS content to GitHub."
