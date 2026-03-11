#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/../lib/config.sh"

PORT="${OPENCLAW_PROD_PORT}"
TOKEN="${OPENCLAW_PROD_TOKEN}"
START_CMD=(bash "${OPENCLAW_PROD_START_SCRIPT}")
LOG_FILE=/tmp/openclaw-prod-gateway.log

if lsof -iTCP:${PORT} -sTCP:LISTEN -n -P >/dev/null 2>&1; then
  echo "Production gateway is already listening on ${PORT}."
  if [ -n "${TOKEN}" ]; then
    echo "URL: http://127.0.0.1:${PORT}/?token=${TOKEN}"
  else
    echo "URL: http://127.0.0.1:${PORT}/"
  fi
  exit 0
fi

nohup "${START_CMD[@]}" >"${LOG_FILE}" 2>&1 &

for _ in $(seq 1 20); do
  if lsof -iTCP:${PORT} -sTCP:LISTEN -n -P >/dev/null 2>&1; then
    echo "Production gateway started."
    if [ -n "${TOKEN}" ]; then
      echo "URL: http://127.0.0.1:${PORT}/?token=${TOKEN}"
      echo "Windows URL: http://localhost:${PORT}/?token=${TOKEN}"
    else
      echo "URL: http://127.0.0.1:${PORT}/"
      echo "Windows URL: http://localhost:${PORT}/"
    fi
    echo "Log: ${LOG_FILE}"
    exit 0
  fi
  sleep 1
done

echo "Production gateway did not come up within 20 seconds." >&2
echo "Check log: ${LOG_FILE}" >&2
exit 1
