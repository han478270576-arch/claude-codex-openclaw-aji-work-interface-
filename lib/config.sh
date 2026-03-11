#!/usr/bin/env bash

AJI_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AJI_PROJECT_ROOT="$(cd "${AJI_LIB_DIR}/.." && pwd)"

_aji_source_if_exists() {
  local file="$1"
  if [ -f "${file}" ]; then
    # shellcheck disable=SC1090
    . "${file}"
  fi
}

_aji_source_if_exists "${AJI_PROJECT_ROOT}/config/default.env"
_aji_source_if_exists "${AJI_PROJECT_ROOT}/config/local.env"

: "${AJI_CLAUDE_BIN:=$HOME/.local/bin/claude}"
: "${AJI_CODEX_BIN:=$HOME/.local/bin/codex}"
: "${AJI_CLAUDE_SESSION_META_DIR:=$HOME/.claude/usage-data/session-meta}"
: "${AJI_CLAUDE_PROJECTS_DIR:=$HOME/.claude/projects}"
: "${AJI_CODEX_SESSIONS_DIR:=$HOME/.codex/sessions}"
: "${AJI_CODEX_INDEX_FILE:=$HOME/.codex/session_index.jsonl}"
: "${AJI_PORTAL_TMP_DIR:=$HOME/.tmp/aji-portal}"
: "${AJI_WSL_DISTRO:=Ubuntu}"
: "${AJI_WINDOWS_SYNC_DIR:=/mnt/g/WSL}"

: "${OPENCLAW_PROD_STATE_DIR:=$HOME/.openclaw}"
: "${OPENCLAW_TEST_STATE_DIR:=$HOME/.openclaw-test}"
: "${OPENCLAW_PROD_PORT:=18789}"
: "${OPENCLAW_TEST_PORT:=18790}"
: "${OPENCLAW_PROD_TOKEN:=}"
: "${OPENCLAW_TEST_TOKEN:=}"
: "${OPENCLAW_BACKUP_BASE:=$HOME/backups/openclaw-prod}"
: "${OPENCLAW_NODE_BIN_DIR:=$HOME/.nvm/versions/node/v22.22.0/bin}"
: "${OPENCLAW_PACKAGE_JSON:=$HOME/.nvm/versions/node/v22.22.0/lib/node_modules/openclaw/package.json}"

: "${OPENCLAW_PROD_WORKSPACE:=${OPENCLAW_PROD_STATE_DIR}/workspace}"
: "${OPENCLAW_TEST_WORKSPACE:=${OPENCLAW_TEST_STATE_DIR}/workspace}"
: "${OPENCLAW_PROD_START_SCRIPT:=${OPENCLAW_PROD_STATE_DIR}/start-gateway.sh}"
: "${OPENCLAW_TEST_START_SCRIPT:=${OPENCLAW_TEST_STATE_DIR}/start-gateway.sh}"
: "${OPENCLAW_PROD_ENV_FILE:=${OPENCLAW_PROD_STATE_DIR}/.env}"
: "${OPENCLAW_PROD_GATEWAY_ENV_FILE:=${OPENCLAW_PROD_STATE_DIR}/gateway.env}"
: "${OPENCLAW_TEST_ENV_FILE:=${OPENCLAW_TEST_STATE_DIR}/.env}"
: "${OPENCLAW_TEST_GATEWAY_ENV_FILE:=${OPENCLAW_TEST_STATE_DIR}/gateway.env}"

aji_maybe_source_env_file() {
  local env_file="$1"
  if [ -f "${env_file}" ]; then
    set -a
    # shellcheck disable=SC1090
    . "${env_file}"
    set +a
  fi
}

aji_resolve_openclaw_bin() {
  if [ -n "${OPENCLAW_BIN:-}" ] && [ -x "${OPENCLAW_BIN}" ]; then
    printf '%s\n' "${OPENCLAW_BIN}"
    return
  fi

  if command -v openclaw >/dev/null 2>&1; then
    command -v openclaw
    return
  fi

  if [ -s "${HOME}/.nvm/nvm.sh" ]; then
    # shellcheck disable=SC1090
    . "${HOME}/.nvm/nvm.sh"
    if command -v openclaw >/dev/null 2>&1; then
      command -v openclaw
      return
    fi
  fi

  if [ -x "${OPENCLAW_NODE_BIN_DIR}/openclaw" ]; then
    printf '%s\n' "${OPENCLAW_NODE_BIN_DIR}/openclaw"
    return
  fi

  return 1
}

