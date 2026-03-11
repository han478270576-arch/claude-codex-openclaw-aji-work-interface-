#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
. "${PROJECT_ROOT}/lib/config.sh"

require_file() {
  local file="$1"
  if [ ! -f "${file}" ]; then
    echo "Required file not found: ${file}" >&2
    exit 1
  fi
}

require_dir() {
  local dir="$1"
  if [ ! -d "${dir}" ]; then
    echo "Required directory not found: ${dir}" >&2
    exit 1
  fi
}

write_test_gateway_launcher() {
  local target="$1"
  cat > "${target}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

export NVM_DIR="${HOME}/.nvm"
export PATH="${OPENCLAW_NODE_BIN_DIR}:\$PATH"
export OPENCLAW_PROFILE="${OPENCLAW_TEST_PROFILE}"
export OPENCLAW_STATE_DIR="${OPENCLAW_TEST_STATE_DIR}"
export OPENCLAW_CONFIG_PATH="${OPENCLAW_TEST_STATE_DIR}/openclaw.json"
export OPENCLAW_GATEWAY_PORT="${OPENCLAW_TEST_PORT}"
export OPENCLAW_GATEWAY_TOKEN="${OPENCLAW_TEST_TOKEN}"

for ENV_FILE in \\
  "${OPENCLAW_TEST_ENV_FILE}" \\
  "${OPENCLAW_TEST_GATEWAY_ENV_FILE}"; do
  if [ -f "\$ENV_FILE" ]; then
    set -a
    . "\$ENV_FILE"
    set +a
  fi
done

cd "${OPENCLAW_TEST_WORKSPACE}"
exec "${OPENCLAW_NODE_BIN_DIR}/node" \\
  "${OPENCLAW_NODE_BIN_DIR}/../lib/node_modules/openclaw/openclaw.mjs" \\
  gateway
EOF
  chmod +x "${target}"
}

sync_test_workspace() {
  local origin_url

  if [ ! -d "${OPENCLAW_TEST_WORKSPACE}/.git" ]; then
    origin_url="$(git -C "${OPENCLAW_PROD_WORKSPACE}" remote get-url origin 2>/dev/null || true)"
    if [ -n "${origin_url}" ]; then
      git clone "${origin_url}" "${OPENCLAW_TEST_WORKSPACE}"
    else
      git clone --no-hardlinks "${OPENCLAW_PROD_WORKSPACE}" "${OPENCLAW_TEST_WORKSPACE}"
      origin_url="$(git -C "${OPENCLAW_PROD_WORKSPACE}" remote get-url origin 2>/dev/null || true)"
      if [ -n "${origin_url}" ]; then
        git -C "${OPENCLAW_TEST_WORKSPACE}" remote remove origin >/dev/null 2>&1 || true
        git -C "${OPENCLAW_TEST_WORKSPACE}" remote add origin "${origin_url}"
      fi
    fi
  fi

  git -C "${OPENCLAW_TEST_WORKSPACE}" fetch origin >/dev/null 2>&1 || true

  if git -C "${OPENCLAW_TEST_WORKSPACE}" show-ref --verify --quiet refs/remotes/origin/test; then
    git -C "${OPENCLAW_TEST_WORKSPACE}" checkout test >/dev/null 2>&1 || git -C "${OPENCLAW_TEST_WORKSPACE}" checkout -b test --track origin/test >/dev/null
    git -C "${OPENCLAW_TEST_WORKSPACE}" pull --ff-only origin test >/dev/null 2>&1 || true
  else
    git -C "${OPENCLAW_TEST_WORKSPACE}" checkout test >/dev/null 2>&1 || git -C "${OPENCLAW_TEST_WORKSPACE}" checkout -b test >/dev/null
  fi
}

generate_test_config() {
  local source_config="${OPENCLAW_PROD_STATE_DIR}/openclaw.json"
  local target_config="${OPENCLAW_TEST_STATE_DIR}/openclaw.json"

  require_file "${source_config}"

  PROD_CONFIG="${source_config}" \
  TEST_CONFIG="${target_config}" \
  OPENCLAW_TEST_WORKSPACE="${OPENCLAW_TEST_WORKSPACE}" \
  OPENCLAW_TEST_PORT="${OPENCLAW_TEST_PORT}" \
  OPENCLAW_TEST_TOKEN="${OPENCLAW_TEST_TOKEN}" \
  OPENCLAW_TEST_PROFILE="${OPENCLAW_TEST_PROFILE}" \
  OPENCLAW_TEST_DISABLE_CHANNELS="${OPENCLAW_TEST_DISABLE_CHANNELS}" \
  python3 <<'PY'
import json
import os
from pathlib import Path

prod = Path(os.environ["PROD_CONFIG"])
test = Path(os.environ["TEST_CONFIG"])
data = json.loads(prod.read_text(encoding="utf-8"))

workspace = os.environ["OPENCLAW_TEST_WORKSPACE"]
test_port = int(os.environ["OPENCLAW_TEST_PORT"])
test_token = os.environ["OPENCLAW_TEST_TOKEN"]
test_profile = os.environ["OPENCLAW_TEST_PROFILE"]
disable_channels = os.environ.get("OPENCLAW_TEST_DISABLE_CHANNELS", "true").lower() == "true"

agents = data.setdefault("agents", {}).setdefault("defaults", {})
agents["workspace"] = workspace

meta = data.setdefault("meta", {})
meta.pop("ajiControlPlaneManaged", None)
meta.pop("ajiControlPlaneProfile", None)

gateway = data.setdefault("gateway", {})
gateway["port"] = test_port
gateway.setdefault("auth", {})
gateway["auth"]["mode"] = "token"
gateway["auth"]["token"] = test_token

if disable_channels:
    channels = data.setdefault("channels", {})
    for key in ("telegram", "discord", "slack"):
        channels.setdefault(key, {})
        channels[key]["enabled"] = False
    plugins = data.setdefault("plugins", {}).setdefault("entries", {})
    for key in ("telegram", "discord", "slack"):
        plugins.setdefault(key, {})
        plugins[key]["enabled"] = False

test.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
}

copy_test_env_files() {
  mkdir -p "${OPENCLAW_TEST_STATE_DIR}"

  if [ -f "${OPENCLAW_PROD_ENV_FILE}" ] && [ ! -f "${OPENCLAW_TEST_ENV_FILE}" ]; then
    cp "${OPENCLAW_PROD_ENV_FILE}" "${OPENCLAW_TEST_ENV_FILE}"
  fi

  if [ -f "${OPENCLAW_PROD_GATEWAY_ENV_FILE}" ] && [ ! -f "${OPENCLAW_TEST_GATEWAY_ENV_FILE}" ]; then
    cp "${OPENCLAW_PROD_GATEWAY_ENV_FILE}" "${OPENCLAW_TEST_GATEWAY_ENV_FILE}"
  fi
}

main() {
  require_dir "${OPENCLAW_PROD_STATE_DIR}"
  require_dir "${OPENCLAW_PROD_WORKSPACE}"

  if [ -z "${OPENCLAW_TEST_TOKEN}" ]; then
    echo "OPENCLAW_TEST_TOKEN is required. Set it in config/local.env." >&2
    exit 1
  fi

  mkdir -p "${OPENCLAW_TEST_STATE_DIR}" "${OPENCLAW_BACKUP_BASE}"
  copy_test_env_files
  sync_test_workspace
  generate_test_config
  write_test_gateway_launcher "${OPENCLAW_TEST_START_SCRIPT}"

  echo "Test environment prepared."
  echo "Test state dir: ${OPENCLAW_TEST_STATE_DIR}"
  echo "Test workspace: ${OPENCLAW_TEST_WORKSPACE}"
  echo "Test branch: $(git -C "${OPENCLAW_TEST_WORKSPACE}" branch --show-current)"
  echo "Test URL: http://localhost:${OPENCLAW_TEST_PORT}/?token=${OPENCLAW_TEST_TOKEN}"
}

main "$@"
