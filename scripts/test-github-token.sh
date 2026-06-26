#!/bin/bash
# Test /root/vab-github.env and GitHub API (run as root on the server).
#
# Usage:
#   bash /root/test-github-token.sh

set -e

FILE=/root/vab-github.env

if [ ! -f "$FILE" ]; then
  echo "Missing $FILE"
  exit 1
fi

echo "File: $FILE ($(wc -c < "$FILE") bytes)"
echo "Hex (first line):"
xxd "$FILE" | head -2

TOKEN=$(sed 's/.*GITHUB_TOKEN=//' "$FILE" | tr -d '\r\n"'"' ')
echo "Token length: ${#TOKEN}"

if [ "${#TOKEN}" -eq 0 ]; then
  echo "ERROR: Could not read token from file."
  exit 1
fi

echo "GitHub API:"
curl -s -H "Authorization: Bearer ${TOKEN}" https://api.github.com/user
echo ""
