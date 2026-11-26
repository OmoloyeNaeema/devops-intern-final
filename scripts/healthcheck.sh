#!/usr/bin/env bash
set -euo pipefail

URL="${1:-http://localhost:8080}"

echo "Checking application at: $URL"

if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl is not installed."
    exit 1
fi

HTTP_STATUS=$(curl -sS -o /dev/null -w "%{http_code}" "$URL") || {
    echo "ERROR: Unable to connect to $URL"
    exit 1
}

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "SUCCESS: Application is healthy (HTTP $HTTP_STATUS)"
    exit 0
else
    echo "ERROR: Application returned HTTP $HTTP_STATUS"
    exit 1
fi
