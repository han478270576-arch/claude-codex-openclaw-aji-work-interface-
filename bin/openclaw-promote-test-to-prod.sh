#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/../lib/config.sh"

REPO="${OPENCLAW_PROD_WORKSPACE}"
TEST_REPO="${OPENCLAW_TEST_WORKSPACE}"
PROD_START="${OPENCLAW_PROD_START_SCRIPT}"
BACKUP_BASE="${OPENCLAW_BACKUP_BASE}"
PROD_PORT="${OPENCLAW_PROD_PORT}"
PROD_TOKEN="${OPENCLAW_PROD_TOKEN}"
PROD_LOG=/tmp/openclaw-prod-gateway.log

if ! git -C "${REPO}" rev-parse --verify test >/dev/null 2>&1; then
  echo "Local test branch does not exist." >&2
  exit 1
fi

if [ -n "$(git -C "${TEST_REPO}" status --porcelain 2>/dev/null)" ]; then
  echo "Test workspace has uncommitted changes. Commit or stash them before promotion." >&2
  git -C "${TEST_REPO}" status --short >&2 || true
  exit 1
fi

TS=$(date +%Y%m%d-%H%M%S)
BACKUP_ROOT=${BACKUP_BASE}/${TS}
TMP_WORKTREE=$(mktemp -d /tmp/openclaw-promote-XXXXXX)

cleanup() {
  git -C "${REPO}" worktree remove -f "${TMP_WORKTREE}" >/dev/null 2>&1 || rm -rf "${TMP_WORKTREE}"
}
trap cleanup EXIT

mkdir -p "${BACKUP_ROOT}"

node -v > "${BACKUP_ROOT}/node-version.txt"
npm -v > "${BACKUP_ROOT}/npm-version.txt"
node -p "require('${OPENCLAW_PACKAGE_JSON}').version" > "${BACKUP_ROOT}/openclaw-version.txt"
git -C "${REPO}" rev-parse HEAD > "${BACKUP_ROOT}/workspace-commit.txt"
git -C "${REPO}" status --short > "${BACKUP_ROOT}/workspace-status.txt"

backup_items=()
for rel in \
  ".env" \
  "gateway.env" \
  "openclaw.json" \
  "openclaw.json.bak" \
  "openclaw.json.bak.1" \
  "openclaw.json.bak.2" \
  "openclaw.json.bak.3" \
  "openclaw.json.bak.4" \
  "start-gateway.sh" \
  "update-check.json" \
  "exec-approvals.json" \
  "agents" \
  "canvas" \
  "completions" \
  "credentials" \
  "cron" \
  "devices" \
  "identity" \
  "media" \
  "settings" \
  "skills" \
  "subagents" \
  "telegram"; do
  if [ -e "${OPENCLAW_PROD_STATE_DIR}/${rel}" ]; then
    backup_items+=("$(basename "${OPENCLAW_PROD_STATE_DIR}")/${rel}")
  fi
done

if [ "${#backup_items[@]}" -eq 0 ]; then
  echo "No production runtime-state files found to back up." >&2
  exit 1
fi

tar -C "${HOME}" -czf "${BACKUP_ROOT}/openclaw-runtime-state.tar.gz" "${backup_items[@]}"
sha256sum "${BACKUP_ROOT}/openclaw-runtime-state.tar.gz" > "${BACKUP_ROOT}/openclaw-runtime-state.tar.gz.sha256"

git -C "${REPO}" fetch origin
git -C "${REPO}" worktree add --detach "${TMP_WORKTREE}" origin/main >/dev/null
git -C "${TMP_WORKTREE}" fetch origin >/dev/null
git -C "${TMP_WORKTREE}" checkout --detach origin/main >/dev/null

MAIN_SHA=$(git -C "${TMP_WORKTREE}" rev-parse HEAD)
TEST_SHA=$(git -C "${TMP_WORKTREE}" rev-parse test)

if [ "${MAIN_SHA}" = "${TEST_SHA}" ]; then
  echo "main and test already point to the same commit: ${MAIN_SHA}"
else
  git -C "${TMP_WORKTREE}" merge --ff-only test
  git -C "${TMP_WORKTREE}" push origin HEAD:main
fi

if lsof -tiTCP:${PROD_PORT} -sTCP:LISTEN >/dev/null 2>&1; then
  lsof -tiTCP:${PROD_PORT} -sTCP:LISTEN | xargs -r kill
  sleep 2
fi

nohup bash "${PROD_START}" >"${PROD_LOG}" 2>&1 &

for _ in $(seq 1 20); do
  if lsof -iTCP:${PROD_PORT} -sTCP:LISTEN -n -P >/dev/null 2>&1; then
    NEW_SHA="$(git -C "${REPO}" rev-parse main)"
    echo "Promotion completed."
    echo "Promoted commit: ${NEW_SHA}"
    echo "Backup: ${BACKUP_ROOT}"
    if [ -n "${PROD_TOKEN}" ]; then
      echo "Production URL: http://127.0.0.1:${PROD_PORT}/?token=${PROD_TOKEN}"
      echo "Windows URL: http://localhost:${PROD_PORT}/?token=${PROD_TOKEN}"
    else
      echo "Production URL: http://127.0.0.1:${PROD_PORT}/"
      echo "Windows URL: http://localhost:${PROD_PORT}/"
    fi
    echo "Log: ${PROD_LOG}"
    exit 0
  fi
  sleep 1
done

echo "Production gateway did not come up within 20 seconds after promotion." >&2
echo "Check log: ${PROD_LOG}" >&2
exit 1
