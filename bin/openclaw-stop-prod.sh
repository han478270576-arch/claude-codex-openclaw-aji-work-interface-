#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/../lib/config.sh"

PORT="${OPENCLAW_PROD_PORT}"

if ! lsof -iTCP:${PORT} -sTCP:LISTEN -n -P >/dev/null 2>&1; then
  echo "Production gateway is not listening on ${PORT}."
  exit 0
fi

lsof -tiTCP:${PORT} -sTCP:LISTEN | xargs -r kill
sleep 1

if lsof -iTCP:${PORT} -sTCP:LISTEN -n -P >/dev/null 2>&1; then
  echo "Production gateway still appears to be running on ${PORT}." >&2
  exit 1
fi

echo "Production gateway stopped."
