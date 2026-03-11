#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/../lib/config.sh"

usage() {
  cat <<'EOF'
Usage:
  bash openclawctl.sh start prod
  bash openclawctl.sh start test
  bash openclawctl.sh stop prod
  bash openclawctl.sh stop test
  bash openclawctl.sh tui prod
  bash openclawctl.sh tui test
  bash openclawctl.sh promote
  bash openclawctl.sh rollback [backup-dir]
  bash openclawctl.sh status

Commands:
  start prod   Start production gateway
  start test   Start test gateway
  stop prod    Stop production gateway
  stop test    Stop test gateway
  tui prod     Open production TUI
  tui test     Open test TUI
  promote      Backup production, fast-forward test into main, push, restart prod
  rollback     Restore production from latest backup or a specified backup dir
  status       Show process and listener status for prod/test
EOF
}

status_cmd() {
  echo "Processes:"
  pgrep -af 'openclaw|run-node|gateway' || true
  echo
  echo "Production listener:"
  lsof -iTCP:${OPENCLAW_PROD_PORT} -sTCP:LISTEN -n -P || true
  echo
  echo "Test listener:"
  lsof -iTCP:${OPENCLAW_TEST_PORT} -sTCP:LISTEN -n -P || true
}

main() {
  local cmd="${1:-}"
  local env="${2:-}"

  case "${cmd}" in
    start)
      case "${env}" in
        prod) exec bash "${SCRIPT_DIR}/openclaw-start-prod.sh" ;;
        test) exec bash "${SCRIPT_DIR}/openclaw-start-test.sh" ;;
        *) usage; exit 1 ;;
      esac
      ;;
    stop)
      case "${env}" in
        prod) exec bash "${SCRIPT_DIR}/openclaw-stop-prod.sh" ;;
        test) exec bash "${SCRIPT_DIR}/openclaw-stop-test.sh" ;;
        *) usage; exit 1 ;;
      esac
      ;;
    tui)
      case "${env}" in
        prod) exec bash "${SCRIPT_DIR}/openclaw-tui-prod.sh" ;;
        test) exec bash "${SCRIPT_DIR}/openclaw-tui-test.sh" ;;
        *) usage; exit 1 ;;
      esac
      ;;
    promote)
      exec bash "${SCRIPT_DIR}/openclaw-promote-test-to-prod.sh"
      ;;
    rollback)
      exec bash "${SCRIPT_DIR}/openclaw-rollback-prod.sh" "${env:-}"
      ;;
    status)
      status_cmd
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
