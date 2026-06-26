#!/bin/bash
# Import a CMS export tarball into this git repo (run from repo root).
#
# Usage:
#   bash scripts/import-cms-content.sh path/to/vab-cms-export-*.tar.gz

set -e

if [ -z "$1" ]; then
  echo "Usage: bash scripts/import-cms-content.sh <export.tar.gz>"
  exit 1
fi

ARCHIVE="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -f "$ARCHIVE" ]; then
  echo "File not found: $ARCHIVE"
  exit 1
fi

tar xzf "$ARCHIVE" -C "$ROOT"
echo "Imported content/ and data/ into $ROOT"
echo "Review with: git status"
echo "Then commit and push if the changes look right."
