#!/usr/bin/env bash
set -euo pipefail

export TERM="${TERM:-xterm}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/../lib/config.sh"

CLAUDE_BIN="${AJI_CLAUDE_BIN}"
CODEX_BIN="${AJI_CODEX_BIN}"
TMP_DIR="${AJI_PORTAL_TMP_DIR}"
PORTAL_CWD="${PWD}"
PAGE_SIZE=10
mkdir -p "${TMP_DIR}"

if [ -t 1 ]; then
  RED="$(printf '\033[31m')"
  GREEN="$(printf '\033[32m')"
  YELLOW="$(printf '\033[33m')"
  CYAN="$(printf '\033[36m')"
  MAGENTA="$(printf '\033[35m')"
  BLUE="$(printf '\033[34m')"
  BOLD="$(printf '\033[1m')"
  DIM="$(printf '\033[2m')"
  RESET="$(printf '\033[0m')"
else
  RED=""
  GREEN=""
  YELLOW=""
  CYAN=""
  MAGENTA=""
  BLUE=""
  BOLD=""
  DIM=""
  RESET=""
fi

pause_menu() {
  echo
  read -r -p "按 Enter 返回..." _
}

term_cols() {
  local cols
  cols="$(tput cols 2>/dev/null || true)"
  if [ -z "${cols}" ] || [ "${cols}" -lt 80 ] 2>/dev/null; then
    cols=100
  fi
  printf '%s\n' "${cols}"
}

center_line() {
  local text="$1"
  local cols visible pad
  cols="$(term_cols)"
  visible="$(printf '%b' "${text}" | sed -E 's/\x1B\[[0-9;]*[[:alpha:]]//g')"
  pad=0
  if [ "${#visible}" -lt "${cols}" ]; then
    pad=$(( (cols - ${#visible}) / 2 ))
  fi
  printf '%*s%s\n' "${pad}" "" "${text}"
}

center_color_line() {
  local color="$1"
  local text="$2"
  center_line "${color}${text}${RESET}"
}

repeat_char() {
  local char="$1"
  local count="$2"
  printf '%*s' "${count}" '' | tr ' ' "${char}"
}

fit_text() {
  local text="$1"
  local limit="$2"
  if [ "${#text}" -le "${limit}" ]; then
    printf '%s' "${text}"
  else
    printf '%s...' "${text:0:$((limit - 3))}"
  fi
}

divider() {
  center_color_line "${DIM}${BLUE}" "--------------------------------------------------------------------"
}

render_box_line() {
  local color="$1"
  local text="$2"
  center_color_line "${color}" "  ${text}  "
}

render_triptych() {
  local left_color="$1"
  local left_text="$2"
  local center_color="$3"
  local center_text="$4"
  local right_color="$5"
  local right_text="$6"
  local composed
  composed="$(printf '%b%-18s%b  %b%-60s%b  %b%-18s%b' \
    "${left_color}" "${left_text}" "${RESET}" \
    "${center_color}" "${center_text}" "${RESET}" \
    "${right_color}" "${right_text}" "${RESET}")"
  center_line "${composed}"
}

geek_rain_line() {
  local side="$1"
  local frame="$2"
  local line="$3"
  local idx bg_idx bright dimmed
  local -a left_lines=(
    ' sudo systemctl up     '
    ' git status --short    '
    ' npm run build         '
    ' const MODE="prod";    '
    ' ssh root@edge-node    '
    ' docker ps --format    '
    ' tail -f gateway.log   '
    ' curl -fsSL api/health '
    ' if (ok) deploy();     '
    ' SELECT * FROM sessions'
    ' tmux attach -t aji    '
    ' chmod +x portal.sh    '
  )
  local -a right_lines=(
    ' codex resume --last   '
    ' claude -r session     '
    ' export OPENCLAW=1     '
    ' pnpm test --watch     '
    ' rsync -av prod/ test/ '
    ' git push origin main  '
    ' ./rollback-prod.sh    '
    ' jq . session.json     '
    ' watch -n 1 "ps aux"   '
    ' exec openclaw tui     '
    ' [ neon_bus == READY ] '
    ' while true; do :; done'
  )

  if [ "${frame}" -ge 4 ]; then
    case "${line}" in
      1) printf '%b\n' "${DIM}${BLUE}      ::          ${RESET}" ;;
      2) printf '%b\n' "${DIM}${BLUE}   << ${RESET}${GREEN}${BOLD}HELLO AI${RESET}${DIM}${BLUE} >>   ${RESET}" ;;
      3) printf '%b\n' "${DIM}${CYAN}   // ${RESET}${CYAN}${BOLD}NEON BUS${RESET}${DIM}${CYAN} //   ${RESET}" ;;
      4) printf '%b\n' "${DIM}${BLUE}   << ${RESET}${GREEN}${BOLD}HELLO AI${RESET}${DIM}${BLUE} >>   ${RESET}" ;;
      5) printf '%b\n' "${DIM}${CYAN}   << ${RESET}${YELLOW}${BOLD}READY${RESET}${DIM}${CYAN} >>      ${RESET}" ;;
      6) printf '%b\n' "${DIM}${BLUE}      ::          ${RESET}" ;;
      *) printf '%s\n' '' ;;
    esac
    return
  fi

  idx=$(( (line + frame - 2) % 12 ))
  bg_idx=$(( (line + frame * 2 - 2) % 12 ))
  if [ "${side}" = "left" ]; then
    dimmed="${left_lines[$bg_idx]}"
    bright="${left_lines[$idx]}"
    printf '%b\n' "${DIM}${BLUE}${dimmed:0:8}${RESET}${GREEN}${BOLD}${bright:8:12}${RESET}"
  else
    dimmed="${right_lines[$bg_idx]}"
    bright="${right_lines[$idx]}"
    printf '%b\n' "${DIM}${BLUE}${dimmed:0:8}${RESET}${CYAN}${BOLD}${bright:8:12}${RESET}"
  fi
}

lobster_trio_line() {
  local frame="$1"
  local line="$2"
  local open_claw close_claw
  local left_small right_small left_eye right_eye

  if [ $((frame % 2)) -eq 0 ]; then
    open_claw='\/'
    close_claw='/\'
    left_eye='oo'
    right_eye='OO'
  else
    open_claw='/\'
    close_claw='\/'
    left_eye='OO'
    right_eye='oo'
  fi

  case $((frame % 3)) in
    0) left_small='<>' ;;
    1) left_small='><' ;;
    2) left_small='{}' ;;
  esac
  case $(((frame + 1) % 3)) in
    0) right_small='<>' ;;
    1) right_small='><' ;;
    2) right_small='{}' ;;
  esac

  case "${line}" in
    1)
      printf '%b\n' "${DIM}${RED}  ${left_small}           ${RESET}${YELLOW}${BOLD}      __..====..__      ${RESET}${DIM}${RED}          ${right_small}${RESET}"
      ;;
    2)
      printf '%b\n' "${DIM}${RED} (${left_small})         ${RESET}${MAGENTA}${BOLD}${open_claw}${RED} .-========-. ${MAGENTA}${close_claw}${RESET}${DIM}${RED}         (${right_small})${RESET}"
      ;;
    3)
      printf '%b\n' "${DIM}${RED} /${left_small}\\         ${RESET}${RED}${BOLD}<   (${YELLOW}${left_eye}${RED})  (${YELLOW}${right_eye}${RED})   >${RESET}${DIM}${RED}         /${right_small}\\${RESET}"
      ;;
    4)
      printf '%b\n' "${DIM}${RED}/_==_\\        ${RESET}${RED}${BOLD} \\    .-====-.    / ${MAGENTA}${DIM}::depth::${RESET}${DIM}${RED}        /_==_\\${RESET}"
      ;;
    5)
      printf '%b\n' "${DIM}${RED}  ||           ${RESET}${RED}${BOLD}  \\/|__||__|\\/   ${MAGENTA}${DIM}/_/shadow\\_\\${RESET}${DIM}${RED}           ||${RESET}"
      ;;
    6)
      printf '%b\n' "${DIM}${RED} _/  \\_        ${RESET}${RED}${BOLD}   _/  ||  \\_    ${MAGENTA}${DIM}   v     v   ${RESET}${DIM}${RED}        _/  \\_${RESET}"
      ;;
    *) printf '%s\n' '' ;;
  esac
}

render_header_frame() {
  local frame="$1"
  local i

  center_color_line "${CYAN}${BOLD}" "CLAUDE CODE · CODEX · OPENCLAW"
  center_color_line "${BLUE}${DIM}" "Aji Super Individual Studio Portal · Neon Rain Console"
  center_color_line "${DIM}" "Code rain streaming on both rails · Triple lobster core online"
  echo
  for i in 1 2 3 4 5 6; do
    render_triptych \
      "" "$(geek_rain_line left "${frame}" "${i}")" \
      "${BOLD}" "$(lobster_trio_line "${frame}" "${i}")" \
      "" "$(geek_rain_line right "${frame}" "${i}")"
  done
  echo
  center_color_line "${MAGENTA}${BOLD}" "欢迎来到阿吉超级个体工作室"
}

play_intro() {
  local frame
  if [ ! -t 1 ]; then
    return
  fi
  for frame in 0 1 2 3 4; do
    clear
    render_header_frame "${frame}"
    sleep 0.06
  done
}

count_claude_sessions() {
  if [ -d "${AJI_CLAUDE_SESSION_META_DIR}" ]; then
    find "${AJI_CLAUDE_SESSION_META_DIR}" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' '
  else
    printf '0\n'
  fi
}

count_codex_sessions() {
  if [ -d "${AJI_CODEX_SESSIONS_DIR}" ]; then
    find "${AJI_CODEX_SESSIONS_DIR}" -type f 2>/dev/null | wc -l | tr -d ' '
  else
    printf '0\n'
  fi
}

binary_state() {
  local bin="$1"
  if [ -x "${bin}" ]; then
    printf '%bONLINE%b' "${GREEN}${BOLD}" "${RESET}"
  else
    printf '%bOFFLINE%b' "${RED}${BOLD}" "${RESET}"
  fi
}

render_portal_status() {
  local claude_count codex_count claude_state codex_state
  claude_count="$(count_claude_sessions)"
  codex_count="$(count_codex_sessions)"
  claude_state="$(binary_state "${CLAUDE_BIN}")"
  codex_state="$(binary_state "${CODEX_BIN}")"

  divider
  center_color_line "${CYAN}${BOLD}" "SYSTEM BUS"
  center_line "PORTAL_CWD  ${PORTAL_CWD}"
  center_line "CLAUDE  ${claude_state}   SESSIONS ${claude_count}        CODEX  ${codex_state}   SESSIONS ${codex_count}        OPENCLAW  ${GREEN}${BOLD}READY${RESET}"
  center_color_line "${DIM}" "NEON KEYS  [1] OPENCLAW   [2] CLAUDE CODE   [3] CODEX   [0] EXIT"
  divider
}

render_primary_cards() {
  render_box_line "${GREEN}${BOLD}"    "┌──────────────────────────────────────────────────────────────┐"
  render_box_line "${GREEN}${BOLD}"    "│ [1] OPENCLAW                                                │"
  render_box_line "${GREEN}"           "│ Runtime Control · PROD/TEST · TUI · Promote · Rollback      │"
  render_box_line "${GREEN}${BOLD}"    "└──────────────────────────────────────────────────────────────┘"
  echo
  render_box_line "${MAGENTA}${BOLD}"  "┌──────────────────────────────────────────────────────────────┐"
  render_box_line "${MAGENTA}${BOLD}"  "│ [2] CLAUDE CODE                                             │"
  render_box_line "${MAGENTA}"         "│ Recent Sessions · All Sessions · Continue · New Session     │"
  render_box_line "${MAGENTA}${BOLD}"  "└──────────────────────────────────────────────────────────────┘"
  echo
  render_box_line "${YELLOW}${BOLD}"   "┌──────────────────────────────────────────────────────────────┐"
  render_box_line "${YELLOW}${BOLD}"   "│ [3] CODEX                                                   │"
  render_box_line "${YELLOW}"          "│ Recent Sessions · All Sessions · Resume Last · New Session  │"
  render_box_line "${YELLOW}${BOLD}"   "└──────────────────────────────────────────────────────────────┘"
}

render_plain_primary_menu() {
  center_color_line "${BOLD}${CYAN}" "主菜单"
  center_line "1. OpenClaw"
  center_line "2. Claude Code"
  center_line "3. Codex"
  center_line "0. Exit"
}

render_footer_glow() {
  center_color_line "${DIM}${BLUE}" "$(repeat_char '=' 66)"
  center_color_line "${MAGENTA}${BOLD}" "欢迎来到阿吉超级个体工作室"
  center_color_line "${DIM}" "Type the index to dive into the next control layer"
}

run_openclaw_ctl() {
  echo
  bash "${SCRIPT_DIR}/openclawctl.sh" "$@"
  pause_menu
}

run_openclaw_tui() {
  local env_name="$1"
  local env_key="$2"
  echo
  echo "${CYAN}正在当前窗口启动 ${env_name} TUI...${RESET}"
  bash "${SCRIPT_DIR}/openclawctl.sh" tui "${env_key}"
  pause_menu
}

confirm_openclaw_promote() {
  local answer
  echo
  center_color_line "${YELLOW}${BOLD}" "这是生产提升操作，会先备份生产，再将 test 提升到 main。"
  read -r -p "请输入 YES 确认继续: " answer
  if [ "${answer}" = "YES" ]; then
    run_openclaw_ctl promote
  else
    echo "已取消生产提升。"
    pause_menu
  fi
}

confirm_openclaw_rollback() {
  local answer
  echo
  center_color_line "${YELLOW}${BOLD}" "这是生产回退操作，会恢复最近一次生产备份。"
  read -r -p "请输入 ROLLBACK 确认继续: " answer
  if [ "${answer}" = "ROLLBACK" ]; then
    run_openclaw_ctl rollback
  else
    echo "已取消生产回退。"
    pause_menu
  fi
}

run_claude() {
  if [ ! -x "${CLAUDE_BIN}" ]; then
    echo "Claude CLI not found: ${CLAUDE_BIN}" >&2
    pause_menu
    return
  fi
  "${CLAUDE_BIN}" "$@"
  pause_menu
}

run_codex() {
  if [ ! -x "${CODEX_BIN}" ]; then
    echo "Codex CLI not found: ${CODEX_BIN}" >&2
    pause_menu
    return
  fi
  "${CODEX_BIN}" "$@"
  pause_menu
}

list_claude_sessions() {
  local out_file="$1"
  local limit="${2:-20}"
  if [ ! -d "${AJI_CLAUDE_SESSION_META_DIR}" ]; then
    : > "${out_file}"
    return
  fi
  AJI_CLAUDE_META_DIR="${AJI_CLAUDE_SESSION_META_DIR}" python3 - "$out_file" "$limit" "${PORTAL_CWD}" <<'PY'
import json, pathlib, sys
import os
out = pathlib.Path(sys.argv[1])
limit = int(sys.argv[2])
current = pathlib.Path(sys.argv[3]).resolve()
meta_dir = pathlib.Path(os.environ["AJI_CLAUDE_META_DIR"])
rows = []

def rank_path(value: str) -> int:
    try:
        p = pathlib.Path(value).resolve()
    except Exception:
        return 3
    if p == current:
        return 0
    if str(p).startswith(str(current) + "/"):
        return 1
    if str(current).startswith(str(p) + "/"):
        return 2
    return 3

for path in meta_dir.glob("*.json"):
    try:
        data = json.loads(path.read_text())
    except Exception:
        continue
    project = data.get("project_path", "-")
    rows.append({
        "id": data.get("session_id", path.stem),
        "project": project,
        "time": data.get("start_time", "-"),
        "prompt": (data.get("first_prompt") or "").replace("\n", " ").strip(),
        "rank": rank_path(project),
    })
rows.sort(key=lambda r: (r["rank"], r["time"]), reverse=True)
rows.sort(key=lambda r: r["rank"])
if limit > 0:
    rows = rows[:limit]
with out.open("w", encoding="utf-8") as fh:
    for row in rows:
        fh.write(json.dumps(row, ensure_ascii=False) + "\n")
PY
}

list_codex_sessions() {
  local out_file="$1"
  local limit="${2:-20}"
  if [ ! -d "${AJI_CODEX_SESSIONS_DIR}" ]; then
    : > "${out_file}"
    return
  fi
  AJI_CODEX_SESSIONS_DIR="${AJI_CODEX_SESSIONS_DIR}" python3 - "$out_file" "$limit" "${PORTAL_CWD}" <<'PY'
import json, pathlib, sys
import os
out = pathlib.Path(sys.argv[1])
limit = int(sys.argv[2])
current = pathlib.Path(sys.argv[3]).resolve()
root = pathlib.Path(os.environ["AJI_CODEX_SESSIONS_DIR"])
rows = []

def rank_path(value: str) -> int:
    try:
        p = pathlib.Path(value).resolve()
    except Exception:
        return 3
    if p == current:
        return 0
    if str(p).startswith(str(current) + "/"):
        return 1
    if str(current).startswith(str(p) + "/"):
        return 2
    return 3

for path in root.rglob("*.jsonl"):
    try:
        first = path.open("r", encoding="utf-8").readline()
        data = json.loads(first)
        payload = data.get("payload", {})
    except Exception:
        continue
    cwd = payload.get("cwd", "-")
    rows.append({
        "id": payload.get("id", path.stem),
        "cwd": cwd,
        "time": payload.get("timestamp", data.get("timestamp", "-")),
        "name": path.stem,
        "rank": rank_path(cwd),
    })
rows.sort(key=lambda r: (r["rank"], r["time"]), reverse=True)
rows.sort(key=lambda r: r["rank"])
if limit > 0:
    rows = rows[:limit]
with out.open("w", encoding="utf-8") as fh:
    for row in rows:
        fh.write(json.dumps(row, ensure_ascii=False) + "\n")
PY
}

render_session_table() {
  local kind="$1"
  local file="$2"
  local start_line="$3"
  local limit="$4"
  local end_line
  local index=1
  local line id path_text time_text desc_text rank mark
  local header

  end_line=$((start_line + limit - 1))

  if [ "${kind}" = "claude" ]; then
    header="$(printf '| %-3s | %-1s | %-8s | %-18s | %-19s | %-26s |' 'No' 'R' 'Session' 'Project' 'Start Time' 'First Prompt')"
  else
    header="$(printf '| %-3s | %-1s | %-8s | %-18s | %-19s | %-26s |' 'No' 'R' 'Session' 'Workspace' 'Start Time' 'Thread')"
  fi
  center_color_line "${DIM}${BLUE}" "$(printf '%*s' "${#header}" '' | tr ' ' '-')"
  center_color_line "${CYAN}${BOLD}" "${header}"
  center_color_line "${DIM}${BLUE}" "$(printf '%*s' "${#header}" '' | tr ' ' '-')"

  while IFS= read -r line; do
    [ -n "${line}" ] || continue
    if [ "${kind}" = "claude" ]; then
      id="$(python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); print(d["id"])' <<<"${line}")"
      path_text="$(python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); print(d["project"])' <<<"${line}")"
      time_text="$(python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); print(d["time"])' <<<"${line}")"
      desc_text="$(python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); print(d["prompt"])' <<<"${line}")"
      rank="$(python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); print(d.get("rank", 3))' <<<"${line}")"
    else
      id="$(python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); print(d["id"])' <<<"${line}")"
      path_text="$(python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); print(d["cwd"])' <<<"${line}")"
      time_text="$(python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); print(d["time"])' <<<"${line}")"
      desc_text="$(python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); print(d["name"])' <<<"${line}")"
      rank="$(python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); print(d.get("rank", 3))' <<<"${line}")"
    fi
    if [ "${rank}" = "0" ]; then
      mark="*"
    elif [ "${rank}" = "1" ] || [ "${rank}" = "2" ]; then
      mark="+"
    else
      mark=" "
    fi
    path_text="$(basename "${path_text}")"
    path_text="$(fit_text "${path_text}" 18)"
    desc_text="$(fit_text "${desc_text}" 26)"
    center_line "$(printf '| %-3s | %-1s | %-8s | %-18s | %-19s | %-26s |' "${index}" "${mark}" "${id:0:8}" "${path_text}" "${time_text:0:19}" "${desc_text}")"
    index=$((index + 1))
  done < <(sed -n "${start_line},${end_line}p" "${file}")
  center_color_line "${DIM}${BLUE}" "$(printf '%*s' "${#header}" '' | tr ' ' '-')"
}

pick_claude_session() {
  local scope="${1:-recent}"
  local sessions_file="${TMP_DIR}/claude-sessions.jsonl"
  local count choice selected_line selected_id
  local page total_pages page_start global_index page_count
  local title_text

  if [ "${scope}" = "all" ]; then
    list_claude_sessions "${sessions_file}" 0
    title_text="Claude Code All Sessions"
  else
    list_claude_sessions "${sessions_file}" 20
    title_text="Claude Code Recent Sessions"
  fi
  count="$(wc -l < "${sessions_file}" | tr -d ' ')"
  if [ "${count}" = "0" ]; then
    echo "未找到 Claude Code session。"
    pause_menu
    return
  fi
  total_pages=$(( (count + PAGE_SIZE - 1) / PAGE_SIZE ))
  page=1

  while true; do
    page_start=$(( (page - 1) * PAGE_SIZE + 1 ))
    page_count=$(( count - page_start + 1 ))
    if [ "${page_count}" -gt "${PAGE_SIZE}" ]; then
      page_count="${PAGE_SIZE}"
    fi

    clear
    render_header_frame 4
    divider
    center_color_line "${BOLD}${CYAN}" "${title_text}"
    center_color_line "${DIM}" "编号 / Session / Project / Start Time / First Prompt"
    center_color_line "${DIM}" "R 列说明: * 当前目录完全匹配, + 当前目录相关"
    center_color_line "${YELLOW}" "第 ${page}/${total_pages} 页，共 ${count} 条"
    divider
    render_session_table claude "${sessions_file}" "${page_start}" "${PAGE_SIZE}"
    divider
    center_line "输入当前页编号恢复会话，输入 [ 上一页，] 下一页，c 继续当前目录最近会话，n 新建，b 返回"
    echo
    read -r -p "请选择: " choice

    case "${choice}" in
      b|B) return ;;
      c|C) run_claude -c; return ;;
      n|N) run_claude; return ;;
      "[")
        if [ "${page}" -gt 1 ]; then
          page=$((page - 1))
        fi
        continue
        ;;
      "]")
        if [ "${page}" -lt "${total_pages}" ]; then
          page=$((page + 1))
        fi
        continue
        ;;
    esac

    if ! [[ "${choice}" =~ ^[0-9]+$ ]]; then
      echo "无效输入: ${choice}"
      pause_menu
      continue
    fi

    if [ "${choice}" -lt 1 ] || [ "${choice}" -gt "${page_count}" ]; then
      echo "编号超出当前页范围"
      pause_menu
      continue
    fi

    global_index=$(( page_start + choice - 1 ))
    selected_line="$(sed -n "${global_index}p" "${sessions_file}")"
    selected_id="$(python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); print(d["id"])' <<<"${selected_line}")"
    run_claude -r "${selected_id}"
    return
  done
}

pick_codex_session() {
  local scope="${1:-recent}"
  local sessions_file="${TMP_DIR}/codex-sessions.jsonl"
  local count choice selected_line selected_id
  local page total_pages page_start global_index page_count
  local title_text

  if [ "${scope}" = "all" ]; then
    list_codex_sessions "${sessions_file}" 0
    title_text="Codex All Sessions"
  else
    list_codex_sessions "${sessions_file}" 20
    title_text="Codex Recent Sessions"
  fi
  count="$(wc -l < "${sessions_file}" | tr -d ' ')"
  if [ "${count}" = "0" ]; then
    echo "未找到 Codex session。"
    pause_menu
    return
  fi
  total_pages=$(( (count + PAGE_SIZE - 1) / PAGE_SIZE ))
  page=1

  while true; do
    page_start=$(( (page - 1) * PAGE_SIZE + 1 ))
    page_count=$(( count - page_start + 1 ))
    if [ "${page_count}" -gt "${PAGE_SIZE}" ]; then
      page_count="${PAGE_SIZE}"
    fi

    clear
    render_header_frame 4
    divider
    center_color_line "${BOLD}${CYAN}" "${title_text}"
    center_color_line "${DIM}" "编号 / Session / CWD / Start Time / File"
    center_color_line "${DIM}" "R 列说明: * 当前目录完全匹配, + 当前目录相关"
    center_color_line "${YELLOW}" "第 ${page}/${total_pages} 页，共 ${count} 条"
    divider
    render_session_table codex "${sessions_file}" "${page_start}" "${PAGE_SIZE}"
    divider
    center_line "输入当前页编号恢复会话，输入 [ 上一页，] 下一页，l 恢复最近一次，n 新建，b 返回"
    echo
    read -r -p "请选择: " choice

    case "${choice}" in
      b|B) return ;;
      l|L) run_codex resume --last; return ;;
      n|N) run_codex; return ;;
      "[")
        if [ "${page}" -gt 1 ]; then
          page=$((page - 1))
        fi
        continue
        ;;
      "]")
        if [ "${page}" -lt "${total_pages}" ]; then
          page=$((page + 1))
        fi
        continue
        ;;
    esac

    if ! [[ "${choice}" =~ ^[0-9]+$ ]]; then
      echo "无效输入: ${choice}"
      pause_menu
      continue
    fi

    if [ "${choice}" -lt 1 ] || [ "${choice}" -gt "${page_count}" ]; then
      echo "编号超出当前页范围"
      pause_menu
      continue
    fi

    global_index=$(( page_start + choice - 1 ))
    selected_line="$(sed -n "${global_index}p" "${sessions_file}")"
    selected_id="$(python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); print(d["id"])' <<<"${selected_line}")"
    run_codex resume "${selected_id}"
    return
  done
}

openclaw_menu() {
  while true; do
    clear
    render_header_frame 4
    divider
    center_color_line "${BOLD}${CYAN}" "OpenClaw"
    divider
    center_line "1. 启动生产环境"
    center_line "2. 停止生产环境"
    center_line "3. 启动测试环境"
    center_line "4. 停止测试环境"
    center_line "5. 查看当前状态"
    center_line "6. 打开生产环境 TUI"
    center_line "7. 打开测试环境 TUI"
    center_line "8. 测试提升到生产"
    center_line "9. 回退到最近一次生产备份"
    center_line "0. 返回上一级"
    divider
    center_color_line "${MAGENTA}${BOLD}" "欢迎来到阿吉超级个体工作室"
    echo
    read -r -p "请选择 [0-9]: " choice
    case "${choice}" in
      1) run_openclaw_ctl start prod ;;
      2) run_openclaw_ctl stop prod ;;
      3) run_openclaw_ctl start test ;;
      4) run_openclaw_ctl stop test ;;
      5) run_openclaw_ctl status ;;
      6) run_openclaw_tui "生产环境" prod ;;
      7) run_openclaw_tui "测试环境" test ;;
      8) confirm_openclaw_promote ;;
      9) confirm_openclaw_rollback ;;
      0) return ;;
      *) echo "无效输入: ${choice}"; pause_menu ;;
    esac
  done
}

claude_menu() {
  while true; do
    clear
    render_header_frame 4
    divider
    center_color_line "${BOLD}${CYAN}" "Claude Code"
    divider
    center_line "1. 选择最近 Session"
    center_line "2. 选择全部 Session"
    center_line "3. 继续当前目录最近会话"
    center_line "4. 新建 Claude 会话"
    center_line "0. 返回上一级"
    divider
    center_color_line "${MAGENTA}${BOLD}" "欢迎来到阿吉超级个体工作室"
    echo
    read -r -p "请选择 [0-4]: " choice
    case "${choice}" in
      1) pick_claude_session recent ;;
      2) pick_claude_session all ;;
      3) run_claude -c ;;
      4) run_claude ;;
      0) return ;;
      *) echo "无效输入: ${choice}"; pause_menu ;;
    esac
  done
}

codex_menu() {
  while true; do
    clear
    render_header_frame 4
    divider
    center_color_line "${BOLD}${CYAN}" "Codex"
    divider
    center_line "1. 选择最近 Session"
    center_line "2. 选择全部 Session"
    center_line "3. 恢复最近一次会话"
    center_line "4. 新建 Codex 会话"
    center_line "0. 返回上一级"
    divider
    center_color_line "${MAGENTA}${BOLD}" "欢迎来到阿吉超级个体工作室"
    echo
    read -r -p "请选择 [0-4]: " choice
    case "${choice}" in
      1) pick_codex_session recent ;;
      2) pick_codex_session all ;;
      3) run_codex resume --last ;;
      4) run_codex ;;
      0) return ;;
      *) echo "无效输入: ${choice}"; pause_menu ;;
    esac
  done
}

main_menu() {
  while true; do
    play_intro
    clear
    render_header_frame 4
    render_portal_status
    render_primary_cards
    divider
    render_plain_primary_menu
    divider
    center_color_line "${CYAN}${BOLD}" "快捷键入口"
    center_line "[1] OpenClaw        [2] Claude Code        [3] Codex        [0] Exit"
    render_footer_glow
    echo
    read -r -p "请选择 [0-3]: " choice
    case "${choice}" in
      1) openclaw_menu ;;
      2) claude_menu ;;
      3) codex_menu ;;
      0) exit 0 ;;
      *) echo "无效输入: ${choice}"; pause_menu ;;
    esac
  done
}

main_menu
