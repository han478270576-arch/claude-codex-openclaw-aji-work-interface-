#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/../lib/config.sh"

export NVM_DIR="${HOME}/.nvm"
export PATH="${OPENCLAW_NODE_BIN_DIR}:${PATH}"

aji_maybe_source_env_file "${OPENCLAW_PROD_ENV_FILE}"
aji_maybe_source_env_file "${OPENCLAW_PROD_GATEWAY_ENV_FILE}"

OPENCLAW_BIN="$(aji_resolve_openclaw_bin || true)"
if [ -z "${OPENCLAW_BIN}" ]; then
  echo "openclaw not found in PATH or nvm." >&2
  exit 1
fi

cd "${OPENCLAW_PROD_WORKSPACE}"
exec "${OPENCLAW_BIN}" tui
