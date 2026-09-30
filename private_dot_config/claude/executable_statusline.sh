#!/usr/bin/env bash
# Claude Code statusLine: model | dir (branch) | cost-or-backend, ccp profile, plugin badges.
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
if [ -n "$branch" ]; then line="$line ($branch)"; fi
# A profile can point at a third-party backend, where the client-side cost estimate is
# computed at Anthropic list price and therefore wrong. Name the backend instead. The caveman
# route (loopback `/w/<agent>`, written into settings.json by its native integration) relays to
# Anthropic, so the estimate holds there; flag only a dead listener, where every request fails.
# `ccp` without -C sets the explicit Anthropic URL to override that route, so it counts as direct.
url=${ANTHROPIC_BASE_URL:-}
host=${url#*://}
host=${host%%/*}
case "$url" in
  '' | https://api.anthropic.com | https://api.anthropic.com/*)
    line="$line | \$$(printf '%.2f' "$cost")"
    ;;
  http://127.0.0.1:*/w/* | http://localhost:*/w/*)
    line="$line | \$$(printf '%.2f' "$cost")"
    if [ -z "$(ss -Hltn "sport = :${host##*:}" 2>/dev/null)" ]; then
      line="$line $(printf '\033[31m[proxy down]\033[0m')"
    fi
    ;;
  *) line="$line | $host" ;;
esac

config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# ccp launches `claude --settings <merged profiles>`; no stdin field carries that path, so ccp
# exports it. Absent it, the base settings are in effect and there is no profile to name.
settings="${CCP_SETTINGS:-$config_dir/settings.json}"

# Several plugin versions can linger in the cache, so resolve the badge through installPath
# rather than globbing. Being installed says nothing about being enabled, and a ccp profile can
# turn a plugin off, so gate each badge on the settings actually in force.
installed="$config_dir/plugins/installed_plugins.json"
badges="" shown=" "
for entry in \
  'ponytail@ponytail|hooks/ponytail-statusline.sh' \
  'caveman@caveman|src/hooks/caveman-statusline.sh'
do
  id=${entry%%|*}
  rel=${entry#*|}
  # shellcheck disable=SC2016,SC2312  # $k is a jaq variable, not a shell one
  [ "$(jaq -r --arg k "$id" '.enabledPlugins[$k] // false' "$settings" 2>/dev/null)" = true ] || continue
  badge=""
  # A plugin can be installed at several scopes; take the first whose badge is actually there.
  # shellcheck disable=SC2016  # $k is a jaq variable, not a shell one
  while read -r root; do
    if [ -f "$root/$rel" ]; then badge="$root/$rel"; break; fi
  done <<<"$(jaq -r --arg k "$id" '.plugins[$k][].installPath // empty' "$installed" 2>/dev/null || true)"
  [ -n "$badge" ] || continue
  # Badge scripts read session_id from the same JSON to resolve per-session state; without it
  # caveman falls back to a machine-wide flag and every window shows the last mode set anywhere.
  out=$(bash "$badge" <<<"$input" 2>/dev/null || true)
  if [ -n "$out" ]; then badges="$badges  $out"; shown="$shown${id%%@*} "; fi
done

# Name the ccp profile, minus any part already announced by its plugin's own badge: `ccp ponytail`
# would otherwise read [ponytail] [PONYTAIL]. Profiles merge as a+b, so filter per part.
if [ -n "${CCP_SETTINGS:-}" ]; then
  profile=${CCP_SETTINGS##*/.merged-}
  tag=""
  IFS=+ read -ra parts <<<"${profile%.json}"
  for p in "${parts[@]}"; do
    case "$shown" in *" $p "*) ;; *) tag="${tag:+$tag+}$p" ;; esac
  done
  if [ -n "$tag" ]; then line="$line  $(printf '\033[38;5;111m[%s]\033[0m' "$tag")"; fi
fi

printf '%s' "$line$badges"
