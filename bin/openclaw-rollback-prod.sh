#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/../lib/config.sh"

REPO="${OPENCLAW_PROD_WORKSPACE}"
BACKUP_BASE="${OPENCLAW_BACKUP_BASE}"
PROD_START="${OPENCLAW_PROD_START_SCRIPT}"
PROD_PORT="${OPENCLAW_PROD_PORT}"
PROD_TOKEN="${OPENCLAW_PROD_TOKEN}"
PROD_LOG=/tmp/openclaw-prod-gateway.log

pick_backup() {
  if [ $# -gt 0 ]; then
    if [ -d "$1" ]; then
      printf '%s\n' "$1"
    else
      printf '%s\n' "${BACKUP_BASE}/$1"
    fi
    return
  fi

  find "${BACKUP_BASE}" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -r | head -n1 | sed "s#^#${BACKUP_BASE}/#"
}

BACKUP_DIR="$(pick_backup "${1:-}")"

if [ -z "${BACKUP_DIR}" ] || [ ! -d "${BACKUP_DIR}" ]; then
  echo "Backup directory not found." >&2
  exit 1
fi

if [ -n "$(git -C "${REPO}" status --porcelain 2>/dev/null)" ]; then
  echo "Production workspace has uncommitted changes. Refusing rollback to avoid overwriting local work." >&2
  git -C "${REPO}" status --short >&2 || true
  exit 1
fi

TAR_FILE="${BACKUP_DIR}/openclaw-runtime-state.tar.gz"
SHA_FILE="${BACKUP_DIR}/openclaw-runtime-state.tar.gz.sha256"
COMMIT_FILE="${BACKUP_DIR}/workspace-commit.txt"

if [ ! -f "${TAR_FILE}" ] || [ ! -f "${SHA_FILE}" ] || [ ! -f "${COMMIT_FILE}" ]; then
  echo "Backup is incomplete: ${BACKUP_DIR}" >&2
  exit 1
fi

sha256sum -c "${SHA_FILE}"

TARGET_COMMIT="$(tr -d '\n' < "${COMMIT_FILE}")"
if ! git -C "${REPO}" cat-file -e "${TARGET_COMMIT}^{commit}" 2>/dev/null; then
  echo "Target commit not found locally: ${TARGET_COMMIT}" >&2
  exit 1
fi

if lsof -tiTCP:${PROD_PORT} -sTCP:LISTEN >/dev/null 2>&1; then
  lsof -tiTCP:${PROD_PORT} -sTCP:LISTEN | xargs -r kill
  sleep 2
fi

git -C "${REPO}" checkout main >/dev/null 2>&1 || true
git -C "${REPO}" reset --hard "${TARGET_COMMIT}" >/dev/null

tar -C "${HOME}" -xzf "${TAR_FILE}"

nohup bash "${PROD_START}" >"${PROD_LOG}" 2>&1 &

for _ in $(seq 1 20); do
  if lsof -iTCP:${PROD_PORT} -sTCP:LISTEN -n -P >/dev/null 2>&1; then
    echo "Rollback completed."
    echo "Restored backup: ${BACKUP_DIR}"
    echo "Restored commit: ${TARGET_COMMIT}"
    if [ -n "${PROD_TOKEN}" ]; then
      echo "Production URL: http://127.0.0.1:${PROD_PORT}/?token=${PROD_TOKEN}"
      echo "Windows URL: http://localhost:${PROD_PORT}/?token=${PROD_TOKEN}"
    else
      echo "Production URL: http://127.0.0.1:${PROD_PORT}/"
      echo "Windows URL: http://localhost:${PROD_PORT}/"
    fi
    echo "Log: ${PROD_LOG}"
    echo "Note: origin/main was not changed. Push or reconcile remote manually if needed."
    exit 0
  fi
  sleep 1
done

echo "Production gateway did not come up within 20 seconds after rollback." >&2
echo "Check log: ${PROD_LOG}" >&2
exit 1
