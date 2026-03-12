#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_SKILLS="${SKILLS_WORKSPACE_DIR:-/root/.openclaw/workspace/skills}"
REPO_SKILLS="${SKILLS_REPO_DIR:-/root/hanji/openclaw/skills}"
OPENCLAW_JSON="${SKILLS_OPENCLAW_JSON:-/root/.openclaw-test/openclaw.json}"
OUT="${SKILLS_DATA_OUT:-/root/.openclaw-test/workspace/canvas/skills/data/skills.json}"

mkdir -p "$(dirname "$OUT")"

DISABLED_LIST=""
if [ -f "$OPENCLAW_JSON" ]; then
  DISABLED_LIST=$(python3 -c "
import json
try:
  cfg=json.load(open('$OPENCLAW_JSON'))
  sc=cfg.get('skills',{}).get('config',{})
  print(' '.join(k for k,v in sc.items() if isinstance(v,dict) and v.get('enabled') is False))
except Exception:
  pass
" 2>/dev/null || echo "")
fi

declare -A CAT_MAP=(
  [sunswap]=defi [gate]=defi [binance]=defi [binance-web3]=defi
  [bitget-wallet]=defi [x402-payment]=defi [x402-payment-demo]=defi
  [finance_expert]=finance [us-value-investing]=finance [us-market-sentiment]=finance
  [tech-earnings-deepdive]=finance [macro-liquidity]=finance [btc-bottom-model]=finance
  [openbb_connector]=finance
  [clawfeed]=data [opentwitter-mcp]=data [x-tweet-fetcher]=data
  [polymarket_cli]=data [scholargraph]=data [okx_market]=data [finance_data]=data
  [8004-skill]=system [cc-worktree]=system [claude-cli]=system
  [magic_commands]=system [skill-vetter]=system [command-repair]=system
  [self_learning]=system [multi_agent]=system
  [embodied_intelligence]=ai [qveris]=ai
)

declare -A EMOJI_MAP=(
  [sunswap]="🔄" [gate]="🏦" [binance]="🟡" [binance-web3]="🌐"
  [bitget-wallet]="👛" [x402-payment]="💳" [x402-payment-demo]="🖼️"
  [finance_expert]="💹" [us-value-investing]="📈" [us-market-sentiment]="🎭"
  [tech-earnings-deepdive]="📑" [macro-liquidity]="💧" [btc-bottom-model]="₿"
  [openbb_connector]="📡" [clawfeed]="☀️" [opentwitter-mcp]="🐦"
  [x-tweet-fetcher]="📥" [polymarket_cli]="🎲" [scholargraph]="🎓"
  [okx_market]="📊" [8004-skill]="🔗" [cc-worktree]="💻" [claude-cli]="🤖"
  [magic_commands]="✨" [skill-vetter]="🔒" [command-repair]="🔧"
  [self_learning]="📚" [multi_agent]="👥" [embodied_intelligence]="🦾"
  [qveris]="🔮" [finance_data]="💰"
)

extract_field() {
  local file="$1" field="$2"
  awk -v f="$field" '/^---$/{if(n++)exit} n && $0 ~ "^"f":"{sub("^"f":[[:space:]]*","");gsub(/"/,"");print;exit}' "$file"
}

extract_desc() {
  local file="$1"
  local desc
  desc=$(extract_field "$file" "description")
  if [ -z "$desc" ]; then
    desc=$(awk '/^#/{getline;if(NF>0){gsub(/"/,"\\\"");print;exit}}' "$file")
  fi
  [ -z "$desc" ] && desc="No description"
  echo "$desc" | cut -c1-200
}

cat > "$OUT" <<HEADER
{
  "generated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "categories": {
    "defi":    {"label":"DeFi/交易","color":"#00ff88","emoji":"💱"},
    "finance": {"label":"金融分析","color":"#ffd700","emoji":"📊"},
    "data":    {"label":"数据/研究","color":"#00f0ff","emoji":"🔍"},
    "system":  {"label":"系统/工具","color":"#ff00ff","emoji":"⚙️"},
    "ai":      {"label":"AI体验","color":"#ff6b35","emoji":"🤖"}
  },
  "skills": [
HEADER

FIRST=1

process_skill() {
  local skilldir="$1" status="$2"
  local id
  id=$(basename "$skilldir")

  local mdfile=""
  [ -f "$skilldir/SKILL.md" ] && mdfile="$skilldir/SKILL.md"
  [ -z "$mdfile" ] && [ -f "$skilldir/README.md" ] && mdfile="$skilldir/README.md"
  [ -z "$mdfile" ] && return 1

  local name desc version tags cat_id emoji name_escaped desc_escaped
  name=$(extract_field "$mdfile" "name")
  [ -z "$name" ] && name="$id"
  desc=$(extract_desc "$mdfile")
  version=$(extract_field "$mdfile" "version")
  [ -z "$version" ] && version="1.0"
  tags=$(awk '/^---$/{if(n++)exit}n&&/^tags:.*\[/{match($0,/\[.*\]/);s=substr($0,RSTART+1,RLENGTH-2);gsub(/,\s*/,"\",\"",s);print "[\""s"\"]";exit}' "$mdfile")
  [ -z "$tags" ] && tags="[]"

  if [ "$status" = "installed" ] && echo " $DISABLED_LIST " | grep -q " $id "; then
    status="disabled"
  fi

  cat_id=${CAT_MAP[$id]:-system}
  emoji=${EMOJI_MAP[$id]:-"⚡"}
  name_escaped=$(echo "$name" | sed 's/\\/\\\\/g;s/"/\\"/g' | tr -d '\n')
  desc_escaped=$(echo "$desc" | sed 's/\\/\\\\/g;s/"/\\"/g;s/\t/ /g' | tr -d '\n')

  [ "$FIRST" -eq 0 ] && echo '    ,' >> "$OUT"
  FIRST=0

  cat >> "$OUT" <<ITEM
    {
      "id": "$id",
      "name": "$name_escaped",
      "emoji": "$emoji",
      "version": "$version",
      "description": "$desc_escaped",
      "category": "$cat_id",
      "tags": $tags,
      "status": "$status",
      "path": "$id/SKILL.md"
    }
ITEM
}

if [ -d "$WORKSPACE_SKILLS" ]; then
  for skilldir in "$WORKSPACE_SKILLS"/*/; do
    [ -d "$skilldir" ] || continue
    id=$(basename "$skilldir")
    [[ "$id" == "__pycache__" || "$id" == "node_modules" ]] && continue
    process_skill "$skilldir" "installed" || true
  done
fi

if [ -d "$REPO_SKILLS" ]; then
  declare -A INSTALLED_SET
  if [ -d "$WORKSPACE_SKILLS" ]; then
    for skilldir in "$WORKSPACE_SKILLS"/*/; do
      [ -d "$skilldir" ] || continue
      INSTALLED_SET[$(basename "$skilldir")]=1
    done
  fi

  for skilldir in "$REPO_SKILLS"/*/; do
    [ -d "$skilldir" ] || continue
    id=$(basename "$skilldir")
    [[ "$id" == "__pycache__" || "$id" == "node_modules" ]] && continue
    [ -n "${INSTALLED_SET[$id]:-}" ] && continue
    process_skill "$skilldir" "available" || true
  done
fi

cat >> "$OUT" <<FOOTER
  ]
}
FOOTER

echo "Generated $(grep -c '\"id\"' "$OUT") skills -> $OUT"
