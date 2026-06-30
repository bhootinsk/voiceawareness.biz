#!/bin/bash
# Load per-domain settings for deploy / bootstrap scripts.
# Usage: source "$(dirname "$0")/lib/site-env.sh" voiceawareness.ca

load_site_env() {
  local site="${1:-voiceawareness.biz}"
  local script_dir="${SITE_ENV_SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
  local env_file="$script_dir/config/${site}.env"

  if [ ! -f "$env_file" ]; then
    echo "Site config not found: $env_file"
    echo "Available: voiceawareness.biz, voiceawareness.ca"
    return 1
  fi

  # shellcheck disable=SC1090
  source "$env_file"

  DOMAIN_ROOT="${DOMAIN_ROOT:-/var/www/vhosts/$SITE_DOMAIN}"
  APP_DIR="${APP_DIR:-$DOMAIN_ROOT/httpdocs}"
  NODE_BIN="${NODE_BIN:-/opt/plesk/node/24/bin}"
  APP_GROUP="${APP_GROUP:-psacln}"
  REPO_URL="${REPO_URL:-https://github.com/bhootinsk/voiceawareness.biz.git}"
  BACKUP_DIR="${BACKUP_DIR:-/root/${BACKUP_PREFIX:-vab}-cms-backup}"
  ENV_BACKUP="${ENV_BACKUP:-/root/${BACKUP_PREFIX:-vab}.env.bak}"
  CLONE_TMP="${CLONE_TMP:-/tmp/${BACKUP_PREFIX:-vab}-update}"
  SERVICE_FILE="${SERVICE_FILE:-$script_dir/systemd/${SERVICE_NAME}.service}"

  if [ -z "$APP_USER" ] && [ -d "$APP_DIR" ]; then
    APP_USER=$(stat -c '%U' "$APP_DIR" 2>/dev/null || true)
  fi
  APP_USER="${APP_USER:-voiceawarenessbiz}"
}

detect_site_from_deploy_path() {
  local deploy_script="$1"
  local domain_root
  domain_root="$(cd "$(dirname "$deploy_script")/.." && pwd)"
  basename "$domain_root"
}
