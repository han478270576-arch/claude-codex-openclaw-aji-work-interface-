#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_SKILLS="/root/.openclaw/workspace/skills"
REPO_SKILLS="/root/hanji/openclaw/skills"
OPENCLAW_JSON="/root/.openclaw-test/openclaw.json"
OUT="/root/.openclaw-test/workspace/canvas/skills/data/skills.json"

mkdir -p "$(dirname "$OUT")"

# Read disabled skills from openclaw.json
DISABLED_LIST=""
if [ -f "$OPENCLAW_JSON" ]; then
  DISABLED_LIST=$(python3 -c "
import json,sys
try:
  cfg=json.load(open('$OPENCLAW_JSON'))
  sc=cfg.get('skills',{}).get('config',{})
  print(' '.join(k for k,v in sc.items() if isinstance(v,dict) and v.get('enabled') is False))
except: pass
" 2>/dev/null || echo "")
fi

# Category mapping
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

# Emoji mapping
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

# Collect all installed skill IDs
declare -A INSTALLED_SET
if [ -d "$WORKSPACE_SKILLS" ]; then
  for d in "$WORKSPACE_SKILLS"/*/; do
    [ -d "$d" ] || continue
    sid=$(basename "$d")
    [[ "$sid" == "__pycache__" || "$sid" == "node_modules" ]] && continue
    INSTALLED_SET[$sid]=1
  done
fi

# Collect repo skill IDs
declare -A REPO_SET
if [ -d "$REPO_SKILLS" ]; then
  for d in "$REPO_SKILLS"/*/; do
    [ -d "$d" ] || continue
    sid=$(basename "$d")
    [[ "$sid" == "__pycache__" || "$sid" == "node_modules" ]] && continue
    REPO_SET[$sid]=1
  done
fi

# Helper: extract field from YAML frontmatter
extract_field() {
  local file="$1" field="$2"
  awk -v f="$field" '/^---$/{if(n++)exit} n && $0 ~ "^"f":"{sub("^"f":[[:space:]]*","");gsub(/"/,"");print;exit}' "$file"
}

# Helper: extract description
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

# Start JSON
cat > "$OUT" << HEADER
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

# Process a skill directory
process_skill() {
  local skilldir="$1" status="$2"
  local id=$(basename "$skilldir")

  local MDFILE=""
  [ -f "$skilldir/SKILL.md" ] && MDFILE="$skilldir/SKILL.md"
  [ -z "$MDFILE" ] && [ -f "$skilldir/README.md" ] && MDFILE="$skilldir/README.md"
  [ -z "$MDFILE" ] && return 1

  local name=$(extract_field "$MDFILE" "name")
  [ -z "$name" ] && name="$id"
  local desc=$(extract_desc "$MDFILE")
  local version=$(extract_field "$MDFILE" "version")
  [ -z "$version" ] && version="1.0"
  local tags=$(awk '/^---$/{if(n++)exit}n&&/^tags:.*\[/{match($0,/\[.*\]/);s=substr($0,RSTART+1,RLENGTH-2);gsub(/,\s*/,"\",\"",s);print "[\""s"\"]";exit}' "$MDFILE")
  [ -z "$tags" ] && tags="[]"

  # Check disabled
  if [ "$status" = "installed" ] && echo " $DISABLED_LIST " | grep -q " $id "; then
    status="disabled"
  fi

  local cat_id=${CAT_MAP[$id]:-system}
  local emoji=${EMOJI_MAP[$id]:-"⚡"}
  local desc_escaped=$(echo "$desc" | sed 's/\\/\\\\/g;s/"/\\"/g;s/\t/ /g' | tr -d '\n')
  local name_escaped=$(echo "$name" | sed 's/\\/\\\\/g;s/"/\\"/g' | tr -d '\n')

  [ $FIRST -eq 0 ] && echo '    ,' >> "$OUT"
  FIRST=0

  cat >> "$OUT" << ITEMEOF
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
ITEMEOF
}

# 1) Process installed skills
for skilldir in "$WORKSPACE_SKILLS"/*/; do
  [ -d "$skilldir" ] || continue
  id=$(basename "$skilldir")
  [[ "$id" == "__pycache__" || "$id" == "node_modules" ]] && continue
  process_skill "$skilldir" "installed" || true
done

# 2) Process available (repo only, not installed)
for skilldir in "$REPO_SKILLS"/*/; do
  [ -d "$skilldir" ] || continue
  id=$(basename "$skilldir")
  [[ "$id" == "__pycache__" || "$id" == "node_modules" ]] && continue
  [ -n "${INSTALLED_SET[$id]:-}" ] && continue
  process_skill "$skilldir" "available" || true
done

cat >> "$OUT" << FOOTER
  ]
}
FOOTER

echo "Generated $(grep -c '"id"' "$OUT") skills -> $OUT"
