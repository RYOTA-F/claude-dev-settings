#!/bin/bash
# エージェント・スキルマップを自動生成するスクリプト
# pre-commit フックから呼び出される
#
# 組織構造の定義もこのスクリプト内で管理する。
# エージェントを追加した場合は ORGANIZATION 配列にも追加すること。

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AGENTS_DIR="$REPO_ROOT/.claude/agents"
OUTPUT="$REPO_ROOT/AGENT_MAP.md"

# ── 組織構造定義 ──────────────────────────────────
# 形式: "セクション種別|ディレクトリ名"
#   HEADER:  セクション見出し（├ 直属 / 組織グループ）
#   AGENT:   エージェント
#   FOOTER:  セクション閉じ
#   BLANK:   空行
ORGANIZATION=(
  "AGENT|secretary"
  "AGENT|corporate-planning"
  "BLANK|"
  "HEADER|CxO"
  "AGENT|cto"
  "AGENT|coo"
  "AGENT|cfo"
  "AGENT|cso"
  "AGENT|cmo"
  "AGENT|cdo"
  "FOOTER|"
  "BLANK|"
  "HEADER|プロダクト・デザイン組織"
  "AGENT|pdm"
  "AGENT|designer"
  "FOOTER|"
  "BLANK|"
  "HEADER|開発組織"
  "AGENT|backend-engineer"
  "AGENT|frontend-engineer"
  "AGENT|infra-engineer"
  "FOOTER|"
  "BLANK|"
  "HEADER|監査組織"
  "AGENT|qa-engineer"
  "AGENT|security-engineer"
  "AGENT|tester"
  "FOOTER|"
)

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
get_title() {
  local dir="$1"
  head -1 "$AGENTS_DIR/$dir/CLAUDE.md" 2>/dev/null | sed 's/^# //'
}

get_subtitle() {
  local dir="$1"
  local title
  title=$(get_title "$dir")
  # "Name — Role" から Name 部分を抽出
  echo "$title" | sed 's/ — .*//'
}

get_role() {
  local dir="$1"
  local title
  title=$(get_title "$dir")
  echo "$title" | sed 's/.* — //'
}

# エージェントの神話由来を CLAUDE.md 2行目から取得（なければ空）
get_myth() {
  local dir="$1"
  local line3
  line3=$(sed -n '3p' "$AGENTS_DIR/$dir/CLAUDE.md" 2>/dev/null)
  # "あなたは **Name**（Japanese）。..." からカッコ内を抽出
  echo "$line3" | grep -o '（[^）]*）' | head -1 | tr -d '（）' || true
}

print_skills() {
  local dir="$1"
  local prefix="$2"
  local skills_dir="$AGENTS_DIR/$dir/skills"
  [ -d "$skills_dir" ] || return

  local skills=()
  for skill in "$skills_dir"/*.md; do
    [ -f "$skill" ] || continue
    [ "$(basename "$skill")" = "README.md" ] && continue
    skills+=("$skill")
  done

  local total=${#skills[@]}
  local i=0
  for skill in "${skills[@]}"; do
    i=$((i + 1))
    local skill_name
    skill_name=$(basename "$skill" .md)
    local skill_title
    skill_title=$(head -1 "$skill" 2>/dev/null | sed 's/^# //' | sed 's/ *（.*）//')

    if [ "$i" -eq "$total" ]; then
      printf '%s└── %-28s%s\n' "$prefix" "$skill_name" "$skill_title"
    else
      printf '%s├── %-28s%s\n' "$prefix" "$skill_name" "$skill_title"
    fi
  done
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

  in_section=false
  section_name=""

  # 最後の AGENT エントリのインデックスを特定
  last_agent_idx=-1
  for ((idx=0; idx<${#ORGANIZATION[@]}; idx++)); do
    entry="${ORGANIZATION[$idx]}"
    [ "${entry%%|*}" = "AGENT" ] && last_agent_idx=$idx
  done

  for ((idx=0; idx<${#ORGANIZATION[@]}; idx++)); do
    entry="${ORGANIZATION[$idx]}"
    type="${entry%%|*}"
    value="${entry##*|}"

    case "$type" in
      BLANK)
        echo "│"
        ;;
      HEADER)
        section_name="$value"
        in_section=true
        # セクション幅を揃える
        local_header=$(printf '│   ┌─── %s ' "$section_name")
        local_pad=$((48 - ${#local_header}))
        printf '%s' "$local_header"
        for ((j=0; j<local_pad; j++)); do printf '─'; done
        printf '┐\n'
        echo "│   │"
        ;;
      FOOTER)
        in_section=false
        if [ "$idx" -gt "$last_agent_idx" ]; then
          echo "    │"
          echo "    └────────────────────────────────────────────┘"
        else
          echo "│   │"
          echo "│   └────────────────────────────────────────────┘"
        fi
        ;;
      AGENT)
        local_name=$(get_subtitle "$value")
        local_role=$(get_role "$value")
        local_jp=$(get_myth "$value")
        local_label="${local_name}（${local_role}）"

        # 罫線の長さ調整
        local_line_len=$((30 - ${#local_label}))
        [ "$local_line_len" -lt 2 ] && local_line_len=2
        local_line=""
        for ((j=0; j<local_line_len; j++)); do local_line="${local_line}─"; done

        if [ "$idx" -eq "$last_agent_idx" ]; then
          printf '└── %s %s %s\n' "$local_label" "$local_line" "$local_jp"
          print_skills "$value" "    "
        else
          printf '├── %s %s %s\n' "$local_label" "$local_line" "$local_jp"
          print_skills "$value" "│   "
          echo "│"
        fi
        ;;
    esac
  done

  # 末尾を整形（最後の │ を削除して閉じる）
  echo '```'

} > "$OUTPUT"

# 末尾の空の │ 行を除去
sed -i '' '/^│$/{ N; /^│\n```$/{ s/^│\n/\n/; }; }' "$OUTPUT"

echo "AGENT_MAP.md を更新しました（${agent_count} エージェント / ${skill_count} スキル）"
