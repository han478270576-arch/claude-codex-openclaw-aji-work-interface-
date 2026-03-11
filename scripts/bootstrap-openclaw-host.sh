#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
. "${PROJECT_ROOT}/lib/config.sh"

write_prod_gateway_launcher() {
  local target="$1"
  cat > "${target}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

export NVM_DIR="${HOME}/.nvm"
export PATH="${OPENCLAW_NODE_BIN_DIR}:\$PATH"

if [ -f "${OPENCLAW_PROD_GATEWAY_ENV_FILE}" ]; then
  set -a
  . "${OPENCLAW_PROD_GATEWAY_ENV_FILE}"
  set +a
fi

cd "${OPENCLAW_PROD_WORKSPACE}"
exec "${OPENCLAW_NODE_BIN_DIR}/node" \\
  "${OPENCLAW_NODE_BIN_DIR}/../lib/node_modules/openclaw/openclaw.mjs" \\
  gateway
EOF
  chmod +x "${target}"
}

main() {
  if [ ! -d "${OPENCLAW_PROD_STATE_DIR}" ]; then
    echo "Production state dir not found: ${OPENCLAW_PROD_STATE_DIR}" >&2
    echo "Run OpenClaw once or create the production state dir before bootstrapping." >&2
    exit 1
  fi

  if [ ! -d "${OPENCLAW_PROD_WORKSPACE}/.git" ]; then
    echo "Production workspace is not a git repo: ${OPENCLAW_PROD_WORKSPACE}" >&2
    exit 1
  fi

  mkdir -p "${OPENCLAW_BACKUP_BASE}"

  if [ ! -f "${OPENCLAW_PROD_START_SCRIPT}" ]; then
    write_prod_gateway_launcher "${OPENCLAW_PROD_START_SCRIPT}"
  fi

  bash "${SCRIPT_DIR}/setup-test-env.sh"

  if [ "${OPENCLAW_INSTALL_LAUNCHERS}" = "true" ] && [ -n "${AJI_WINDOWS_SYNC_DIR}" ]; then
    bash "${SCRIPT_DIR}/install-launchers.sh" "${AJI_WINDOWS_SYNC_DIR}"
  fi

  echo
  echo "OpenClaw host bootstrap complete."
  echo "Production state dir: ${OPENCLAW_PROD_STATE_DIR}"
  echo "Production workspace: ${OPENCLAW_PROD_WORKSPACE}"
  echo "Test state dir: ${OPENCLAW_TEST_STATE_DIR}"
  echo "Test workspace: ${OPENCLAW_TEST_WORKSPACE}"
  echo "Backup base: ${OPENCLAW_BACKUP_BASE}"
}

main "$@"

