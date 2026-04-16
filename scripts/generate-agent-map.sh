#!/bin/bash
# エージェント・スキル一覧を自動生成するスクリプト
# pre-commit フックから呼び出される

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AGENTS_DIR="$REPO_ROOT/.claude/agents"
OUTPUT="$REPO_ROOT/AGENT_MAP.md"

cat > "$OUTPUT" << 'HEADER'
<!-- このファイルは scripts/generate-agent-map.sh により自動生成されます。直接編集しないでください。 -->

# エージェント・スキルマップ

HEADER

# エージェント数とスキル数を集計
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

echo "**${agent_count} エージェント / ${skill_count} スキル**" >> "$OUTPUT"
echo "" >> "$OUTPUT"

# 各エージェントを出力
for agent_dir in "$AGENTS_DIR"/*/; do
  [ -d "$agent_dir" ] || continue

  agent_name=$(basename "$agent_dir")
  title=$(head -1 "$agent_dir/CLAUDE.md" 2>/dev/null | sed 's/^# //')

  echo "## ${title}" >> "$OUTPUT"
  echo "" >> "$OUTPUT"

  if [ -d "$agent_dir/skills" ]; then
    echo "| スキル | 概要 |" >> "$OUTPUT"
    echo "| ------ | ---- |" >> "$OUTPUT"

    for skill in "$agent_dir"/skills/*.md; do
      [ -f "$skill" ] || continue
      [ "$(basename "$skill")" = "README.md" ] && continue

      skill_file=$(basename "$skill" .md)
      skill_title=$(head -1 "$skill" 2>/dev/null | sed 's/^# //')
      echo "| ${skill_file} | ${skill_title} |" >> "$OUTPUT"
    done

    echo "" >> "$OUTPUT"
  fi
done

echo "AGENT_MAP.md を更新しました（${agent_count} エージェント / ${skill_count} スキル）"
