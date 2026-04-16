#!/bin/bash
# エージェント・スキルマップを自動生成するスクリプト
# pre-commit フックから呼び出される
#
# 組織階層はこのスクリプト内で定義する。
# エージェントを追加した場合はこのスクリプトも更新すること。

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AGENTS_DIR="$REPO_ROOT/.claude/agents"
OUTPUT="$REPO_ROOT/AGENT_MAP.md"

# ── 集計 ──────────────────────────────────────────
agent_count=0
skill_count=0
for agent_dir in "$AGENTS_DIR"/*/; do
  [ -d "$agent_dir" ] || continue
  agent_count=$((agent_count + 1))
  for skill in "$agent_dir"/skills/*.md; do
    [ -f "$skill" ] || continue
    [ "$(basename "$skill")" = "README.md" ] && continue
    skill_count=$((skill_count + 1))
  done
done

# ── ヘルパー関数 ──────────────────────────────────

# CLAUDE.md のタイトル行から神名を取得
get_name() {
  head -1 "$AGENTS_DIR/$1/CLAUDE.md" 2>/dev/null | sed 's/^# //' | sed 's/ — .*//'
}

# CLAUDE.md のタイトル行から役職を取得
get_role() {
  head -1 "$AGENTS_DIR/$1/CLAUDE.md" 2>/dev/null | sed 's/^# //' | sed 's/.* — //'
}

# CLAUDE.md 3行目から日本語神名を取得
get_myth() {
  sed -n '3p' "$AGENTS_DIR/$1/CLAUDE.md" 2>/dev/null | grep -o '（[^）]*）' | head -1 | tr -d '（）' || true
}

# エージェント1行を出力: prefix, dir, is_last
print_agent() {
  local prefix="$1" dir="$2" is_last="$3"
  local name role myth label line_char line_str line_len

  name=$(get_name "$dir")
  role=$(get_role "$dir")
  myth=$(get_myth "$dir")
  label="${name}（${role}）"

  line_len=$((30 - ${#label}))
  [ "$line_len" -lt 2 ] && line_len=2
  line_str=""
  for ((i=0; i<line_len; i++)); do line_str="${line_str}─"; done

  if [ "$is_last" = "1" ]; then
    line_char="└"
  else
    line_char="├"
  fi

  printf '%s%s── %s %s %s\n' "$prefix" "$line_char" "$label" "$line_str" "$myth"
}

# スキル一覧を出力: prefix, dir
print_skills() {
  local prefix="$1" dir="$2"
  local skills_dir="$AGENTS_DIR/$dir/skills"
  [ -d "$skills_dir" ] || return

  local skills=()
  for skill in "$skills_dir"/*.md; do
    [ -f "$skill" ] || continue
    [ "$(basename "$skill")" = "README.md" ] && continue
    skills+=("$skill")
  done

  local total=${#skills[@]} i=0
  for skill in "${skills[@]}"; do
    i=$((i + 1))
    local skill_name skill_title
    skill_name=$(basename "$skill" .md)
    skill_title=$(head -1 "$skill" 2>/dev/null | sed 's/^# //' | sed 's/ *（.*）//')

    if [ "$i" -eq "$total" ]; then
      printf '%s└── %-28s%s\n' "$prefix" "$skill_name" "$skill_title"
    else
      printf '%s├── %-28s%s\n' "$prefix" "$skill_name" "$skill_title"
    fi
  done
}

# エージェント + スキルをまとめて出力
print_agent_block() {
  local prefix="$1" dir="$2" is_last="$3"
  local child_prefix

  print_agent "$prefix" "$dir" "$is_last"

  if [ "$is_last" = "1" ]; then
    child_prefix="${prefix}    "
  else
    child_prefix="${prefix}│   "
  fi
  print_skills "$child_prefix" "$dir"
}

# ── 出力生成 ──────────────────────────────────────
{
  cat << HEADER
<!-- このファイルは scripts/generate-agent-map.sh により自動生成されます。直接編集しないでください。 -->

# エージェント・スキルマップ

${agent_count} エージェント / ${skill_count} スキル

\`\`\`text
RYOTA（CEO）
│
HEADER

  # ── CEO 直属: 秘書 ──
  print_agent_block "" "secretary" "0"
  echo "│"

  # ── CxO ──
  echo "└── CxO"
  echo "    │"

  # CxO メンバー
  for dir in cto coo cfo cso cmo cdo; do
    print_agent_block "    " "$dir" "0"
    echo "    │"
  done

  # ── 経営企画 ──
  echo "    ├── 経営企画"
  echo "    │   │"
  print_agent_block "    │   " "corporate-planning" "1"
  echo "    │"

  # ── プロダクトデザインチーム ──
  echo "    ├── プロダクトデザインチーム"
  echo "    │   │"
  print_agent_block "    │   " "pdm" "0"
  echo "    │   │"
  print_agent_block "    │   " "designer" "1"
  echo "    │"

  # ── 開発チーム ──
  echo "    ├── 開発チーム"
  echo "    │   │"
  print_agent_block "    │   " "backend-engineer" "0"
  echo "    │   │"
  print_agent_block "    │   " "frontend-engineer" "0"
  echo "    │   │"
  print_agent_block "    │   " "infra-engineer" "1"
  echo "    │"

  # ── QA チーム ──
  echo "    └── QAチーム"
  echo "        │"
  print_agent_block "        " "qa-engineer" "0"
  echo "        │"
  print_agent_block "        " "security-engineer" "0"
  echo "        │"
  print_agent_block "        " "tester" "1"

  echo '```'

} > "$OUTPUT"

echo "AGENT_MAP.md を更新しました（${agent_count} エージェント / ${skill_count} スキル）"
