#!/usr/bin/env bash
set -Eeuo pipefail

# Hyprpanel custom widget for SAS awards
# - Scroll or click to change month
# - Summarizes outbound/inbound availability per month

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hyprpanel"
STATE_FILE="$STATE_DIR/sas_awards_state.json"
FETCH="$DIR/fetch_sas_awards_v2.sh"
DEFAULT_YM="${HYPR_SAS_DEFAULT_YM:-2026-09}"
# Force a fixed month view regardless of interactions

# Config via env (override defaults)
MARKET="${HYPR_SAS_MARKET:-se-sv}"
ORIGIN="${HYPR_SAS_ORIGIN:-ARN}"
DEST="${HYPR_SAS_DESTINATIONS:-HND}"
PASSENGERS="${HYPR_SAS_PASSENGERS:-2}"
DIRECT="${HYPR_SAS_DIRECT:-false}"
AVAIL="${HYPR_SAS_AVAILABILITY:-true}"
MIN_SEATS="${HYPR_SAS_MIN_SEATS:-0}"

# Helpers
ym_now() { date +%Y-%m; }

month_shift() {
  # shift like: month_shift 2026-09 +1  => 2026-10
  local base="$1"; local shift="${2:-0}"
  local y m; IFS='-' read -r y m <<<"$base"
  local y2=y m2=m; y2=$y; m2=$m
  local t=$((10#$y * 12 + 10#$m + shift))
  y2=$((t / 12)); m2=$((t % 12)); if (( m2 == 0 )); then m2=12; y2=$((y2-1)); fi
  printf "%04d-%02d" "$y2" "$m2"
}

ensure_state() {
  mkdir -p "$STATE_DIR"
  if [[ -f "$STATE_FILE" ]]; then
    :
  else
    printf '{"ym":"%s"}\n' "${DEFAULT_YM}" > "$STATE_FILE"
  fi
}

get_ym() {
  ensure_state
  jq -r '.ym // empty' "$STATE_FILE" 2>/dev/null || true
}

set_ym() {
  local ym="$1"
  mkdir -p "$STATE_DIR"
  printf '{"ym":"%s"}\n' "$ym" > "$STATE_FILE"
}

# Handle actions: widget always shows September 2026 in the bar
action="${1:-}"
ym="${DEFAULT_YM}"

# Derive API month forms
ymdash="$ym"
ymnodash="${ym//-/}"

# Safety: if fetch script not present, render placeholder
if [[ ! -x "$FETCH" ]]; then
  printf '{"alt":"none","class":"sas-awards-none","text":"N/A","tooltip":"fetch_sas_awards_v2.sh not found"}\n'
  exit 0
fi

# Fetch and summarize; tolerate network/API failure gracefully
set +e
raw_json="$("$FETCH" -m "$MARKET" -o "$ORIGIN" -D "$DEST" -p "$PASSENGERS" \
  --direct "$DIRECT" --availability "$AVAIL" -M "$ymnodash" -F "$ymdash" 2>/dev/null)"
status=$?
set -e

if [[ $status -ne 0 || -z "$raw_json" ]]; then
  # API failed
  printf '{"alt":"none","class":"sas-awards-none","text":"%s","tooltip":"API error for %s→%s (%s)"}\n' \
    "ERR" "$ORIGIN" "$DEST" "$ymdash"
  exit 0
fi

# Use jq to compute summary counts and a short tooltip list
have_jq=true
if ! command -v jq >/dev/null 2>&1; then have_jq=false; fi

if $have_jq; then
  # counts
  read -r out_count in_count total_count <<<"$(printf '%s' "$raw_json" | jq -r \
    --arg ym "$ymdash" --argjson min "$MIN_SEATS" '
      def filt(arr): (arr // []) | map(select((.date // "") | startswith($ym)))
        | map(select((.availableSeatsTotal // 0) >= $min));
      [
        (.[0].availability.outbound | filt(.) | length),
        (.[0].availability.inbound  | filt(.) | length)
      ] as $a | [$a[0], $a[1], ($a[0] + $a[1])] | @tsv
    ' )"
  

  # top rows for tooltip (limit to 12)
  tooltip_lines=$(printf '%s' "$raw_json" | jq -r \
    --arg ym "$ymdash" --argjson min "$MIN_SEATS" '
      def filt(arr): (arr // []) | map(select((.date // "") | startswith($ym)))
        | map(select((.availableSeatsTotal // 0) >= $min));
      [
        (.[0].availability.outbound | filt(.) | map(. + {direction:"out"})),
        (.[0].availability.inbound  | filt(.) | map(. + {direction:"in"}))
      ] | add | sort_by(.date) | .[:12] | map(
        (.direction + " " + (.date // "") + "  " + ((.availableSeatsTotal // 0)|tostring)
         + " seats  AG:" + ((.AG // 0)|tostring) + " AP:" + ((.AP // 0)|tostring))
      ) | join("\n")
    ')

  # Short month label
  month_label=$(date -d "$ymdash-01" +%b 2>/dev/null || printf '%s' "$ymdash")

  # Choose style
  if [[ "${total_count:-0}" -gt 0 ]]; then
    alt="avail"; cls="sas-awards-avail"
  else
    alt="none"; cls="sas-awards-none"
  fi

  text=$(printf 'Out: %s In: %s' "${out_count:-0}" "${in_count:-0}")
  # Output JSON single line
  jq -n --arg alt "$alt" --arg class "$cls" --arg text "$text" \
        --arg tip "$tooltip_lines" '{alt:$alt, class:$class, text:$text, tooltip:$tip}'
else
  # Fallback without jq
  printf '{"alt":"avail","class":"sas-awards-avail","text":"%s %s","tooltip":"%s"}\n' \
    "$ymdash" "$ORIGIN-$DEST" "Install jq for details"
fi
