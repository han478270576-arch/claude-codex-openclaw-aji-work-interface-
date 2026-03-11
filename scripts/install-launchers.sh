#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
. "${PROJECT_ROOT}/lib/config.sh"

TARGET_DIR="${1:-${AJI_WINDOWS_SYNC_DIR}}"
mkdir -p "${TARGET_DIR}"

cp "${PROJECT_ROOT}/bin/claude-codex-openclaw.sh" "${TARGET_DIR}/claude-codex-openclaw.sh"

BAT_FILE="${TARGET_DIR}/claude-codex-openclaw.bat"
printf '%s\r\n' \
  '@echo off' \
  'title Claude Codex OpenClaw Portal' \
  "wsl.exe -d ${AJI_WSL_DISTRO} bash -lc \"bash ${PROJECT_ROOT}/bin/claude-codex-openclaw.sh\"" \
  'pause' > "${BAT_FILE}"

echo "Installed launchers to: ${TARGET_DIR}"
echo "WSL entry: ${TARGET_DIR}/claude-codex-openclaw.sh"
echo "Windows entry: ${TARGET_DIR}/claude-codex-openclaw.bat"

