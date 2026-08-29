#!/usr/bin/env bash
# Claude Code statusLine: model | dir (branch) | cost, plus plugin mode badges.
set -euo pipefail

input=$(cat)

model=$(jaq -r '.model.display_name // "?"' <<<"$input")
dir=$(jaq -r '.workspace.current_dir // .cwd // "?"' <<<"$input")
cost=$(jaq -r '.cost.total_cost_usd // 0' <<<"$input")

branch=""
if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$dir" branch --show-current 2>/dev/null || true)
fi

line="$model | ${dir##*/}"
[ -n "$branch" ] && line="$line ($branch)"
line="$line | \$$(printf '%.2f' "$cost")"

config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
for badge in \
  "$config_dir"/plugins/cache/ponytail/ponytail/*/hooks/ponytail-statusline.sh \
  "$config_dir"/plugins/cache/caveman/caveman/*/src/hooks/caveman-statusline.sh
do
  [ -f "$badge" ] || continue
  out=$(bash "$badge" 2>/dev/null || true)
  [ -n "$out" ] && line="$line  $out"
done

printf '%s' "$line"
